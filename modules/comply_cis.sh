#!/usr/bin/env bash
# KWT5H13LD Module: CIS Controls Assessment

run_comply_cis() {
    local report_file="${REPORTS_DIR}/comply_cis_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CIS CONTROLS V8 ASSESSMENT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    local total=0 passed=0 failed=0

    # CIS Control 1: Inventory of Enterprise Assets
    log INFO "CIS Control 1: Inventory of Enterprise Assets"
    ((total++))
    local hw_inv
    hw_inv=$(lshw -short 2>/dev/null || dmidecode -t system 2>/dev/null || echo "")
    if [[ -n "${hw_inv}" ]]; then
        log SUCCESS "  Hardware inventory retrievable"
        ((passed++))
    else
        log WARNING "  Cannot retrieve hardware inventory"
        ((failed++))
    fi

    # CIS Control 2: Inventory of Software Assets
    log INFO "CIS Control 2: Inventory of Software Assets"
    ((total++))
    local pkg_mgr=""
    check_dependency "dpkg" && pkg_mgr="dpkg -l"
    check_dependency "rpm" && pkg_mgr="rpm -qa"
    if [[ -n "${pkg_mgr}" ]]; then
        local pkg_count
        pkg_count=$(${pkg_mgr} 2>/dev/null | wc -l)
        log SUCCESS "  Software inventory available (${pkg_count} packages)"
        ((passed++))
    else
        log WARNING "  Cannot enumerate installed software"
        ((failed++))
    fi

    # CIS Control 3: Data Protection
    log INFO "CIS Control 3: Data Protection"
    ((total++))
    if check_dependency "cryptsetup"; then
        local luks_devs
        luks_devs=$(lsblk -f 2>/dev/null | grep -c "crypto_LUKS" || echo "0")
        if [[ ${luks_devs} -gt 0 ]]; then
            log SUCCESS "  Disk encryption detected (${luks_devs} LUKS volumes)"
            ((passed++))
        else
            log WARNING "  No disk encryption detected"
            ((failed++))
        fi
    else
        log WARNING "  cryptsetup not available for encryption check"
        ((failed++))
    fi

    # CIS Control 4: Secure Configuration
    log INFO "CIS Control 4: Secure Configuration of Enterprise Assets"
    ((total++))
    local secure_configs=0
    grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null && ((secure_configs++))
    [[ $(sysctl -n kernel.randomize_va_space 2>/dev/null) == "2" ]] && ((secure_configs++))
    grep -q "hard core 0" /etc/security/limits.conf 2>/dev/null && ((secure_configs++))
    if [[ ${secure_configs} -ge 2 ]]; then
        log SUCCESS "  Baseline secure configuration detected (${secure_configs}/3 checks)"
        ((passed++))
    else
        log WARNING "  Secure configuration gaps found (${secure_configs}/3 checks)"
        ((failed++))
    fi

    # CIS Control 5: Account Management
    log INFO "CIS Control 5: Account Management"
    ((total++))
    local inactive_users
    inactive_users=$(lastlog 2>/dev/null | awk 'NR>1 && $2=="Never" {count++} END{print count+0}')
    if [[ ${inactive_users} -le 5 ]]; then
        log SUCCESS "  Inactive accounts within acceptable range (${inactive_users})"
        ((passed++))
    else
        log WARNING "  ${inactive_users} accounts have never logged in — review for cleanup"
        ((failed++))
    fi

    # CIS Control 6: Access Control Management
    log INFO "CIS Control 6: Access Control Management"
    ((total++))
    local sudo_users
    sudo_users=$(grep -c "^[^#]" /etc/sudoers.d/* 2>/dev/null || echo "0")
    local wheel_members
    wheel_members=$(getent group sudo 2>/dev/null | cut -d: -f4 | tr ',' '\n' | wc -l)
    log INFO "  Sudoers entries: ${sudo_users} | Sudo group members: ${wheel_members}"
    if [[ ${wheel_members} -le 5 ]]; then
        log SUCCESS "  Privileged access limited to ${wheel_members} users"
        ((passed++))
    else
        log WARNING "  ${wheel_members} users have sudo — review for least privilege"
        ((failed++))
    fi

    # CIS Control 8: Audit Log Management
    log INFO "CIS Control 8: Audit Log Management"
    ((total++))
    if systemctl is-active auditd &>/dev/null 2>&1 || [[ -f /var/log/audit/audit.log ]]; then
        log SUCCESS "  Audit logging (auditd) is active"
        ((passed++))
    else
        log WARNING "  Audit logging (auditd) is not active"
        ((failed++))
    fi

    # CIS Control 10: Anti-Malware Defenses
    log INFO "CIS Control 10: Anti-Malware Defenses"
    ((total++))
    if check_dependency "clamscan" || check_dependency "clamd" || systemctl is-active clamav-daemon &>/dev/null 2>&1; then
        log SUCCESS "  Anti-malware (ClamAV) detected"
        ((passed++))
    else
        log WARNING "  No anti-malware solution detected"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "CIS Assessment Score: ${score}% (${passed}/${total} controls pass)"
    echo ""
    { echo "KWT5H13LD CIS Controls Assessment"; echo "Generated: $(date)"; echo "Score: ${score}% | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
