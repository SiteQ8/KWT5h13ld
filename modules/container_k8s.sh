#!/usr/bin/env bash
run_container_k8s() {
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  KUBERNETES CLUSTER SECURITY ASSESSMENT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    if ! check_dependency "kubectl"; then
        log ERROR "kubectl not installed or cluster not accessible"
        return 1
    fi

    local total=0 passed=0 failed=0

    # Cluster info
    log INFO "Cluster info:"
    kubectl cluster-info 2>/dev/null | head -5 | while read -r line; do echo -e "    ${line}"; done

    # Pods running as root
    ((total++))
    local root_pods
    root_pods=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}: {.spec.securityContext.runAsNonRoot}{"\n"}{end}' 2>/dev/null | grep -c "false\|:$" || echo "0")
    if [[ ${root_pods} -eq 0 ]]; then
        log SUCCESS "No pods running as root"
        ((passed++))
    else
        log WARNING "${root_pods} pods may run as root"
        ((failed++))
    fi

    # Privileged pods
    ((total++))
    local priv_pods
    priv_pods=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.securityContext.privileged}{"\n"}{end}{end}' 2>/dev/null | grep -c "true" || echo "0")
    if [[ ${priv_pods} -eq 0 ]]; then
        log SUCCESS "No privileged pods"
        ((passed++))
    else
        log WARNING "${priv_pods} privileged containers found"
        ((failed++))
    fi

    # Network policies
    ((total++))
    local netpol_count
    netpol_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)
    if [[ ${netpol_count} -gt 0 ]]; then
        log SUCCESS "Network policies configured: ${netpol_count}"
        ((passed++))
    else
        log WARNING "No network policies — all pod traffic is unrestricted"
        ((failed++))
    fi

    # RBAC check
    ((total++))
    local cluster_admin_bindings
    cluster_admin_bindings=$(kubectl get clusterrolebindings -o jsonpath='{range .items[?(@.roleRef.name=="cluster-admin")]}{.subjects[*].name}{"\n"}{end}' 2>/dev/null | wc -l)
    log INFO "cluster-admin bindings: ${cluster_admin_bindings}"
    if [[ ${cluster_admin_bindings} -le 3 ]]; then
        log SUCCESS "cluster-admin bindings within acceptable range"
        ((passed++))
    else
        log WARNING "Too many cluster-admin bindings (${cluster_admin_bindings})"
        ((failed++))
    fi

    echo ""
    local score=0; [[ ${total} -gt 0 ]] && score=$(( (passed * 100) / total ))
    log INFO "K8s Security Score: ${score}% | Pass: ${passed}/${total}"
    echo ""
}
