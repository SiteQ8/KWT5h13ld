#!/usr/bin/env bash
# KWT5H13LD Module: Service Enumeration & Review

run_harden_services() {
    local report_file="${REPORTS_DIR}/harden_services_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SERVICE ENUMERATION & SECURITY REVIEW"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # Unnecessary services check
    local unnecessary=("telnet" "rsh" "rlogin" "rexec" "tftp" "xinetd" "avahi-daemon" "cups" "nfs" "rpcbind" "slapd" "snmpd" "squid" "vsftpd" "named")
    
    log INFO "Checking for unnecessary/insecure services..."
    for svc in "${unnecessary[@]}"; do
        ((total++))
        if systemctl is-active "${svc}" &>/dev/null 2>&1 || systemctl is-active "${svc}.service" &>/dev/null 2>&1; then
            log WARNING "  Service '${svc}' is running — disable if not needed"
            ((failed++))
        else
            log SUCCESS "  Service '${svc}' is not running"
            ((passed++))
        fi
    done

    # Check listening services
    log INFO ""
    log INFO "Listing all listening network services..."
    if check_dependency "ss"; then
        ss -tlnp 2>/dev/null | while read -r line; do
            echo -e "    ${GRAY}${line}${NC}"
        done
    fi

    # World-readable service configs
    log INFO ""
    log INFO "Checking service config file permissions..."
    local sensitive_configs=("/etc/mysql/my.cnf" "/etc/postgresql" "/etc/nginx/nginx.conf" "/etc/apache2/apache2.conf" "/etc/redis/redis.conf")
    for cfg in "${sensitive_configs[@]}"; do
        if [[ -f "${cfg}" ]]; then
            ((total++))
            local perms
            perms=$(stat -c "%a" "${cfg}" 2>/dev/null)
            if [[ "${perms}" -le 640 ]]; then
                log SUCCESS "  ${cfg}: ${perms}"
                ((passed++))
            else
                log WARNING "  ${cfg}: ${perms} (should be 640 or less)"
                ((failed++))
            fi
        fi
    done

    # Check for services running as root
    log INFO ""
    log INFO "Checking for non-essential services running as root..."
    ((total++))
    local root_svcs
    root_svcs=$(ps aux 2>/dev/null | awk '$1=="root" && $11!~/\[.*\]/' | grep -v "PID" | wc -l)
    log INFO "  Processes running as root: ${root_svcs}"
    if [[ ${root_svcs} -lt 30 ]]; then
        log SUCCESS "  Root process count within normal range"
        ((passed++))
    else
        log WARNING "  High number of root processes — review for least privilege"
        ((failed++))
    fi

    echo ""
    local score=0
    [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""

    { echo "KWT5H13LD Service Review Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"; } > "${report_file}"
}
