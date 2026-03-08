#!/usr/bin/env bash
run_log_auth() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  AUTHENTICATION LOG ANALYSIS"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    local auth_log="/var/log/auth.log"
    [[ ! -f "${auth_log}" ]] && auth_log="/var/log/secure"
    [[ ! -f "${auth_log}" ]] && { log ERROR "Auth log not found"; return 1; }

    log INFO "Analyzing ${auth_log}..."

    # Failed SSH logins
    local failed_ssh
    failed_ssh=$(grep -c "Failed password" "${auth_log}" 2>/dev/null || echo "0")
    log INFO "Failed SSH login attempts: ${failed_ssh}"
    
    if [[ ${failed_ssh} -gt 100 ]]; then
        log WARNING "High number of failed logins — possible brute force"
    fi

    # Top attacking IPs
    log INFO "Top source IPs for failed logins:"
    grep "Failed password" "${auth_log}" 2>/dev/null | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head -10 | while read -r count ip; do
        if [[ ${count} -gt 50 ]]; then
            log WARNING "  ${count} attempts from ${ip}"
        else
            echo -e "    ${count} — ${ip}"
        fi
    done

    # Successful root logins
    local root_logins
    root_logins=$(grep -c "session opened.*root" "${auth_log}" 2>/dev/null || echo "0")
    log INFO "Root session opens: ${root_logins}"

    # Sudo usage
    local sudo_cmds
    sudo_cmds=$(grep -c "sudo:" "${auth_log}" 2>/dev/null || echo "0")
    log INFO "Sudo commands logged: ${sudo_cmds}"

    # Account changes
    local acct_changes
    acct_changes=$(grep -cE "useradd|userdel|usermod|groupadd|passwd" "${auth_log}" 2>/dev/null || echo "0")
    if [[ ${acct_changes} -gt 0 ]]; then
        log WARNING "Account modifications detected: ${acct_changes}"
    fi

    log SUCCESS "Auth log analysis finished"
    echo ""
}
