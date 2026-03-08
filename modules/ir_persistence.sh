#!/usr/bin/env bash
run_ir_persistence() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  PERSISTENCE MECHANISM DETECTION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    local total=0 found=0

    # Cron jobs
    log INFO "Scanning cron jobs..."
    ((total++))
    for crondir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly /var/spool/cron/crontabs; do
        if [[ -d "${crondir}" ]]; then
            local count
            count=$(ls -la "${crondir}" 2>/dev/null | grep -v "total\|^\.\|^d" | wc -l)
            [[ ${count} -gt 0 ]] && log INFO "  ${crondir}: ${count} entries"
        fi
    done

    # Systemd services (user-created)
    log INFO "Scanning user-created systemd services..."
    ((total++))
    local user_services
    user_services=$(find /etc/systemd/system -maxdepth 1 -name "*.service" -newer /etc/os-release 2>/dev/null)
    if [[ -n "${user_services}" ]]; then
        log WARNING "Recently created systemd services:"
        echo "${user_services}" | while read -r svc; do echo -e "    ${YELLOW}${svc}${NC}"; done
        ((found++))
    else
        log SUCCESS "No suspicious systemd services"
    fi

    # init.d scripts
    log INFO "Scanning init.d scripts..."
    ((total++))
    local initd_count
    initd_count=$(ls /etc/init.d/ 2>/dev/null | wc -l)
    log INFO "  /etc/init.d entries: ${initd_count}"

    # Shell profile backdoors
    log INFO "Checking shell profiles for suspicious entries..."
    ((total++))
    local profile_files=("/etc/profile" "/etc/bash.bashrc" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")
    for pf in "${profile_files[@]}"; do
        if [[ -f "${pf}" ]]; then
            if grep -qiE "curl.*\||wget.*\||nc |ncat |/dev/tcp|base64.*-d|eval.*\$" "${pf}" 2>/dev/null; then
                log WARNING "Suspicious commands in ${pf}"
                ((found++))
            fi
        fi
    done
    [[ ${found} -eq 0 ]] && log SUCCESS "No suspicious shell profile entries"

    # SSH authorized keys
    log INFO "Scanning SSH authorized_keys..."
    ((total++))
    find /home /root -name "authorized_keys" 2>/dev/null | while read -r ak; do
        local key_count
        key_count=$(wc -l < "${ak}" 2>/dev/null)
        log INFO "  ${ak}: ${key_count} keys"
        grep -i "command=" "${ak}" 2>/dev/null && log WARNING "  Forced command found in ${ak}"
    done

    # /etc/rc.local
    log INFO "Checking rc.local..."
    ((total++))
    if [[ -f /etc/rc.local ]] && [[ -x /etc/rc.local ]]; then
        local rc_lines
        rc_lines=$(grep -v "^#\|^$\|^exit" /etc/rc.local 2>/dev/null | wc -l)
        if [[ ${rc_lines} -gt 0 ]]; then
            log WARNING "Active rc.local entries: ${rc_lines}"
        fi
    fi

    # LD_PRELOAD
    log INFO "Checking for LD_PRELOAD persistence..."
    ((total++))
    if [[ -f /etc/ld.so.preload ]] && [[ -s /etc/ld.so.preload ]]; then
        log WARNING "LD_PRELOAD file has entries (possible rootkit)"
        ((found++))
    else
        log SUCCESS "No LD_PRELOAD persistence"
    fi

    echo ""
    log INFO "Persistence checks complete. Suspicious findings: ${found}"
    echo ""
}
