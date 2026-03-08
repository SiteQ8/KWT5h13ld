#!/usr/bin/env bash
run_log_syslog() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SYSLOG ANOMALY & PATTERN DETECTION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    local syslog="/var/log/syslog"
    [[ ! -f "${syslog}" ]] && syslog="/var/log/messages"
    [[ ! -f "${syslog}" ]] && { log ERROR "Syslog not found"; return 1; }

    log INFO "Scanning ${syslog} for anomalies..."
    
    # Error/critical counts
    local errors warnings criticals
    errors=$(grep -ci "error" "${syslog}" 2>/dev/null || echo "0")
    warnings=$(grep -ci "warning\|warn" "${syslog}" 2>/dev/null || echo "0")
    criticals=$(grep -ci "critical\|emergency\|alert" "${syslog}" 2>/dev/null || echo "0")
    
    log INFO "Error entries: ${errors}"
    log INFO "Warning entries: ${warnings}"
    [[ ${criticals} -gt 0 ]] && log WARNING "Critical/Emergency entries: ${criticals}" || log SUCCESS "No critical entries"

    # Disk space warnings
    local disk_warns
    disk_warns=$(grep -ci "No space\|disk full\|ENOSPC" "${syslog}" 2>/dev/null || echo "0")
    [[ ${disk_warns} -gt 0 ]] && log WARNING "Disk space issues detected: ${disk_warns}"

    # OOM killer
    local oom
    oom=$(grep -ci "Out of memory\|oom-kill" "${syslog}" 2>/dev/null || echo "0")
    [[ ${oom} -gt 0 ]] && log WARNING "OOM killer events: ${oom}"

    # Segfaults
    local segfaults
    segfaults=$(grep -ci "segfault" "${syslog}" 2>/dev/null || echo "0")
    [[ ${segfaults} -gt 0 ]] && log WARNING "Segfault events: ${segfaults}"

    log SUCCESS "Syslog analysis finished"
    echo ""
}
