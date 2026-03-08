#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD Module: Cloud IAM Policy & Privilege Review      ║
# ╚══════════════════════════════════════════════════════════════╝

run_cloud_iam() {
    local report_file="${REPORTS_DIR}/cloud_iam_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CLOUD IAM POLICY & PRIVILEGE REVIEW"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # ── AWS IAM ────────────────────────────────────────────────
    if check_dependency "aws"; then
        log INFO "[AWS IAM] Checking for root account usage..."
        ((total++))
        local root_keys
        root_keys=$(aws iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent' --output text 2>/dev/null) || true
        if [[ "${root_keys}" == "0" ]]; then
            log SUCCESS "[AWS] Root account has no access keys"
            ((passed++))
        else
            log WARNING "[AWS] Root account has active access keys — remove them"
            ((failed++))
        fi

        log INFO "[AWS IAM] Checking MFA enforcement on IAM users..."
        ((total++))
        local users_without_mfa
        users_without_mfa=$(aws iam list-users --query 'Users[].UserName' --output text 2>/dev/null | while read -r user; do
            mfa=$(aws iam list-mfa-devices --user-name "${user}" --query 'MFADevices' --output text 2>/dev/null)
            [[ -z "${mfa}" ]] && echo "${user}"
        done) || true
        if [[ -z "${users_without_mfa}" ]]; then
            log SUCCESS "[AWS] All IAM users have MFA enabled"
            ((passed++))
        else
            log WARNING "[AWS] Users without MFA: ${users_without_mfa}"
            ((failed++))
        fi

        log INFO "[AWS IAM] Checking for overly permissive policies (*)..."
        ((total++))
        local star_policies
        star_policies=$(aws iam list-policies --scope Local --query 'Policies[].Arn' --output text 2>/dev/null | while read -r arn; do
            ver=$(aws iam get-policy --policy-arn "${arn}" --query 'Policy.DefaultVersionId' --output text 2>/dev/null)
            doc=$(aws iam get-policy-version --policy-arn "${arn}" --version-id "${ver}" --query 'PolicyVersion.Document' --output json 2>/dev/null)
            echo "${doc}" | grep -q '"Action": "\*"' && echo "${arn}"
        done) || true
        if [[ -z "${star_policies}" ]]; then
            log SUCCESS "[AWS] No local policies with wildcard (*) Action"
            ((passed++))
        else
            log WARNING "[AWS] Policies with wildcard Actions found — review for least privilege"
            ((failed++))
        fi

        log INFO "[AWS IAM] Checking for unused IAM credentials (90+ days)..."
        ((total++))
        aws iam generate-credential-report &>/dev/null || true
        sleep 2
        local stale_creds
        stale_creds=$(aws iam get-credential-report --output text --query 'Content' 2>/dev/null | base64 -d 2>/dev/null | awk -F, 'NR>1 && $5!="N/A" { split($5,a,"T"); if (systime()-mktime(gensub(/-/," ","g",a[1])" 0 0 0") > 7776000) print $1 }' 2>/dev/null) || true
        if [[ -z "${stale_creds}" ]]; then
            log SUCCESS "[AWS] No credentials unused for 90+ days"
            ((passed++))
        else
            log WARNING "[AWS] Stale credentials (90+ days): ${stale_creds}"
            ((failed++))
        fi

        log INFO "[AWS IAM] Checking password policy strength..."
        ((total++))
        local pw_policy
        pw_policy=$(aws iam get-account-password-policy 2>/dev/null) || true
        if [[ -n "${pw_policy}" ]]; then
            local min_len
            min_len=$(echo "${pw_policy}" | jq -r '.PasswordPolicy.MinimumPasswordLength' 2>/dev/null)
            if [[ "${min_len}" -ge 14 ]]; then
                log SUCCESS "[AWS] Password policy minimum length: ${min_len} (meets recommendation)"
                ((passed++))
            else
                log WARNING "[AWS] Password policy minimum length: ${min_len} (recommend 14+)"
                ((failed++))
            fi
        else
            log WARNING "[AWS] No custom password policy set"
            ((failed++))
        fi
    else
        log INFO "[AWS] AWS CLI not available — skipping IAM checks"
    fi

    # ── Azure IAM ──────────────────────────────────────────────
    if check_dependency "az"; then
        log INFO "[Azure] Checking for Global Administrator role assignments..."
        ((total++))
        local global_admins
        global_admins=$(az role assignment list --role "Global Administrator" --query '[].principalName' -o tsv 2>/dev/null) || true
        if [[ -n "${global_admins}" ]]; then
            local admin_count
            admin_count=$(echo "${global_admins}" | wc -l)
            if [[ ${admin_count} -le 4 ]]; then
                log SUCCESS "[Azure] Global Admins count (${admin_count}) within recommended limit"
                ((passed++))
            else
                log WARNING "[Azure] ${admin_count} Global Admins — reduce to 2-4"
                ((failed++))
            fi
        fi
    fi

    # ── Summary ────────────────────────────────────────────────
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  IAM REVIEW SUMMARY"
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "Total checks:  ${total}"
    log SUCCESS "Passed:        ${passed}"
    log ERROR "Failed:        ${failed}"
    echo ""

    {
        echo "KWT5H13LD IAM Review Report"
        echo "Generated: $(date)"
        echo "=========================="
        echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"
    } > "${report_file}"
}
