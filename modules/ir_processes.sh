#!/usr/bin/env bash
run_ir_processes() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  PROCESS ANALYSIS & ANOMALY DETECTION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    # Processes with no associated binary
    log INFO "Checking for processes with deleted binaries..."
    local deleted
    deleted=$(ls -la /proc/*/exe 2>/dev/null | grep "(deleted)" | head -10)
    if [[ -n "${deleted}" ]]; then
        log WARNING "Processes running from deleted binaries:"
        echo "${deleted}" | while read -r line; do echo -e "    ${RED}${line}${NC}"; done
    else
        log SUCCESS "No processes with deleted binaries"
    fi

    # High CPU processes
    log INFO "Top CPU consumers:"
    ps aux --sort=-%cpu 2>/dev/null | head -6 | while read -r line; do echo -e "    ${line}"; done

    # High memory processes  
    log INFO "Top memory consumers:"
    ps aux --sort=-%mem 2>/dev/null | head -6 | while read -r line; do echo -e "    ${line}"; done

    # Processes running as root
    log INFO "Non-kernel root processes:"
    ps aux 2>/dev/null | awk '$1=="root" && $11!~/^\[/' | wc -l | xargs -I{} log INFO "  Count: {}"

    # Hidden processes check
    log INFO "Checking for hidden processes..."
    local ps_count
    ps_count=$(ps aux 2>/dev/null | wc -l)
    local proc_count
    proc_count=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
    local diff=$(( proc_count - ps_count ))
    if [[ ${diff} -gt 5 ]]; then
        log WARNING "Process count discrepancy — ps: ${ps_count}, /proc: ${proc_count}"
    else
        log SUCCESS "No hidden processes detected"
    fi

    # Processes with network connections
    log INFO "Processes with established network connections:"
    ss -tnp 2>/dev/null | grep ESTAB | awk '{print $NF}' | sort -u | head -15 | while read -r p; do echo -e "    ${p}"; done

    log SUCCESS "Process analysis finished"
    echo ""
}
