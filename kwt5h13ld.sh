#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  KWT5H13LD - Kuwait Shield Security Toolkit                        ║
# ║  Guarding Kuwait's Cyber Gates                                     ║
# ║                                                                    ║
# ║  Author : Ali AlEnezi (SiteQ8)                                     ║
# ║  Email  : Site@hotmail.com                                         ║
# ║  GitHub : https://github.com/SiteQ8                                ║
# ║  License: MIT                                                      ║
# ║                                                                    ║
# ║  A Blue Team defensive security toolkit for infrastructure         ║
# ║  hardening, cloud security auditing, network defense, compliance   ║
# ║  checking, and incident response.                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Global Configuration ───────────────────────────────────────────
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
CONFIG_DIR="${SCRIPT_DIR}/config"
LOGS_DIR="${SCRIPT_DIR}/logs"
REPORTS_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${LOGS_DIR}/kwt5h13ld_${TIMESTAMP}.log"

# ─── Colors & Formatting ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Ensure Directories Exist ──────────────────────────────────────
mkdir -p "${LOGS_DIR}" "${REPORTS_DIR}" "${CONFIG_DIR}"

# ─── Logging ────────────────────────────────────────────────────────
log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${ts}] [${level}] ${msg}" >> "${LOG_FILE}"
    case "${level}" in
        INFO)    echo -e "${CYAN}[*]${NC} ${msg}" ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC} ${msg}" ;;
        WARNING) echo -e "${YELLOW}[!]${NC} ${msg}" ;;
        ERROR)   echo -e "${RED}[✗]${NC} ${msg}" ;;
        DEBUG)   [[ "${DEBUG:-0}" == "1" ]] && echo -e "${GRAY}[D]${NC} ${msg}" ;;
    esac
}

# ─── Dependency Check ──────────────────────────────────────────────
check_dependency() {
    local cmd="$1"
    if command -v "${cmd}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log WARNING "Some modules require root privileges. Run with sudo for full functionality."
    fi
}

