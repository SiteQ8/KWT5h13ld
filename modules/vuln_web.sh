#!/usr/bin/env bash
# KWT5H13LD Module: Web Application Security Headers & Config Check

run_vuln_web() {
    local report_file="${REPORTS_DIR}/vuln_web_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  WEB APPLICATION SECURITY HEADERS CHECK"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local target="${TARGET:-localhost}"
    [[ "${target}" != http* ]] && target="https://${target}"
    local total=0 passed=0 failed=0

    if ! check_dependency "curl"; then
        log ERROR "curl required for web checks"
        return 1
    fi

    log INFO "Target: ${target}"
    local headers
    headers=$(curl -sI -L --max-time 10 "${target}" 2>/dev/null)

    if [[ -z "${headers}" ]]; then
        log ERROR "Could not connect to ${target}"
        return 1
    fi

    check_header() {
        local name="$1" desc="$2"
        ((total++))
        if echo "${headers}" | grep -qi "^${name}:"; then
            local val
            val=$(echo "${headers}" | grep -i "^${name}:" | head -1 | cut -d: -f2- | xargs)
            log SUCCESS "${desc}: ${val}"
            ((passed++))
        else
            log WARNING "${desc}: MISSING"
            ((failed++))
        fi
    }

    check_header "Strict-Transport-Security" "HSTS"
    check_header "Content-Security-Policy" "CSP"
    check_header "X-Content-Type-Options" "X-Content-Type-Options"
    check_header "X-Frame-Options" "X-Frame-Options"
    check_header "X-XSS-Protection" "X-XSS-Protection"
    check_header "Referrer-Policy" "Referrer-Policy"
    check_header "Permissions-Policy" "Permissions-Policy"

    # Server header (should be hidden)
    ((total++))
    if echo "${headers}" | grep -qi "^Server:"; then
        local server_val
        server_val=$(echo "${headers}" | grep -i "^Server:" | head -1 | cut -d: -f2- | xargs)
        log WARNING "Server header exposed: ${server_val}"
        ((failed++))
    else
        log SUCCESS "Server header is hidden"
        ((passed++))
    fi

    # X-Powered-By (should be hidden)
    ((total++))
    if echo "${headers}" | grep -qi "^X-Powered-By:"; then
        log WARNING "X-Powered-By header exposed (technology disclosure)"
        ((failed++))
    else
        log SUCCESS "X-Powered-By header is hidden"
        ((passed++))
    fi

    # Cookie security flags
    ((total++))
    local cookies
    cookies=$(echo "${headers}" | grep -i "^Set-Cookie:")
    if [[ -n "${cookies}" ]]; then
        if echo "${cookies}" | grep -qi "Secure" && echo "${cookies}" | grep -qi "HttpOnly"; then
            log SUCCESS "Cookies have Secure and HttpOnly flags"
            ((passed++))
        else
            log WARNING "Cookies missing Secure or HttpOnly flags"
            ((failed++))
        fi
    else
        log INFO "No cookies set in response"
        ((passed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD Web Security Report"; echo "Generated: $(date)"; echo "Target: ${target}"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
