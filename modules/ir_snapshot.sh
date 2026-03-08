#!/usr/bin/env bash
run_ir_snapshot() {
    local report_file="${REPORTS_DIR}/ir_snapshot_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SYSTEM STATE SNAPSHOT (FORENSIC BASELINE)"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    {
        echo "=== KWT5H13LD SYSTEM SNAPSHOT ==="
        echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -a)"
        echo ""
        echo "=== RUNNING PROCESSES ==="
        ps auxf 2>/dev/null
        echo ""
        echo "=== NETWORK CONNECTIONS ==="
        ss -tlnpa 2>/dev/null || netstat -tlnpa 2>/dev/null
        echo ""
        echo "=== LISTENING SERVICES ==="
        ss -tlnp 2>/dev/null
        echo ""
        echo "=== MOUNTED FILESYSTEMS ==="
        mount 2>/dev/null
        echo ""
        echo "=== DISK USAGE ==="
        df -h 2>/dev/null
        echo ""
        echo "=== LOGGED IN USERS ==="
        w 2>/dev/null
        echo ""
        echo "=== LAST LOGINS ==="
        last -20 2>/dev/null
        echo ""
        echo "=== CRON JOBS (ROOT) ==="
        crontab -l 2>/dev/null
        echo ""
        echo "=== /etc/crontab ==="
        cat /etc/crontab 2>/dev/null
        echo ""
        echo "=== IPTABLES RULES ==="
        iptables -L -n -v 2>/dev/null
        echo ""
        echo "=== DNS RESOLV.CONF ==="
        cat /etc/resolv.conf 2>/dev/null
        echo ""
        echo "=== HOSTS FILE ==="
        cat /etc/hosts 2>/dev/null
        echo ""
        echo "=== ENVIRONMENT ==="
        env 2>/dev/null
    } > "${report_file}" 2>&1

    log SUCCESS "Snapshot saved: ${report_file}"
    log INFO "File size: $(du -h "${report_file}" | awk '{print $1}')"
    echo ""
}
