#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD Module: Cloud Network & Firewall Inspection      ║
# ╚══════════════════════════════════════════════════════════════╝

run_cloud_network() {
    local report_file="${REPORTS_DIR}/cloud_network_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CLOUD NETWORK & FIREWALL INSPECTION"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    if check_dependency "aws"; then
        # VPC Flow Logs
        log INFO "[AWS] Checking VPC Flow Logs status..."
        ((total++))
        local vpcs
        vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text 2>/dev/null) || true
        for vpc in ${vpcs}; do
            local flow_logs
            flow_logs=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=${vpc}" --query 'FlowLogs[].FlowLogId' --output text 2>/dev/null) || true
            if [[ -n "${flow_logs}" ]]; then
                log SUCCESS "[AWS] VPC ${vpc} has flow logs enabled"
                ((passed++))
            else
                log WARNING "[AWS] VPC ${vpc} has NO flow logs — enable for network visibility"
                ((failed++))
            fi
        done

        # Default security group restrictions
        log INFO "[AWS] Checking default security groups for open rules..."
        ((total++))
        local default_sgs
        default_sgs=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=default" \
            --query 'SecurityGroups[?length(IpPermissions)>`0`].[GroupId,VpcId]' --output text 2>/dev/null) || true
        if [[ -z "${default_sgs}" ]]; then
            log SUCCESS "[AWS] Default security groups have no inbound rules"
            ((passed++))
        else
            log WARNING "[AWS] Default security groups with active rules:"
            echo "${default_sgs}" | while read -r line; do log WARNING "  → ${line}"; done
            ((failed++))
        fi

        # Check for public subnets auto-assigning public IPs
        log INFO "[AWS] Checking subnets auto-assigning public IPs..."
        ((total++))
        local public_subnets
        public_subnets=$(aws ec2 describe-subnets --query 'Subnets[?MapPublicIpOnLaunch==`true`].[SubnetId,CidrBlock]' --output text 2>/dev/null) || true
        if [[ -n "${public_subnets}" ]]; then
            log WARNING "[AWS] Subnets auto-assigning public IPs (verify this is intentional):"
            echo "${public_subnets}" | while read -r line; do log WARNING "  → ${line}"; done
            ((failed++))
        else
            log SUCCESS "[AWS] No subnets auto-assigning public IPs"
            ((passed++))
        fi

        # Check for unencrypted ELB listeners
        log INFO "[AWS] Checking load balancers for HTTP (unencrypted) listeners..."
        ((total++))
        local http_listeners
        http_listeners=$(aws elbv2 describe-listeners --query 'Listeners[?Protocol==`HTTP`].[ListenerArn]' --output text 2>/dev/null) || true
        if [[ -z "${http_listeners}" ]]; then
            log SUCCESS "[AWS] No unencrypted HTTP listeners on load balancers"
            ((passed++))
        else
            log WARNING "[AWS] HTTP listeners found — migrate to HTTPS"
            ((failed++))
        fi
    fi

    if check_dependency "az"; then
        log INFO "[Azure] Checking for NSGs not attached to subnets/NICs..."
        ((total++))
        local unattached_nsgs
        unattached_nsgs=$(az network nsg list --query '[?length(subnets)==`0` && length(networkInterfaces)==`0`].name' -o tsv 2>/dev/null) || true
        if [[ -n "${unattached_nsgs}" ]]; then
            log WARNING "[Azure] Unattached NSGs: ${unattached_nsgs}"
            ((failed++))
        else
            log SUCCESS "[Azure] All NSGs are attached to resources"
            ((passed++))
        fi
    fi

    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CLOUD NETWORK SUMMARY"
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed}"
    echo ""

    {
        echo "KWT5H13LD Cloud Network Report"
        echo "Generated: $(date)"
        echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"
    } > "${report_file}"
}
