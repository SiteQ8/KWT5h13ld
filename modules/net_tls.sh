#!/usr/bin/env bash
# KWT5H13LD Module: TLS/SSL Certificate & Cipher Audit

run_net_tls() {
    local report_file="${REPORTS_DIR}/net_tls_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  TLS/SSL CERTIFICATE & CIPHER AUDIT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local target="${TARGET:-localhost}"
    local port=443
    [[ "${target}" == *:* ]] && port="${target##*:}" && target="${target%%:*}"
    local total=0 passed=0 failed=0

    if ! check_dependency "openssl"; then
        log ERROR "OpenSSL not available"
        return 1
    fi

    # Certificate details
    log INFO "Connecting to ${target}:${port}..."
    local cert_info
    cert_info=$(echo | openssl s_client -connect "${target}:${port}" -servername "${target}" 2>/dev/null)
    
    if [[ -z "${cert_info}" ]]; then
        log ERROR "Could not connect to ${target}:${port}"
        return 1
    fi

    # Certificate expiry
    ((total++))
    local expiry
    expiry=$(echo "${cert_info}" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [[ -n "${expiry}" ]]; then
        local exp_epoch
        exp_epoch=$(date -d "${expiry}" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "${expiry}" +%s 2>/dev/null)
        local now_epoch
        now_epoch=$(date +%s)
        local days_left=$(( (exp_epoch - now_epoch) / 86400 ))
        if [[ ${days_left} -gt 30 ]]; then
            log SUCCESS "Certificate expires in ${days_left} days (${expiry})"
            ((passed++))
        elif [[ ${days_left} -gt 0 ]]; then
            log WARNING "Certificate expires in ${days_left} days — renew soon!"
            ((failed++))
        else
            log ERROR "Certificate EXPIRED ${days_left} days ago"
            ((failed++))
        fi
    fi

    # Key size
    ((total++))
    local key_size
    key_size=$(echo "${cert_info}" | openssl x509 -noout -text 2>/dev/null | grep "Public-Key:" | grep -oP '\d+')
    if [[ -n "${key_size}" && "${key_size}" -ge 2048 ]]; then
        log SUCCESS "Key size: ${key_size} bits"
        ((passed++))
    else
        log WARNING "Key size: ${key_size:-unknown} bits (minimum 2048 recommended)"
        ((failed++))
    fi

    # Protocol support
    for proto in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
        ((total++))
        local proto_flag="-${proto}"
        local result
        result=$(echo | openssl s_client -connect "${target}:${port}" "${proto_flag}" -servername "${target}" 2>&1)
        if echo "${result}" | grep -q "Protocol.*:.*TLSv\|Protocol.*:.*SSLv"; then
            local proto_name
            proto_name=$(echo "${result}" | grep "Protocol" | awk '{print $NF}')
            case "${proto}" in
                ssl3|tls1|tls1_1)
                    log WARNING "Insecure protocol supported: ${proto_name}"
                    ((failed++)) ;;
                tls1_2|tls1_3)
                    log SUCCESS "Secure protocol supported: ${proto_name}"
                    ((passed++)) ;;
            esac
        else
            case "${proto}" in
                ssl3|tls1|tls1_1) log SUCCESS "Insecure protocol ${proto} is disabled"; ((passed++)) ;;
                tls1_2|tls1_3) log WARNING "Secure protocol ${proto} not supported"; ((failed++)) ;;
            esac
        fi
    done

    # Cipher strength check
    ((total++))
    local weak_ciphers
    weak_ciphers=$(echo | openssl s_client -connect "${target}:${port}" -cipher 'NULL:EXPORT:LOW:DES:RC4:MD5:PSK:SRP:CAMELLIA' 2>&1 | grep -c "Cipher.*:" || echo "0")
    if [[ "${weak_ciphers}" -eq 0 ]]; then
        log SUCCESS "No weak ciphers accepted"
        ((passed++))
    else
        log WARNING "Weak ciphers may be accepted"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD TLS Audit Report"; echo "Generated: $(date)"; echo "Target: ${target}:${port}"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
