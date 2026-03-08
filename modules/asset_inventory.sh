#!/usr/bin/env bash
run_asset_inventory() {
    local report_file="${REPORTS_DIR}/asset_inventory_${TIMESTAMP}.${OUTPUT_FORMAT:-txt}"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  SYSTEM ASSET & SOFTWARE INVENTORY"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    {
        echo "=== SYSTEM INFORMATION ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo ""

        echo "=== HARDWARE ==="
        echo "CPU: $(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs)"
        echo "Cores: $(nproc 2>/dev/null)"
        echo "RAM: $(free -h 2>/dev/null | awk '/Mem:/{print $2}')"
        echo "Disk:"
        lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null
        echo ""

        echo "=== NETWORK INTERFACES ==="
        ip -br addr 2>/dev/null || ifconfig 2>/dev/null
        echo ""

        echo "=== INSTALLED PACKAGES ==="
        if check_dependency "dpkg"; then
            echo "Package manager: dpkg/apt"
            echo "Total packages: $(dpkg -l 2>/dev/null | grep -c '^ii')"
        elif check_dependency "rpm"; then
            echo "Package manager: rpm/yum"
            echo "Total packages: $(rpm -qa 2>/dev/null | wc -l)"
        fi
        echo ""

        echo "=== RUNNING SERVICES ==="
        systemctl list-units --type=service --state=running 2>/dev/null | head -30
    } | tee "${report_file}"

    echo ""
    log SUCCESS "Asset inventory saved: ${report_file}"
    echo ""
}