# ─── Banner ─────────────────────────────────────────────────────────
show_banner() {
    echo -e "${BLUE}"
    cat << 'BANNER'

    ██╗  ██╗██╗    ██╗████████╗███████╗██╗  ██╗ ██╗██████╗ ██╗     ██████╗
    ██║ ██╔╝██║    ██║╚══██╔══╝██╔════╝██║  ██║███║╚════██╗██║     ██╔══██╗
    █████╔╝ ██║ █╗ ██║   ██║   ███████╗███████║╚██║ █████╔╝██║     ██║  ██║
    ██╔═██╗ ██║███╗██║   ██║   ╚════██║██╔══██║ ██║ ╚═══██╗██║     ██║  ██║
    ██║  ██╗╚███╔███╔╝   ██║   ███████║██║  ██║ ██║██████╔╝███████╗██████╔╝
    ╚═╝  ╚═╝ ╚══╝╚══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═╝╚═════╝ ╚══════╝╚═════╝

BANNER
    echo -e "${NC}"
    echo -e "${WHITE}${BOLD}    Kuwait Shield Security Toolkit v${VERSION}${NC}"
    echo -e "${CYAN}    Guarding Kuwait's Cyber Gates${NC}"
    echo -e "${GRAY}    By Ali AlEnezi | SiteQ8 | Site@hotmail.com${NC}"
    echo -e ""
    echo -e "${BLUE}    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ─── Module Loader ──────────────────────────────────────────────────
load_module() {
    local module_name="$1"
    local module_path="${MODULES_DIR}/${module_name}.sh"
    if [[ -f "${module_path}" ]]; then
        source "${module_path}"
        log DEBUG "Loaded module: ${module_name}"
    else
        log ERROR "Module not found: ${module_name}"
        return 1
    fi
}

# ─── Help ───────────────────────────────────────────────────────────
show_help() {
    echo -e "${WHITE}${BOLD}USAGE:${NC}"
    echo -e "  ./kwt5h13ld.sh [MODULE] [OPTIONS]"
    echo ""
    echo -e "${WHITE}${BOLD}MODULES:${NC}"
    echo ""
    echo -e "  ${CYAN}Cloud Security${NC}"
    echo -e "    cloud-audit          Audit cloud storage & service misconfigurations"
    echo -e "    cloud-iam            Review IAM policies, roles & privilege escalation paths"
    echo -e "    cloud-network        Inspect cloud VPC, security groups & firewall rules"
    echo ""
    echo -e "  ${CYAN}System Hardening${NC}"
    echo -e "    harden-linux         Linux CIS benchmark hardening assessment"
    echo -e "    harden-ssh           SSH configuration security audit"
    echo -e "    harden-kernel        Kernel parameter & sysctl security check"
    echo -e "    harden-services      Service enumeration & unnecessary service detection"
    echo ""
    echo -e "  ${CYAN}Network Defense${NC}"
    echo -e "    net-scan             Network discovery & service enumeration"
    echo -e "    net-firewall         Firewall rule audit & gap analysis"
    echo -e "    net-dns              DNS security assessment (zone transfers, DNSSEC)"
    echo -e "    net-tls              TLS/SSL certificate & cipher audit"
    echo ""
    echo -e "  ${CYAN}Vulnerability Assessment${NC}"
    echo -e "    vuln-system          System vulnerability scan (CVE check)"
    echo -e "    vuln-web             Web application security headers & config check"
    echo -e "    vuln-deps            Dependency & package vulnerability audit"
    echo ""
    echo -e "  ${CYAN}Compliance & Policy${NC}"
    echo -e "    comply-cis           CIS Controls assessment"
    echo -e "    comply-iso27001      ISO 27001 control mapping check"
    echo -e "    comply-pci           PCI DSS requirement validation"
    echo -e "    comply-password      Password policy audit"
    echo ""
    echo -e "  ${CYAN}Log Analysis & Monitoring${NC}"
    echo -e "    log-auth             Authentication log analysis (brute force detection)"
    echo -e "    log-syslog           Syslog anomaly & pattern detection"
    echo -e "    log-audit            Auditd log review & suspicious activity flagging"
    echo ""
    echo -e "  ${CYAN}Incident Response${NC}"
    echo -e "    ir-snapshot          System state snapshot for forensic baseline"
    echo -e "    ir-processes         Running process analysis & anomaly detection"
    echo -e "    ir-connections       Active network connection investigation"
    echo -e "    ir-persistence       Persistence mechanism detection (cron, services, etc.)"
    echo ""
    echo -e "  ${CYAN}Container & Orchestration${NC}"
    echo -e "    container-docker     Docker security audit (CIS Docker Benchmark)"
    echo -e "    container-k8s        Kubernetes cluster security assessment"
    echo -e "    container-images     Container image vulnerability & config scan"
    echo ""
    echo -e "  ${CYAN}Asset & Inventory${NC}"
    echo -e "    asset-inventory      System asset & software inventory collection"
    echo -e "    asset-ports          Port & service inventory mapping"
    echo ""
    echo -e "  ${CYAN}Utility${NC}"
    echo -e "    report               Generate consolidated HTML/PDF security report"
    echo -e "    gui                  Launch the web-based GUI dashboard"
    echo -e "    update               Check for toolkit updates"
    echo -e "    health               Verify all dependencies & module health"
    echo ""
    echo -e "${WHITE}${BOLD}OPTIONS:${NC}"
    echo -e "  -o, --output FILE      Output report file path"
    echo -e "  -f, --format FORMAT    Report format: txt, json, html, csv (default: txt)"
    echo -e "  -t, --target HOST      Target host or IP (for network modules)"
    echo -e "  -v, --verbose          Enable verbose/debug output"
    echo -e "  -q, --quiet            Suppress banner & non-essential output"
    echo -e "  -h, --help             Show this help message"
    echo -e "  --no-color             Disable colored output"
    echo ""
    echo -e "${WHITE}${BOLD}EXAMPLES:${NC}"
    echo -e "  ${GREEN}./kwt5h13ld.sh harden-linux${NC}                     Run Linux hardening audit"
    echo -e "  ${GREEN}./kwt5h13ld.sh cloud-audit -f json${NC}              Cloud audit with JSON output"
    echo -e "  ${GREEN}./kwt5h13ld.sh net-tls -t example.com${NC}           TLS audit on target"
    echo -e "  ${GREEN}./kwt5h13ld.sh ir-snapshot -o /tmp/snap.txt${NC}     IR snapshot to file"
    echo -e "  ${GREEN}sudo ./kwt5h13ld.sh harden-linux -v${NC}             Full hardening scan (verbose)"
    echo ""
}

# ─── Interactive Menu ───────────────────────────────────────────────
show_menu() {
    echo -e "${WHITE}${BOLD}  SELECT A MODULE CATEGORY:${NC}"
    echo ""
    echo -e "    ${CYAN}[1]${NC}  Cloud Security Audit"
    echo -e "    ${CYAN}[2]${NC}  System Hardening Assessment"
    echo -e "    ${CYAN}[3]${NC}  Network Defense & Analysis"
    echo -e "    ${CYAN}[4]${NC}  Vulnerability Assessment"
    echo -e "    ${CYAN}[5]${NC}  Compliance & Policy Check"
    echo -e "    ${CYAN}[6]${NC}  Log Analysis & Monitoring"
    echo -e "    ${CYAN}[7]${NC}  Incident Response"
    echo -e "    ${CYAN}[8]${NC}  Container & Orchestration Security"
    echo -e "    ${CYAN}[9]${NC}  Asset & Inventory Management"
    echo -e "    ${CYAN}[10]${NC} Generate Security Report"
    echo -e "    ${CYAN}[11]${NC} Launch Web GUI"
    echo -e "    ${CYAN}[12]${NC} System Health Check"
    echo -e "    ${CYAN}[0]${NC}  Exit"
    echo ""
    echo -ne "    ${WHITE}${BOLD}kwt5h13ld ➜ ${NC}"
}

submenu_cloud() {
    echo ""
    echo -e "    ${WHITE}${BOLD}CLOUD SECURITY:${NC}"
    echo -e "    ${CYAN}[1]${NC} Cloud Storage & Service Misconfiguration Audit"
    echo -e "    ${CYAN}[2]${NC} IAM Policy & Privilege Review"
    echo -e "    ${CYAN}[3]${NC} Cloud Network & Firewall Inspection"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/cloud ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "cloud_audit" && run_cloud_audit ;;
        2) load_module "cloud_iam" && run_cloud_iam ;;
        3) load_module "cloud_network" && run_cloud_network ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_hardening() {
    echo ""
    echo -e "    ${WHITE}${BOLD}SYSTEM HARDENING:${NC}"
    echo -e "    ${CYAN}[1]${NC} Linux CIS Benchmark Assessment"
    echo -e "    ${CYAN}[2]${NC} SSH Configuration Audit"
    echo -e "    ${CYAN}[3]${NC} Kernel & Sysctl Security Check"
    echo -e "    ${CYAN}[4]${NC} Service Enumeration & Review"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/harden ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "harden_linux" && run_harden_linux ;;
        2) load_module "harden_ssh" && run_harden_ssh ;;
        3) load_module "harden_kernel" && run_harden_kernel ;;
        4) load_module "harden_services" && run_harden_services ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_network() {
    echo ""
    echo -e "    ${WHITE}${BOLD}NETWORK DEFENSE:${NC}"
    echo -e "    ${CYAN}[1]${NC} Network Discovery & Service Scan"
    echo -e "    ${CYAN}[2]${NC} Firewall Rule Audit"
    echo -e "    ${CYAN}[3]${NC} DNS Security Assessment"
    echo -e "    ${CYAN}[4]${NC} TLS/SSL Certificate & Cipher Audit"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/network ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "net_scan" && run_net_scan ;;
        2) load_module "net_firewall" && run_net_firewall ;;
        3) load_module "net_dns" && run_net_dns ;;
        4) load_module "net_tls" && run_net_tls ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_vuln() {
    echo ""
    echo -e "    ${WHITE}${BOLD}VULNERABILITY ASSESSMENT:${NC}"
    echo -e "    ${CYAN}[1]${NC} System CVE Vulnerability Scan"
    echo -e "    ${CYAN}[2]${NC} Web Application Security Check"
    echo -e "    ${CYAN}[3]${NC} Dependency Vulnerability Audit"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/vuln ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "vuln_system" && run_vuln_system ;;
        2) load_module "vuln_web" && run_vuln_web ;;
        3) load_module "vuln_deps" && run_vuln_deps ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_compliance() {
    echo ""
    echo -e "    ${WHITE}${BOLD}COMPLIANCE & POLICY:${NC}"
    echo -e "    ${CYAN}[1]${NC} CIS Controls Assessment"
    echo -e "    ${CYAN}[2]${NC} ISO 27001 Control Mapping"
    echo -e "    ${CYAN}[3]${NC} PCI DSS Requirement Check"
    echo -e "    ${CYAN}[4]${NC} Password Policy Audit"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/comply ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "comply_cis" && run_comply_cis ;;
        2) load_module "comply_iso27001" && run_comply_iso27001 ;;
        3) load_module "comply_pci" && run_comply_pci ;;
        4) load_module "comply_password" && run_comply_password ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_logs() {
    echo ""
    echo -e "    ${WHITE}${BOLD}LOG ANALYSIS:${NC}"
    echo -e "    ${CYAN}[1]${NC} Authentication Log Analysis"
    echo -e "    ${CYAN}[2]${NC} Syslog Anomaly Detection"
    echo -e "    ${CYAN}[3]${NC} Auditd Log Review"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/logs ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "log_auth" && run_log_auth ;;
        2) load_module "log_syslog" && run_log_syslog ;;
        3) load_module "log_audit" && run_log_audit ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_ir() {
    echo ""
    echo -e "    ${WHITE}${BOLD}INCIDENT RESPONSE:${NC}"
    echo -e "    ${CYAN}[1]${NC} System State Snapshot"
    echo -e "    ${CYAN}[2]${NC} Process Analysis & Anomaly Detection"
    echo -e "    ${CYAN}[3]${NC} Active Connection Investigation"
    echo -e "    ${CYAN}[4]${NC} Persistence Mechanism Detection"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/ir ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "ir_snapshot" && run_ir_snapshot ;;
        2) load_module "ir_processes" && run_ir_processes ;;
        3) load_module "ir_connections" && run_ir_connections ;;
        4) load_module "ir_persistence" && run_ir_persistence ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_container() {
    echo ""
    echo -e "    ${WHITE}${BOLD}CONTAINER SECURITY:${NC}"
    echo -e "    ${CYAN}[1]${NC} Docker Security Audit"
    echo -e "    ${CYAN}[2]${NC} Kubernetes Cluster Assessment"
    echo -e "    ${CYAN}[3]${NC} Container Image Scan"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/container ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "container_docker" && run_container_docker ;;
        2) load_module "container_k8s" && run_container_k8s ;;
        3) load_module "container_images" && run_container_images ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

