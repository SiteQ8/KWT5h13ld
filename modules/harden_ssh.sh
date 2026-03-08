#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD Module: SSH Configuration Security Audit         ║
# ╚══════════════════════════════════════════════════════════════╝

run_harden_ssh() {
    local report_file="${REPORTS_DIR}/harden_ssh_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    local sshd_config="/etc/ssh/sshd_config"
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SSH CONFIGURATION SECURITY AUDIT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    if [[ ! -f "${sshd_config}" ]]; then
        log ERROR "SSH config not found at ${sshd_config}"
        return 1
    fi

    check_ssh_param() {
        local param="$1" expected="$2" desc="$3"
        ((total++))
        local actual
        actual=$(grep -i "^${param}" "${sshd_config}" 2>/dev/null | awk '{print $2}' | head -1)
        if [[ "${actual,,}" == "${expected,,}" ]]; then
            log SUCCESS "  ${desc}: ${actual}"
            ((passed++))
        else
            log WARNING "  ${desc}: ${actual:-not set} (recommended: ${expected})"
            ((failed++))
        fi
    }

    check_ssh_param "Protocol" "2" "SSH Protocol version"
    check_ssh_param "PermitRootLogin" "no" "Root login disabled"
    check_ssh_param "PasswordAuthentication" "no" "Password auth disabled"
    check_ssh_param "PermitEmptyPasswords" "no" "Empty passwords blocked"
    check_ssh_param "X11Forwarding" "no" "X11 forwarding disabled"
    check_ssh_param "MaxAuthTries" "4" "Max auth attempts limited"
    check_ssh_param "ClientAliveInterval" "300" "Client alive interval set"
    check_ssh_param "ClientAliveCountMax" "2" "Client alive count limited"
    check_ssh_param "LoginGraceTime" "60" "Login grace time limited"
    check_ssh_param "AllowAgentForwarding" "no" "Agent forwarding disabled"
    check_ssh_param "AllowTcpForwarding" "no" "TCP forwarding disabled"
    check_ssh_param "UsePAM" "yes" "PAM authentication enabled"
    check_ssh_param "StrictModes" "yes" "Strict file modes enabled"
    check_ssh_param "LogLevel" "VERBOSE" "Verbose logging enabled"

    # Check SSH key permissions
    ((total++))
    local ssh_key_perms_ok=true
    for key_file in /etc/ssh/ssh_host_*_key; do
        if [[ -f "${key_file}" ]]; then
            local perms
            perms=$(stat -c "%a" "${key_file}" 2>/dev/null)
            if [[ "${perms}" != "600" && "${perms}" != "400" ]]; then
                log WARNING "  Host key ${key_file} has permissions ${perms} (should be 600)"
                ssh_key_perms_ok=false
            fi
        fi
    done
    if ${ssh_key_perms_ok}; then
        log SUCCESS "  SSH host key permissions are secure"
        ((passed++))
    else
        ((failed++))
    fi

    # Check for weak ciphers
    ((total++))
    local weak_ciphers=("3des-cbc" "aes128-cbc" "aes192-cbc" "aes256-cbc" "blowfish-cbc" "cast128-cbc")
    local configured_ciphers
    configured_ciphers=$(grep -i "^Ciphers" "${sshd_config}" 2>/dev/null | awk '{print $2}')
    local weak_found=false
    if [[ -n "${configured_ciphers}" ]]; then
        for wc in "${weak_ciphers[@]}"; do
            if echo "${configured_ciphers}" | grep -qi "${wc}"; then
                weak_found=true
                break
            fi
        done
    fi
    if ! ${weak_found}; then
        log SUCCESS "  No weak ciphers configured"
        ((passed++))
    else
        log WARNING "  Weak CBC ciphers detected in configuration"
        ((failed++))
    fi

    # Check for weak MACs
    ((total++))
    local configured_macs
    configured_macs=$(grep -i "^MACs" "${sshd_config}" 2>/dev/null | awk '{print $2}')
    if [[ -n "${configured_macs}" ]]; then
        if echo "${configured_macs}" | grep -qi "md5\|sha1[^-]"; then
            log WARNING "  Weak MACs (MD5/SHA1) detected"
            ((failed++))
        else
            log SUCCESS "  MAC algorithms are secure"
            ((passed++))
        fi
    else
        log INFO "  MACs not explicitly configured (using defaults)"
        ((passed++))
    fi

    # Check authorized_keys file permissions
    ((total++))
    local auth_issues=0
    while IFS=: read -r user _ _ _ _ home _; do
        local ak="${home}/.ssh/authorized_keys"
        if [[ -f "${ak}" ]]; then
            local ak_perms
            ak_perms=$(stat -c "%a" "${ak}" 2>/dev/null)
            if [[ "${ak_perms}" != "600" && "${ak_perms}" != "400" && "${ak_perms}" != "644" ]]; then
                log WARNING "  ${ak} has permissive permissions: ${ak_perms}"
                ((auth_issues++))
            fi
        fi
    done < /etc/passwd 2>/dev/null
    if [[ ${auth_issues} -eq 0 ]]; then
        log SUCCESS "  authorized_keys file permissions are secure"
        ((passed++))
    else
        ((failed++))
    fi

    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SSH AUDIT SUMMARY"
    log INFO "═══════════════════════════════════════════════════════"
    local score=0
    [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""

    {
        echo "KWT5H13LD SSH Audit Report"
        echo "Generated: $(date)"
        echo "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    } > "${report_file}"
}
