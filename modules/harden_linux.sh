#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD Module: Linux CIS Benchmark Hardening Audit      ║
# ╚══════════════════════════════════════════════════════════════╝

run_harden_linux() {
    local report_file="${REPORTS_DIR}/harden_linux_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  LINUX CIS BENCHMARK HARDENING ASSESSMENT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0 warnings=0
    local results=""

    append_result() {
        results+="$1"$'\n'
    }

    # ── 1. Filesystem Configuration ────────────────────────────
    log INFO "1. Filesystem Configuration"

    # 1.1 Check /tmp mount
    ((total++))
    if mount | grep -q " /tmp "; then
        log SUCCESS "  1.1 /tmp is a separate partition"
        ((passed++))
    else
        log WARNING "  1.1 /tmp is NOT a separate partition"
        ((failed++))
    fi

    # 1.2 Check noexec on /tmp
    ((total++))
    if mount | grep " /tmp " | grep -q "noexec"; then
        log SUCCESS "  1.2 /tmp has noexec option set"
        ((passed++))
    else
        log WARNING "  1.2 /tmp does NOT have noexec option"
        ((failed++))
    fi

    # 1.3 Check /var mount
    ((total++))
    if mount | grep -q " /var "; then
        log SUCCESS "  1.3 /var is a separate partition"
        ((passed++))
    else
        log WARNING "  1.3 /var is NOT a separate partition"
        ((failed++))
    fi

    # 1.4 Sticky bit on world-writable dirs
    ((total++))
    local sticky_missing
    sticky_missing=$(df --local -P 2>/dev/null | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | head -20)
    if [[ -z "${sticky_missing}" ]]; then
        log SUCCESS "  1.4 All world-writable directories have sticky bit"
        ((passed++))
    else
        log WARNING "  1.4 World-writable dirs without sticky bit found"
        ((failed++))
    fi

    # ── 2. Software Updates ────────────────────────────────────
    log INFO "2. Software & Patch Management"

    ((total++))
    if check_dependency "apt"; then
        local updates
        updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)
        if [[ "${updates}" -eq 0 ]]; then
            log SUCCESS "  2.1 System is up to date (apt)"
            ((passed++))
        else
            log WARNING "  2.1 ${updates} packages need updating"
            ((failed++))
        fi
    elif check_dependency "yum"; then
        local yum_updates
        yum_updates=$(yum check-update --quiet 2>/dev/null | wc -l || true)
        if [[ "${yum_updates}" -eq 0 ]]; then
            log SUCCESS "  2.1 System is up to date (yum)"
            ((passed++))
        else
            log WARNING "  2.1 ${yum_updates} packages need updating"
            ((failed++))
        fi
    fi

    # ── 3. Boot Security ──────────────────────────────────────
    log INFO "3. Boot Security"

    ((total++))
    if [[ -f /boot/grub/grub.cfg || -f /boot/grub2/grub.cfg ]]; then
        local grub_file="/boot/grub/grub.cfg"
        [[ -f /boot/grub2/grub.cfg ]] && grub_file="/boot/grub2/grub.cfg"
        local grub_perms
        grub_perms=$(stat -c "%a" "${grub_file}" 2>/dev/null || echo "unknown")
        if [[ "${grub_perms}" == "400" || "${grub_perms}" == "600" ]]; then
            log SUCCESS "  3.1 GRUB config permissions: ${grub_perms}"
            ((passed++))
        else
            log WARNING "  3.1 GRUB config permissions too open: ${grub_perms} (should be 400/600)"
            ((failed++))
        fi
    fi

    # ── 4. Process Security ───────────────────────────────────
    log INFO "4. Process Security"

    # Core dump restrictions
    ((total++))
    if grep -q "hard core 0" /etc/security/limits.conf 2>/dev/null || grep -rq "hard core 0" /etc/security/limits.d/ 2>/dev/null; then
        log SUCCESS "  4.1 Core dumps are restricted"
        ((passed++))
    else
        log WARNING "  4.1 Core dumps are NOT restricted"
        ((failed++))
    fi

    # ASLR
    ((total++))
    local aslr
    aslr=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null)
    if [[ "${aslr}" == "2" ]]; then
        log SUCCESS "  4.2 ASLR is fully enabled (${aslr})"
        ((passed++))
    else
        log WARNING "  4.2 ASLR is not fully enabled (value: ${aslr}, should be 2)"
        ((failed++))
    fi

    # ── 5. Network Parameters ─────────────────────────────────
    log INFO "5. Network Parameters"

    local sysctl_checks=(
        "net.ipv4.ip_forward:0:IP forwarding disabled"
        "net.ipv4.conf.all.send_redirects:0:ICMP redirects disabled"
        "net.ipv4.conf.all.accept_source_route:0:Source routing disabled"
        "net.ipv4.conf.all.accept_redirects:0:ICMP redirect acceptance disabled"
        "net.ipv4.conf.all.log_martians:1:Martian packet logging enabled"
        "net.ipv4.icmp_echo_ignore_broadcasts:1:Broadcast ICMP ignored"
        "net.ipv4.tcp_syncookies:1:SYN cookies enabled"
    )

    for check in "${sysctl_checks[@]}"; do
        IFS=':' read -r param expected desc <<< "${check}"
        ((total++))
        local actual
        actual=$(sysctl -n "${param}" 2>/dev/null || echo "unavailable")
        if [[ "${actual}" == "${expected}" ]]; then
            log SUCCESS "  5.x ${desc} (${param}=${actual})"
            ((passed++))
        else
            log WARNING "  5.x ${desc} — ${param}=${actual} (expected ${expected})"
            ((failed++))
        fi
    done

    # ── 6. File Permissions ───────────────────────────────────
    log INFO "6. Critical File Permissions"

    local perm_checks=(
        "/etc/passwd:644"
        "/etc/shadow:640"
        "/etc/group:644"
        "/etc/gshadow:640"
        "/etc/crontab:600"
    )

    for check in "${perm_checks[@]}"; do
        IFS=':' read -r filepath expected_perm <<< "${check}"
        ((total++))
        if [[ -f "${filepath}" ]]; then
            local actual_perm
            actual_perm=$(stat -c "%a" "${filepath}" 2>/dev/null)
            if [[ "${actual_perm}" -le "${expected_perm}" ]]; then
                log SUCCESS "  6.x ${filepath} permissions: ${actual_perm}"
                ((passed++))
            else
                log WARNING "  6.x ${filepath} permissions: ${actual_perm} (max ${expected_perm})"
                ((failed++))
            fi
        fi
    done

    # ── 7. User Accounts ─────────────────────────────────────
    log INFO "7. User Account Security"

    # Check for UID 0 accounts besides root
    ((total++))
    local uid0_accounts
    uid0_accounts=$(awk -F: '($3 == 0 && $1 != "root") { print $1 }' /etc/passwd 2>/dev/null)
    if [[ -z "${uid0_accounts}" ]]; then
        log SUCCESS "  7.1 No non-root accounts with UID 0"
        ((passed++))
    else
        log WARNING "  7.1 Non-root UID 0 accounts: ${uid0_accounts}"
        ((failed++))
    fi

    # Empty password check
    ((total++))
    local empty_pass
    empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow 2>/dev/null)
    if [[ -z "${empty_pass}" ]]; then
        log SUCCESS "  7.2 No accounts with empty passwords"
        ((passed++))
    else
        log WARNING "  7.2 Accounts with empty passwords: ${empty_pass}"
        ((failed++))
    fi

    # Root login path
    ((total++))
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        log SUCCESS "  7.3 Direct root SSH login is disabled"
        ((passed++))
    else
        log WARNING "  7.3 Direct root SSH login may be permitted"
        ((failed++))
    fi

    # ── Summary ────────────────────────────────────────────────
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  LINUX HARDENING SUMMARY"
    log INFO "═══════════════════════════════════════════════════════"
    local score=0
    [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total checks:  ${total}"
    log SUCCESS "Passed:        ${passed}"
    log ERROR "Failed:        ${failed}"
    log INFO "Score:         ${score}%"
    echo ""

    {
        echo "KWT5H13LD Linux Hardening Report"
        echo "Generated: $(date)"
        echo "=========================="
        echo "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    } > "${report_file}"
}
