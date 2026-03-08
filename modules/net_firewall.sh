#!/usr/bin/env bash
# KWT5H13LD Module: Firewall Rule Audit & Gap Analysis

run_net_firewall() {
    local report_file="${REPORTS_DIR}/net_firewall_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  FIREWALL RULE AUDIT & GAP ANALYSIS"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # Check if firewall is active
    ((total++))
    local fw_active=false
    if check_dependency "ufw"; then
        local ufw_status
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "${ufw_status}" | grep -qi "active"; then
            log SUCCESS "UFW firewall is active"
            ((passed++)); fw_active=true
            ufw status verbose 2>/dev/null | while read -r line; do echo -e "    ${line}"; done
        else
            log WARNING "UFW is installed but NOT active"
            ((failed++))
        fi
    fi

    if check_dependency "iptables"; then
        log INFO ""
        log INFO "iptables rules:"
        ((total++))
        local rule_count
        rule_count=$(iptables -L -n 2>/dev/null | grep -c "^[A-Z]" || echo "0")
        if [[ ${rule_count} -gt 3 ]]; then
            log SUCCESS "iptables has ${rule_count} chains configured"
            ((passed++)); fw_active=true
        else
            [[ "${fw_active}" == false ]] && log WARNING "iptables has minimal configuration"
            ((failed++))
        fi
        iptables -L -n -v 2>/dev/null | head -50 | while read -r line; do echo -e "    ${GRAY}${line}${NC}"; done
    fi

    if check_dependency "nft"; then
        log INFO ""
        log INFO "nftables ruleset:"
        ((total++))
        local nft_rules
        nft_rules=$(nft list ruleset 2>/dev/null | wc -l)
        if [[ ${nft_rules} -gt 2 ]]; then
            log SUCCESS "nftables has ${nft_rules} lines of rules"
            ((passed++)); fw_active=true
        fi
    fi

    # Default policy check
    ((total++))
    local input_policy
    input_policy=$(iptables -L INPUT 2>/dev/null | head -1 | awk '{print $4}' | tr -d ')')
    if [[ "${input_policy}" == "DROP" || "${input_policy}" == "REJECT" ]]; then
        log SUCCESS "Default INPUT policy is ${input_policy}"
        ((passed++))
    else
        log WARNING "Default INPUT policy is ${input_policy:-ACCEPT} (should be DROP)"
        ((failed++))
    fi

    ((total++))
    local forward_policy
    forward_policy=$(iptables -L FORWARD 2>/dev/null | head -1 | awk '{print $4}' | tr -d ')')
    if [[ "${forward_policy}" == "DROP" || "${forward_policy}" == "REJECT" ]]; then
        log SUCCESS "Default FORWARD policy is ${forward_policy}"
        ((passed++))
    else
        log WARNING "Default FORWARD policy is ${forward_policy:-ACCEPT} (should be DROP)"
        ((failed++))
    fi

    # Check for overly permissive rules
    ((total++))
    local any_any_rules
    any_any_rules=$(iptables -L -n 2>/dev/null | grep -c "0.0.0.0/0.*0.0.0.0/0.*ACCEPT" || echo "0")
    if [[ ${any_any_rules} -le 2 ]]; then
        log SUCCESS "Limited any-to-any ACCEPT rules (${any_any_rules})"
        ((passed++))
    else
        log WARNING "Multiple any-to-any ACCEPT rules (${any_any_rules}) — review for least privilege"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD Firewall Audit Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"; } > "${report_file}"
}
