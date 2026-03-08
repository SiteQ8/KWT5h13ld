#!/usr/bin/env bash
# KWT5H13LD Module: DNS Security Assessment

run_net_dns() {
    local report_file="${REPORTS_DIR}/net_dns_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  DNS SECURITY ASSESSMENT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local target="${TARGET:-$(hostname -d 2>/dev/null || echo 'localhost')}"
    local total=0 passed=0 failed=0

    if ! check_dependency "dig"; then
        log ERROR "dig not available — install dnsutils/bind-utils"
        return 1
    fi

    # Check DNS resolution
    log INFO "Testing DNS resolution for ${target}..."
    ((total++))
    if dig +short "${target}" A 2>/dev/null | grep -q '.'; then
        log SUCCESS "DNS resolution working for ${target}"
        ((passed++))
    else
        log WARNING "DNS resolution failed for ${target}"
        ((failed++))
    fi

    # DNSSEC validation
    log INFO "Checking DNSSEC..."
    ((total++))
    local dnssec
    dnssec=$(dig +dnssec +short "${target}" 2>/dev/null)
    local rrsig
    rrsig=$(dig +dnssec "${target}" 2>/dev/null | grep -c "RRSIG")
    if [[ ${rrsig} -gt 0 ]]; then
        log SUCCESS "DNSSEC RRSIG records found for ${target}"
        ((passed++))
    else
        log WARNING "No DNSSEC RRSIG records for ${target}"
        ((failed++))
    fi

    # Zone transfer test
    log INFO "Testing for zone transfer vulnerability..."
    ((total++))
    local ns_servers
    ns_servers=$(dig +short NS "${target}" 2>/dev/null)
    local zone_xfer_ok=true
    for ns in ${ns_servers}; do
        local xfer
        xfer=$(dig @"${ns}" "${target}" AXFR +short 2>/dev/null | head -5)
        if [[ -n "${xfer}" ]]; then
            log WARNING "Zone transfer possible from ${ns}"
            zone_xfer_ok=false
        fi
    done
    if ${zone_xfer_ok}; then
        log SUCCESS "Zone transfers properly restricted"
        ((passed++))
    else
        ((failed++))
    fi

    # SPF record
    log INFO "Checking SPF record..."
    ((total++))
    local spf
    spf=$(dig +short TXT "${target}" 2>/dev/null | grep "v=spf1")
    if [[ -n "${spf}" ]]; then
        log SUCCESS "SPF record found"
        ((passed++))
    else
        log WARNING "No SPF record — email spoofing risk"
        ((failed++))
    fi

    # DMARC record
    log INFO "Checking DMARC record..."
    ((total++))
    local dmarc
    dmarc=$(dig +short TXT "_dmarc.${target}" 2>/dev/null | grep "v=DMARC1")
    if [[ -n "${dmarc}" ]]; then
        log SUCCESS "DMARC record found"
        ((passed++))
    else
        log WARNING "No DMARC record"
        ((failed++))
    fi

    # CAA record
    log INFO "Checking CAA record..."
    ((total++))
    local caa
    caa=$(dig +short CAA "${target}" 2>/dev/null)
    if [[ -n "${caa}" ]]; then
        log SUCCESS "CAA record found"
        ((passed++))
    else
        log WARNING "No CAA record — any CA can issue certificates"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD DNS Audit Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
