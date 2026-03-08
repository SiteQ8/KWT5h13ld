#!/usr/bin/env bash
# KWT5H13LD Module: Network Discovery & Service Enumeration

run_net_scan() {
    local report_file="${REPORTS_DIR}/net_scan_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  NETWORK DISCOVERY & SERVICE ENUMERATION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local target="${TARGET:-}"
    if [[ -z "${target}" ]]; then
        local default_gw
        default_gw=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -1)
        local subnet
        subnet=$(ip -o -f inet addr show 2>/dev/null | awk '/scope global/{print $4}' | head -1)
        target="${subnet:-${default_gw:-127.0.0.1/24}}"
        log INFO "No target specified — using local subnet: ${target}"
    fi

    # Network interface inventory
    log INFO "Network interfaces:"
    ip -br addr 2>/dev/null | while read -r line; do
        echo -e "    ${CYAN}${line}${NC}"
    done

    # ARP table
    log INFO ""
    log INFO "ARP table (known hosts):"
    arp -n 2>/dev/null | tail -n +2 | while read -r line; do
        echo -e "    ${line}"
    done

    # Port scan with nmap or fallback
    log INFO ""
    if check_dependency "nmap"; then
        log INFO "Running service discovery scan on ${target}..."
        nmap -sV -sC --top-ports 1000 -T4 "${target}" -oN "${report_file}" 2>/dev/null | while read -r line; do
            echo -e "    ${line}"
        done
    else
        log INFO "Nmap not available — using built-in port scanner on ${target}..."
        local host="${target%%/*}"
        local common_ports=(21 22 23 25 53 80 110 143 443 445 993 995 1433 1521 3306 3389 5432 5900 6379 8080 8443 9200 27017)
        for port in "${common_ports[@]}"; do
            (echo >/dev/tcp/"${host}"/"${port}") 2>/dev/null && log SUCCESS "  Port ${port}/tcp OPEN on ${host}" || true
        done
    fi

    # Listening services
    log INFO ""
    log INFO "Local listening services:"
    ss -tlnp 2>/dev/null | column -t | while read -r line; do
        echo -e "    ${line}"
    done

    log SUCCESS "Network scan saved to ${report_file}"
    echo ""
}
