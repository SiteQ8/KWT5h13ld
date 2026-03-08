#!/usr/bin/env bash
run_container_images() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  CONTAINER IMAGE VULNERABILITY & CONFIG SCAN"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    if ! check_dependency "docker"; then
        log ERROR "Docker not available"
        return 1
    fi

    local total=0 passed=0 failed=0

    # List images
    log INFO "Container images on system:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null | while read -r line; do
        echo -e "    ${line}"
    done

    # Check for latest tag
    ((total++))
    local latest_count
    latest_count=$(docker images --format '{{.Tag}}' 2>/dev/null | grep -c "^latest$" || echo "0")
    if [[ ${latest_count} -eq 0 ]]; then
        log SUCCESS "No images using 'latest' tag"
        ((passed++))
    else
        log WARNING "${latest_count} images use 'latest' tag — use specific versions"
        ((failed++))
    fi

    # Dangling images
    ((total++))
    local dangling
    dangling=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    if [[ ${dangling} -eq 0 ]]; then
        log SUCCESS "No dangling images"
        ((passed++))
    else
        log WARNING "${dangling} dangling images — run docker image prune"
        ((failed++))
    fi

    # Image vulnerability scanning with Trivy
    if check_dependency "trivy"; then
        log INFO ""
        log INFO "Scanning images with Trivy..."
        docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v "<none>" | head -10 | while read -r img; do
            ((total++))
            log INFO "  Scanning ${img}..."
            trivy image --severity HIGH,CRITICAL --quiet "${img}" 2>/dev/null | tail -5 | while read -r line; do echo -e "    ${line}"; done
        done
    else
        log INFO "Install Trivy for image vulnerability scanning"
    fi

    echo ""
    log INFO "Image scan finished. Pass: ${passed} | Fail: ${failed}"
    echo ""
}
