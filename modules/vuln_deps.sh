#!/usr/bin/env bash
# KWT5H13LD Module: Dependency & Package Vulnerability Audit

run_vuln_deps() {
    local report_file="${REPORTS_DIR}/vuln_deps_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  DEPENDENCY & PACKAGE VULNERABILITY AUDIT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # System packages
    log INFO "Checking system package vulnerabilities..."
    if check_dependency "apt"; then
        ((total++))
        apt list --installed 2>/dev/null | wc -l | xargs -I{} log INFO "Installed packages: {}"
        local upgradable
        upgradable=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
        if [[ ${upgradable} -eq 0 ]]; then
            log SUCCESS "All system packages are up to date"
            ((passed++))
        else
            log WARNING "${upgradable} packages have available updates"
            ((failed++))
        fi
    fi

    # NPM audit
    if check_dependency "npm"; then
        local npm_dirs
        npm_dirs=$(find / -maxdepth 4 -name "package-lock.json" -not -path "*/node_modules/*" 2>/dev/null | head -5)
        for pkg_lock in ${npm_dirs}; do
            local dir
            dir=$(dirname "${pkg_lock}")
            ((total++))
            log INFO "Running npm audit in ${dir}..."
            local audit_result
            audit_result=$(cd "${dir}" && npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities.high // 0, .metadata.vulnerabilities.critical // 0' 2>/dev/null)
            local high crit
            high=$(echo "${audit_result}" | head -1)
            crit=$(echo "${audit_result}" | tail -1)
            if [[ "${high:-0}" -eq 0 && "${crit:-0}" -eq 0 ]]; then
                log SUCCESS "No high/critical npm vulnerabilities in ${dir}"
                ((passed++))
            else
                log WARNING "npm: ${high} high, ${crit} critical in ${dir}"
                ((failed++))
            fi
        done
    fi

    # Python pip audit
    if check_dependency "pip"; then
        ((total++))
        if check_dependency "pip-audit"; then
            log INFO "Running pip-audit..."
            local pip_vulns
            pip_vulns=$(pip-audit --format json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
            if [[ "${pip_vulns}" -eq 0 ]]; then
                log SUCCESS "No known pip package vulnerabilities"
                ((passed++))
            else
                log WARNING "${pip_vulns} pip packages have known vulnerabilities"
                ((failed++))
            fi
        else
            log INFO "pip-audit not installed — install with: pip install pip-audit"
        fi
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""
    { echo "KWT5H13LD Dependency Audit Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed}"; } > "${report_file}"
}
