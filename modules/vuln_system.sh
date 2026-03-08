#!/usr/bin/env bash
# KWT5H13LD Module: System CVE Vulnerability Scan

run_vuln_system() {
    local report_file="${REPORTS_DIR}/vuln_system_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SYSTEM VULNERABILITY SCAN (CVE CHECK)"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # Kernel version & known vulns
    ((total++))
    local kernel_ver
    kernel_ver=$(uname -r 2>/dev/null)
    log INFO "Kernel version: ${kernel_ver}"

    # Check for pending security updates
    log INFO "Checking for pending security updates..."
    ((total++))
    if check_dependency "apt"; then
        local sec_updates
        sec_updates=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
        if [[ ${sec_updates} -eq 0 ]]; then
            log SUCCESS "No pending security updates"
            ((passed++))
        else
            log WARNING "${sec_updates} security updates available"
            ((failed++))
        fi
    elif check_dependency "yum"; then
        local yum_sec
        yum_sec=$(yum updateinfo list security 2>/dev/null | grep -c "security" || echo "0")
        if [[ ${yum_sec} -eq 0 ]]; then
            log SUCCESS "No pending security updates"
            ((passed++))
        else
            log WARNING "${yum_sec} security advisories pending"
            ((failed++))
        fi
    fi

    # SUID/SGID binaries
    log INFO "Scanning for SUID/SGID binaries..."
    ((total++))
    local suid_count
    suid_count=$(find / -perm /6000 -type f 2>/dev/null | wc -l)
    log INFO "Found ${suid_count} SUID/SGID binaries"
    local suspicious_suids=("nmap" "vim" "find" "bash" "sh" "python" "perl" "ruby" "php" "node" "gcc" "wget" "curl" "nc" "ncat")
    local found_suspicious=0
    for bin in "${suspicious_suids[@]}"; do
        if find / -perm /4000 -name "${bin}" -type f 2>/dev/null | grep -q .; then
            log WARNING "Suspicious SUID binary: ${bin}"
            ((found_suspicious++))
        fi
    done
    if [[ ${found_suspicious} -eq 0 ]]; then
        log SUCCESS "No suspicious SUID binaries found"
        ((passed++))
    else
        ((failed++))
    fi

    # World-writable files in system directories
    log INFO "Checking for world-writable files in /etc..."
    ((total++))
    local ww_files
    ww_files=$(find /etc -perm -0002 -type f 2>/dev/null | wc -l)
    if [[ ${ww_files} -eq 0 ]]; then
        log SUCCESS "No world-writable files in /etc"
        ((passed++))
    else
        log WARNING "${ww_files} world-writable files found in /etc"
        ((failed++))
    fi

    # Unowned files
    log INFO "Checking for unowned files..."
    ((total++))
    local unowned
    unowned=$(find /usr /etc /var -nouser -o -nogroup 2>/dev/null | head -20 | wc -l)
    if [[ ${unowned} -eq 0 ]]; then
        log SUCCESS "No unowned files found"
        ((passed++))
    else
        log WARNING "${unowned} unowned files found — may indicate compromised packages"
        ((failed++))
    fi

    # Trivy integration
    if check_dependency "trivy"; then
        log INFO "Running Trivy filesystem scan..."
        ((total++))
        local trivy_count
        trivy_count=$(trivy fs / --severity HIGH,CRITICAL --quiet 2>/dev/null | grep -c "CRITICAL\|HIGH" || echo "0")
        if [[ ${trivy_count} -eq 0 ]]; then
            log SUCCESS "No HIGH/CRITICAL vulnerabilities found by Trivy"
            ((passed++))
        else
            log WARNING "Trivy found ${trivy_count} HIGH/CRITICAL findings"
            ((failed++))
        fi
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD Vulnerability Scan Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
