#!/usr/bin/env bash
run_container_docker() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  DOCKER SECURITY AUDIT (CIS DOCKER BENCHMARK)"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    if ! check_dependency "docker"; then
        log ERROR "Docker not installed or not accessible"
        return 1
    fi

    local total=0 passed=0 failed=0

    # Docker daemon config
    ((total++))
    if [[ -f /etc/docker/daemon.json ]]; then
        log SUCCESS "Docker daemon.json exists"
        ((passed++))
        
        # Check for userns-remap
        ((total++))
        if grep -q "userns-remap" /etc/docker/daemon.json 2>/dev/null; then
            log SUCCESS "  User namespace remapping enabled"
            ((passed++))
        else
            log WARNING "  User namespace remapping not configured"
            ((failed++))
        fi

        # Check for live-restore
        ((total++))
        if grep -q "live-restore" /etc/docker/daemon.json 2>/dev/null; then
            log SUCCESS "  Live restore enabled"
            ((passed++))
        else
            log WARNING "  Live restore not configured"
            ((failed++))
        fi
    else
        log WARNING "Docker daemon.json not found"
        ((failed++))
    fi

    # Containers running as root
    ((total++))
    local root_containers
    root_containers=$(docker ps -q 2>/dev/null | xargs -I{} docker inspect --format '{{.Name}} {{.Config.User}}' {} 2>/dev/null | grep -c "^/.* $\|^/.*root" || echo "0")
    if [[ ${root_containers} -eq 0 ]]; then
        log SUCCESS "No containers running as root"
        ((passed++))
    else
        log WARNING "${root_containers} containers running as root user"
        ((failed++))
    fi

    # Privileged containers
    ((total++))
    local priv_containers
    priv_containers=$(docker ps -q 2>/dev/null | xargs -I{} docker inspect --format '{{.Name}} {{.HostConfig.Privileged}}' {} 2>/dev/null | grep -c "true" || echo "0")
    if [[ ${priv_containers} -eq 0 ]]; then
        log SUCCESS "No privileged containers"
        ((passed++))
    else
        log WARNING "${priv_containers} privileged containers detected"
        ((failed++))
    fi

    # Docker socket permissions
    ((total++))
    if [[ -S /var/run/docker.sock ]]; then
        local sock_perms
        sock_perms=$(stat -c "%a" /var/run/docker.sock 2>/dev/null)
        if [[ "${sock_perms}" == "660" || "${sock_perms}" == "600" ]]; then
            log SUCCESS "Docker socket permissions: ${sock_perms}"
            ((passed++))
        else
            log WARNING "Docker socket permissions: ${sock_perms} (should be 660)"
            ((failed++))
        fi
    fi

    # Images with known vulnerabilities
    if check_dependency "trivy"; then
        log INFO "Running Trivy on running container images..."
        docker ps --format '{{.Image}}' 2>/dev/null | sort -u | while read -r img; do
            ((total++))
            local vulns
            vulns=$(trivy image --severity HIGH,CRITICAL --quiet "${img}" 2>/dev/null | grep -c "CRITICAL\|HIGH" || echo "0")
            if [[ ${vulns} -eq 0 ]]; then
                log SUCCESS "  ${img}: No HIGH/CRITICAL vulnerabilities"
                ((passed++))
            else
                log WARNING "  ${img}: ${vulns} HIGH/CRITICAL vulnerabilities"
                ((failed++))
            fi
        done
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "Docker Audit Score: ${score}% | Pass: ${passed}/${total}"
    echo ""
}
