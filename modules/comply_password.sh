#!/usr/bin/env bash
run_comply_password() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  PASSWORD POLICY AUDIT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    local total=0 passed=0 failed=0

    # login.defs checks
    local defs="/etc/login.defs"
    if [[ -f "${defs}" ]]; then
        local params=("PASS_MAX_DAYS:90:Max password age" "PASS_MIN_DAYS:1:Min password age" "PASS_MIN_LEN:8:Min password length" "PASS_WARN_AGE:14:Password warning days")
        for check in "${params[@]}"; do
            IFS=':' read -r param expected desc <<< "${check}"
            ((total++))
            local actual
            actual=$(grep "^${param}" "${defs}" 2>/dev/null | awk '{print $2}')
            if [[ -n "${actual}" ]]; then
                log INFO "  ${desc}: ${actual} (recommended ≤${expected})"
                ((passed++))
            else
                log WARNING "  ${desc}: not configured"
                ((failed++))
            fi
        done
    fi

    # PAM password quality
    ((total++))
    if [[ -f /etc/pam.d/common-password ]] || [[ -f /etc/pam.d/system-auth ]]; then
        local pam_file="/etc/pam.d/common-password"
        [[ ! -f "${pam_file}" ]] && pam_file="/etc/pam.d/system-auth"
        if grep -q "pam_pwquality\|pam_cracklib" "${pam_file}" 2>/dev/null; then
            log SUCCESS "  PAM password quality module configured"
            ((passed++))
        else
            log WARNING "  No PAM password quality module"
            ((failed++))
        fi
    fi

    # Account lockout
    ((total++))
    if grep -rq "pam_tally2\|pam_faillock" /etc/pam.d/ 2>/dev/null; then
        log SUCCESS "  Account lockout policy configured"
        ((passed++))
    else
        log WARNING "  No account lockout policy found"
        ((failed++))
    fi

    # Empty passwords
    ((total++))
    local empty
    empty=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | wc -l)
    if [[ ${empty} -eq 0 ]]; then
        log SUCCESS "  No accounts with empty passwords"
        ((passed++))
    else
        log WARNING "  ${empty} accounts have empty passwords"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Password Policy Score: ${score}% | Pass: ${passed}/${total}"
    echo ""
}
