#!/usr/bin/env bash
run_asset_ports() {
    local report_file="${REPORTS_DIR}/asset_ports_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  PORT & SERVICE INVENTORY MAPPING"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    {
        echo "=== LISTENING TCP PORTS ==="
        ss -tlnp 2>/dev/null | column -t
        echo ""
        echo "=== LISTENING UDP PORTS ==="
        ss -ulnp 2>/dev/null | column -t
        echo ""
        echo "=== ESTABLISHED CONNECTIONS ==="
        ss -tnp state established 2>/dev/null | column -t
        echo ""
        echo "=== PORT-TO-PROCESS MAPPING ==="
        ss -tlnp 2>/dev/null | awk 'NR>1{print $4, $6}' | while read -r addr proc; do
            echo "  ${addr} → ${proc}"
        done
    } | tee "${report_file}"

    echo ""
    log SUCCESS "Port inventory saved: ${report_file}"
    echo ""
}
