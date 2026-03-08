#!/usr/bin/env bash
# KWT5H13LD Module: Kernel & Sysctl Security Check

run_harden_kernel() {
    local report_file="${REPORTS_DIR}/harden_kernel_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  KERNEL & SYSCTL SECURITY CHECK"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local total=0 passed=0 failed=0

    # Kernel security parameters
    declare -A kernel_params=(
        ["kernel.dmesg_restrict"]="1:Restrict dmesg access"
        ["kernel.kptr_restrict"]="2:Restrict kernel pointer exposure"
        ["kernel.yama.ptrace_scope"]="1:Restrict ptrace access"
        ["kernel.sysrq"]="0:Magic SysRq disabled"
        ["kernel.core_uses_pid"]="1:Core dumps use PID naming"
        ["kernel.randomize_va_space"]="2:Full ASLR enabled"
        ["kernel.panic"]="60:Auto-reboot on panic"
        ["kernel.panic_on_oops"]="1:Panic on oops"
        ["fs.suid_dumpable"]="0:SUID core dumps disabled"
        ["fs.protected_hardlinks"]="1:Hardlink protection enabled"
        ["fs.protected_symlinks"]="1:Symlink protection enabled"
        ["net.core.bpf_jit_harden"]="2:BPF JIT hardened"
        ["net.ipv4.conf.all.rp_filter"]="1:Reverse path filtering"
        ["net.ipv4.conf.default.rp_filter"]="1:Default reverse path filtering"
        ["net.ipv6.conf.all.accept_ra"]="0:IPv6 router advertisements disabled"
        ["net.ipv4.tcp_timestamps"]="0:TCP timestamps disabled"
    )

    for param in "${!kernel_params[@]}"; do
        IFS=':' read -r expected desc <<< "${kernel_params[$param]}"
        ((total++))
        local actual
        actual=$(sysctl -n "${param}" 2>/dev/null || echo "unavailable")
        if [[ "${actual}" == "${expected}" ]]; then
            log SUCCESS "  ${desc} (${param}=${actual})"
            ((passed++))
        elif [[ "${actual}" == "unavailable" ]]; then
            log INFO "  ${desc} — parameter not available"
            ((total--))
        else
            log WARNING "  ${desc} — ${param}=${actual} (expected: ${expected})"
            ((failed++))
        fi
    done

    # Check loaded kernel modules
    log INFO ""
    log INFO "Checking for unnecessary/dangerous kernel modules..."
    local dangerous_modules=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf" "dccp" "sctp" "rds" "tipc")
    for mod in "${dangerous_modules[@]}"; do
        ((total++))
        if lsmod 2>/dev/null | grep -q "^${mod}"; then
            log WARNING "  Module '${mod}' is loaded — consider blacklisting"
            ((failed++))
        else
            log SUCCESS "  Module '${mod}' is not loaded"
            ((passed++))
        fi
    done

    # Check module blacklist
    log INFO ""
    log INFO "Checking module blacklist configuration..."
    ((total++))
    if [[ -d /etc/modprobe.d ]]; then
        local blacklist_count
        blacklist_count=$(grep -rh "^blacklist\|^install.*\/bin\/true\|^install.*\/bin\/false" /etc/modprobe.d/ 2>/dev/null | wc -l)
        log INFO "  Module blacklist entries found: ${blacklist_count}"
        if [[ ${blacklist_count} -ge 5 ]]; then
            log SUCCESS "  Module blacklisting is actively configured"
            ((passed++))
        else
            log WARNING "  Limited module blacklisting — review CIS recommendations"
            ((failed++))
        fi
    fi

    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    local score=0
    [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"
    echo ""

    { echo "KWT5H13LD Kernel Security Report"; echo "Generated: $(date)"; echo "Total: ${total} | Pass: ${passed} | Fail: ${failed} | Score: ${score}%"; } > "${report_file}"
}