submenu_assets() {
    echo ""
    echo -e "    ${WHITE}${BOLD}ASSET MANAGEMENT:${NC}"
    echo -e "    ${CYAN}[1]${NC} System Asset & Software Inventory"
    echo -e "    ${CYAN}[2]${NC} Port & Service Mapping"
    echo -e "    ${CYAN}[0]${NC} Back"
    echo ""
    echo -ne "    ${WHITE}kwt5h13ld/assets ➜ ${NC}"
    read -r subchoice
    case "${subchoice}" in
        1) load_module "asset_inventory" && run_asset_inventory ;;
        2) load_module "asset_ports" && run_asset_ports ;;
        0) return ;;
        *) log WARNING "Invalid selection" ;;
    esac
}

# ─── Health Check ───────────────────────────────────────────────────
run_health_check() {
    echo ""
    log INFO "Running KWT5H13LD System Health Check..."
    echo ""
    
    local tools=("nmap" "curl" "openssl" "dig" "awk" "sed" "grep" "jq" "ss" "ip" "iptables" "docker" "kubectl" "aws" "az" "gcloud" "lynis" "nikto" "trivy")
    local found=0
    local missing=0
    
    for tool in "${tools[@]}"; do
        if check_dependency "${tool}"; then
            echo -e "    ${GREEN}[✓]${NC} ${tool}"
            ((found++))
        else
            echo -e "    ${RED}[✗]${NC} ${tool} ${DIM}(not installed)${NC}"
            ((missing++))
        fi
    done
    
    echo ""
    log INFO "Dependencies: ${found} found, ${missing} missing"
    echo ""
    
    # Check modules
    local mod_count=0
    for mod_file in "${MODULES_DIR}"/*.sh; do
        [[ -f "${mod_file}" ]] && ((mod_count++))
    done
    log INFO "Modules available: ${mod_count}"
    
    # Disk space
    local disk_avail
    disk_avail="$(df -h "${SCRIPT_DIR}" | awk 'NR==2{print $4}')"
    log INFO "Disk available: ${disk_avail}"
    
    echo ""
    log SUCCESS "Health check finished."
}

# ─── Launch GUI ─────────────────────────────────────────────────────
launch_gui() {
    local gui_file="${SCRIPT_DIR}/gui/index.html"
    if [[ -f "${gui_file}" ]]; then
        log INFO "Launching KWT5H13LD Web GUI..."
        if check_dependency "python3"; then
            cd "${SCRIPT_DIR}/gui"
            log INFO "Starting local server on http://localhost:8443"
            python3 -m http.server 8443 &
            local pid=$!
            log SUCCESS "GUI server running (PID: ${pid})"
            if check_dependency "xdg-open"; then
                xdg-open "http://localhost:8443" 2>/dev/null
            elif check_dependency "open"; then
                open "http://localhost:8443" 2>/dev/null
            fi
            log INFO "Press Ctrl+C to stop the server"
            wait "${pid}"
        else
            log ERROR "Python3 required to serve GUI"
        fi
    else
        log ERROR "GUI files not found at ${gui_file}"
    fi
}

# ─── CLI Argument Parsing ──────────────────────────────────────────
parse_args() {
    OUTPUT_FILE=""
    OUTPUT_FORMAT="txt"
    TARGET=""
    VERBOSE=0
    QUIET=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)   OUTPUT_FILE="$2"; shift 2 ;;
            -f|--format)   OUTPUT_FORMAT="$2"; shift 2 ;;
            -t|--target)   TARGET="$2"; shift 2 ;;
            -v|--verbose)  VERBOSE=1; DEBUG=1; shift ;;
            -q|--quiet)    QUIET=1; shift ;;
            -h|--help)     show_banner; show_help; exit 0 ;;
            --no-color)    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; WHITE=""; GRAY=""; BOLD=""; DIM=""; NC=""; shift ;;
            # Direct module invocation
            cloud-audit)       load_module "cloud_audit" && run_cloud_audit; exit $? ;;
            cloud-iam)         load_module "cloud_iam" && run_cloud_iam; exit $? ;;
            cloud-network)     load_module "cloud_network" && run_cloud_network; exit $? ;;
            harden-linux)      load_module "harden_linux" && run_harden_linux; exit $? ;;
            harden-ssh)        load_module "harden_ssh" && run_harden_ssh; exit $? ;;
            harden-kernel)     load_module "harden_kernel" && run_harden_kernel; exit $? ;;
            harden-services)   load_module "harden_services" && run_harden_services; exit $? ;;
            net-scan)          load_module "net_scan" && run_net_scan; exit $? ;;
            net-firewall)      load_module "net_firewall" && run_net_firewall; exit $? ;;
            net-dns)           load_module "net_dns" && run_net_dns; exit $? ;;
            net-tls)           load_module "net_tls" && run_net_tls; exit $? ;;
            vuln-system)       load_module "vuln_system" && run_vuln_system; exit $? ;;
            vuln-web)          load_module "vuln_web" && run_vuln_web; exit $? ;;
            vuln-deps)         load_module "vuln_deps" && run_vuln_deps; exit $? ;;
            comply-cis)        load_module "comply_cis" && run_comply_cis; exit $? ;;
            comply-iso27001)   load_module "comply_iso27001" && run_comply_iso27001; exit $? ;;
            comply-pci)        load_module "comply_pci" && run_comply_pci; exit $? ;;
            comply-password)   load_module "comply_password" && run_comply_password; exit $? ;;
            log-auth)          load_module "log_auth" && run_log_auth; exit $? ;;
            log-syslog)        load_module "log_syslog" && run_log_syslog; exit $? ;;
            log-audit)         load_module "log_audit" && run_log_audit; exit $? ;;
            ir-snapshot)       load_module "ir_snapshot" && run_ir_snapshot; exit $? ;;
            ir-processes)      load_module "ir_processes" && run_ir_processes; exit $? ;;
            ir-connections)    load_module "ir_connections" && run_ir_connections; exit $? ;;
            ir-persistence)    load_module "ir_persistence" && run_ir_persistence; exit $? ;;
            container-docker)  load_module "container_docker" && run_container_docker; exit $? ;;
            container-k8s)     load_module "container_k8s" && run_container_k8s; exit $? ;;
            container-images)  load_module "container_images" && run_container_images; exit $? ;;
            asset-inventory)   load_module "asset_inventory" && run_asset_inventory; exit $? ;;
            asset-ports)       load_module "asset_ports" && run_asset_ports; exit $? ;;
            report)            load_module "report_gen" && run_report_gen; exit $? ;;
            gui)               launch_gui; exit $? ;;
            health)            run_health_check; exit $? ;;
            *)                 log ERROR "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
}

# ─── Main ───────────────────────────────────────────────────────────
main() {
    if [[ $# -gt 0 ]]; then
        parse_args "$@"
        return
    fi

    show_banner
    check_root
    log INFO "KWT5H13LD v${VERSION} initialized | Log: ${LOG_FILE}"
    echo ""

    while true; do
        show_menu
        read -r choice
        case "${choice}" in
            1)  submenu_cloud ;;
            2)  submenu_hardening ;;
            3)  submenu_network ;;
            4)  submenu_vuln ;;
            5)  submenu_compliance ;;
            6)  submenu_logs ;;
            7)  submenu_ir ;;
            8)  submenu_container ;;
            9)  submenu_assets ;;
            10) load_module "report_gen" && run_report_gen ;;
            11) launch_gui ;;
            12) run_health_check ;;
            0)  echo ""; log INFO "Thank you for using KWT5H13LD. Stay secure!"; echo ""; exit 0 ;;
            *)  log WARNING "Invalid selection. Please choose 0-12." ;;
        esac
    done
}

main "$@"
