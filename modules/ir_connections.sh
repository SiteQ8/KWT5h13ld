#!/usr/bin/env bash
run_ir_connections() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  ACTIVE NETWORK CONNECTION INVESTIGATION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    log INFO "Established connections:"
    ss -tnp state established 2>/dev/null | column -t | while read -r line; do echo -e "    ${line}"; done

    log INFO ""
    log INFO "Listening services:"
    ss -tlnp 2>/dev/null | column -t | while read -r line; do echo -e "    ${line}"; done

    log INFO ""
    log INFO "Connection state summary:"
    ss -s 2>/dev/null | while read -r line; do echo -e "    ${line}"; done

    log INFO ""
    log INFO "Unusual outbound connections (non-standard ports):"
    ss -tnp 2>/dev/null | awk '$4!~/:443$|:80$|:53$|:22$/ && $1=="ESTAB"' | while read -r line; do
        echo -e "    ${YELLOW}${line}${NC}"
    done

    log INFO ""
    log INFO "DNS server configuration:"
    cat /etc/resolv.conf 2>/dev/null | grep nameserver | while read -r line; do echo -e "    ${line}"; done

    log SUCCESS "Connection investigation finished"
    echo ""
}
