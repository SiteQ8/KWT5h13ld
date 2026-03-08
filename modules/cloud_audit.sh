#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD Module: Cloud Storage & Service Audit            ║
# ║  Detects public buckets, misconfigurations, open services   ║
# ╚══════════════════════════════════════════════════════════════╝

run_cloud_audit() {
    local report_file="${REPORTS_DIR}/cloud_audit_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CLOUD STORAGE & SERVICE MISCONFIGURATION AUDIT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""
    
    local total_checks=0
    local passed=0
    local failed=0
    local warnings=0

    # ── AWS Checks ─────────────────────────────────────────────
    if check_dependency "aws"; then
        log INFO "Scanning AWS environment..."
        
        # Check S3 bucket public access
        log INFO "[AWS] Checking S3 bucket public access settings..."
        ((total_checks++))
        local buckets
        buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null) || true
        if [[ -n "${buckets}" ]]; then
            for bucket in ${buckets}; do
                local public_block
                public_block=$(aws s3api get-public-access-block --bucket "${bucket}" 2>/dev/null) || true
                if [[ -z "${public_block}" ]]; then
                    log WARNING "[AWS] S3 bucket '${bucket}' has NO public access block configured"
                    ((failed++))
                else
                    local block_all
                    block_all=$(echo "${public_block}" | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls' 2>/dev/null)
                    if [[ "${block_all}" == "true" ]]; then
                        log SUCCESS "[AWS] S3 bucket '${bucket}' has public access blocked"
                        ((passed++))
                    else
                        log WARNING "[AWS] S3 bucket '${bucket}' may allow public access"
                        ((failed++))
                    fi
                fi
            done
        else
            log INFO "[AWS] No S3 buckets found or not configured"
        fi

        # Check for public EC2 security groups
        log INFO "[AWS] Checking EC2 security groups for 0.0.0.0/0 ingress..."
        ((total_checks++))
        local open_sgs
        open_sgs=$(aws ec2 describe-security-groups \
            --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName]' \
            --output text 2>/dev/null) || true
        if [[ -n "${open_sgs}" ]]; then
            log WARNING "[AWS] Security groups with open 0.0.0.0/0 ingress found:"
            echo "${open_sgs}" | while read -r line; do
                log WARNING "  → ${line}"
            done
            ((failed++))
        else
            log SUCCESS "[AWS] No security groups with unrestricted ingress found"
            ((passed++))
        fi

        # Check RDS public accessibility
        log INFO "[AWS] Checking RDS instances for public accessibility..."
        ((total_checks++))
        local public_rds
        public_rds=$(aws rds describe-db-instances \
            --query 'DBInstances[?PubliclyAccessible==`true`].[DBInstanceIdentifier]' \
            --output text 2>/dev/null) || true
        if [[ -n "${public_rds}" ]]; then
            log WARNING "[AWS] Publicly accessible RDS instances: ${public_rds}"
            ((failed++))
        else
            log SUCCESS "[AWS] No publicly accessible RDS instances"
            ((passed++))
        fi

        # Check CloudTrail status
        log INFO "[AWS] Verifying CloudTrail is enabled..."
        ((total_checks++))
        local trails
        trails=$(aws cloudtrail describe-trails --query 'trailList[].Name' --output text 2>/dev/null) || true
        if [[ -n "${trails}" ]]; then
            log SUCCESS "[AWS] CloudTrail trails active: ${trails}"
            ((passed++))
        else
            log WARNING "[AWS] No CloudTrail trails found — audit logging may be disabled"
            ((failed++))
        fi

        # Check EBS encryption default
        log INFO "[AWS] Checking EBS default encryption..."
        ((total_checks++))
        local ebs_enc
        ebs_enc=$(aws ec2 get-ebs-encryption-by-default --query 'EbsEncryptionByDefault' --output text 2>/dev/null) || true
        if [[ "${ebs_enc}" == "True" ]]; then
            log SUCCESS "[AWS] EBS encryption by default is enabled"
            ((passed++))
        else
            log WARNING "[AWS] EBS encryption by default is NOT enabled"
            ((failed++))
        fi
    else
        log INFO "[AWS] AWS CLI not installed — skipping AWS checks"
    fi

    # ── Azure Checks ───────────────────────────────────────────
    if check_dependency "az"; then
        log INFO "Scanning Azure environment..."
        
        # Check storage account public access
        log INFO "[Azure] Checking storage accounts for public blob access..."
        ((total_checks++))
        local storage_accounts
        storage_accounts=$(az storage account list --query '[].{name:name,allowBlobPublicAccess:allowBlobPublicAccess}' -o tsv 2>/dev/null) || true
        if [[ -n "${storage_accounts}" ]]; then
            echo "${storage_accounts}" | while IFS=$'\t' read -r name public_access; do
                if [[ "${public_access}" == "true" || "${public_access}" == "True" ]]; then
                    log WARNING "[Azure] Storage account '${name}' allows public blob access"
                    ((failed++))
                else
                    log SUCCESS "[Azure] Storage account '${name}' blocks public blob access"
                    ((passed++))
                fi
            done
        fi

        # Check NSG rules
        log INFO "[Azure] Checking Network Security Groups for permissive rules..."
        ((total_checks++))
        local open_nsgs
        open_nsgs=$(az network nsg list --query '[].{name:name,rules:securityRules[?sourceAddressPrefix==`*` && access==`Allow` && direction==`Inbound`]}' -o tsv 2>/dev/null) || true
        if [[ -n "${open_nsgs}" ]]; then
            log WARNING "[Azure] NSGs with permissive inbound rules detected"
            ((failed++))
        else
            log SUCCESS "[Azure] No overly permissive NSG rules detected"
            ((passed++))
        fi
    else
        log INFO "[Azure] Azure CLI not installed — skipping Azure checks"
    fi

    # ── GCP Checks ─────────────────────────────────────────────
    if check_dependency "gcloud"; then
        log INFO "Scanning GCP environment..."
        
        # Check GCS bucket access
        log INFO "[GCP] Checking Cloud Storage buckets for public access..."
        ((total_checks++))
        local gcs_buckets
        gcs_buckets=$(gsutil ls 2>/dev/null) || true
        if [[ -n "${gcs_buckets}" ]]; then
            for bucket_url in ${gcs_buckets}; do
                local acl
                acl=$(gsutil iam get "${bucket_url}" 2>/dev/null | grep -c "allUsers\|allAuthenticatedUsers" || true)
                if [[ "${acl}" -gt 0 ]]; then
                    log WARNING "[GCP] Bucket ${bucket_url} is publicly accessible"
                    ((failed++))
                else
                    log SUCCESS "[GCP] Bucket ${bucket_url} is not public"
                    ((passed++))
                fi
            done
        fi

        # Check firewall rules
        log INFO "[GCP] Checking firewall rules for 0.0.0.0/0 source ranges..."
        ((total_checks++))
        local open_fw
        open_fw=$(gcloud compute firewall-rules list --filter="sourceRanges=0.0.0.0/0 AND direction=INGRESS" --format="value(name)" 2>/dev/null) || true
        if [[ -n "${open_fw}" ]]; then
            log WARNING "[GCP] Firewall rules allowing all source IPs:"
            echo "${open_fw}" | while read -r rule; do
                log WARNING "  → ${rule}"
            done
            ((failed++))
        else
            log SUCCESS "[GCP] No firewall rules with unrestricted source ranges"
            ((passed++))
        fi
    else
        log INFO "[GCP] gcloud CLI not installed — skipping GCP checks"
    fi

    # ── General Cloud Hygiene ──────────────────────────────────
    log INFO "Running general cloud hygiene checks..."
    
    # Check for exposed credentials in common locations
    log INFO "Scanning for credential files in common locations..."
    ((total_checks++))
    local cred_files=("$HOME/.aws/credentials" "$HOME/.azure/accessTokens.json" "$HOME/.config/gcloud/application_default_credentials.json" "$HOME/.docker/config.json")
    local cred_found=0
    for cf in "${cred_files[@]}"; do
        if [[ -f "${cf}" ]]; then
            local perms
            perms=$(stat -c "%a" "${cf}" 2>/dev/null || stat -f "%Lp" "${cf}" 2>/dev/null)
            if [[ "${perms}" != "600" && "${perms}" != "400" ]]; then
                log WARNING "Credential file ${cf} has permissive permissions: ${perms}"
                ((cred_found++))
            fi
        fi
    done
    if [[ ${cred_found} -eq 0 ]]; then
        log SUCCESS "Credential file permissions are properly restricted"
        ((passed++))
    else
        ((failed++))
    fi

    # ── Summary ────────────────────────────────────────────────
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CLOUD AUDIT SUMMARY"
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "Total checks:  ${total_checks}"
    log SUCCESS "Passed:        ${passed}"
    log WARNING "Warnings:      ${warnings}"
    log ERROR "Failed:        ${failed}"
    log INFO "Report saved:  ${report_file}"
    echo ""

    # Write report
    {
        echo "KWT5H13LD Cloud Audit Report"
        echo "Generated: $(date)"
        echo "=========================="
        echo "Total: ${total_checks} | Pass: ${passed} | Fail: ${failed} | Warn: ${warnings}"
    } > "${report_file}"
}
