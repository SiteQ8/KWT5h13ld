#!/usr/bin/env bash
run_log_audit() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  AUDITD LOG REVIEW"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    if ! check_dependency "ausearch" && ! [[ -f /var/log/audit/audit.log ]]; then
        log WARNING "auditd is not installed or not running"
        log INFO "Install: apt install auditd / yum install audit"
        return 1
    fi

    local audit_log="/var/log/audit/audit.log"
    if [[ -f "${audit_log}" ]]; then
        log INFO "Analyzing ${audit_log}..."
        
        # Failed syscalls
        if check_dependency "ausearch"; then
            log INFO "Failed syscall events:"
            ausearch -m SYSCALL --success no -i 2>/dev/null | tail -20 | while read -r line; do echo -e "    ${line}"; done

            log INFO "User authentication events:"
            ausearch -m USER_AUTH -i 2>/dev/null | tail -10 | while read -r line; do echo -e "    ${line}"; done

            log INFO "File access anomalies:"
            ausearch -m PATH -i 2>/dev/null | grep -i "shadow\|passwd\|sudoers" | tail -10 | while read -r line; do echo -e "    ${YELLOW}${line}${NC}"; done
        fi

        local total_events
        total_events=$(wc -l < "${audit_log}" 2>/dev/null || echo "0")
        log INFO "Total audit log entries: ${total_events}"
    else
        log WARNING "Audit log file not found at ${audit_log}"
    fi

    log SUCCESS "Audit review finished"
    echo ""
}
