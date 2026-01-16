# Kubernetes OOM killer detective
k-oom() {
    local limit=${1:-10}
    echo "🔍 Finding the $limit most recent OOM-killed pods...\n"

    # Define colors once
    local -A colors=(
        [time]='\033[0;36m'       # Cyan
        [namespace]='\033[0;35m'  # Magenta  
        [pod]='\033[0;33m'        # Yellow
        [node]='\033[0;32m'       # Green
        [container]='\033[0;34m'  # Blue
        [restart]='\033[0;31m'    # Red
        [memory]='\033[0;37m'     # Light gray
        [exit]='\033[0;91m'       # Light red
        [reset]='\033[0m'
    )

    # Collect OOM data with simplified jq
    local temp_file=$(mktemp)
    kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r --arg def "unknown" '
    .items[]
    | . as $pod
    | .status.containerStatuses[]?
    | select(.lastState.terminated.reason == "OOMKilled" or .state.terminated.reason == "OOMKilled")
    | [
        (.lastState.terminated.finishedAt // .state.terminated.finishedAt // $pod.metadata.creationTimestamp),
        $pod.metadata.namespace,
        $pod.metadata.name,
        ($pod.spec.nodeName // $def),
        .name,
        .restartCount,
        (($pod.spec.containers[] | select(.name == .name) | .resources.limits.memory) // "none"),
        ((.lastState.terminated.exitCode // .state.terminated.exitCode) // $def | tostring)
    ] | @tsv
    ' | while IFS=$'\t' read -r timestamp namespace pod node container restarts memory exit_code; do
        [[ -n "$namespace" && "$namespace" != "null" ]] || continue
        
        # Format timestamp for display
        local display_time="$timestamp"
        if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                display_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%m/%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
            else
                display_time=$(date -d "$timestamp" "+%m/%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
            fi
        fi
        
        echo "$timestamp|$display_time|$namespace|$pod|$node|$container|$restarts|$memory|$exit_code" >> "$temp_file"
    done

    # Display results
    if [[ -s "$temp_file" ]]; then
        # Print colored header
        printf "${colors[time]}%-15s${colors[reset]}  " "KILLED_TIME"
        printf "${colors[namespace]}%-20s${colors[reset]}  " "NAMESPACE"
        printf "${colors[pod]}%-40s${colors[reset]}  " "POD"
        printf "${colors[node]}%-20s${colors[reset]}  " "NODE"
        printf "${colors[container]}%-20s${colors[reset]}  " "CONTAINER"
        printf "${colors[restart]}%-8s${colors[reset]}  " "RESTARTS"
        printf "${colors[memory]}%-10s${colors[reset]}  " "MEM_LIMIT"
        printf "${colors[exit]}%-4s${colors[reset]}\n" "EXIT"

        # Print data (sorted, limited)
        sort -t'|' -k1,1r "$temp_file" | head -n "$limit" | \
        while IFS='|' read -r _ display_time namespace pod node container restarts memory exit_code; do
            printf "${colors[time]}%-15s${colors[reset]}  " "$display_time"
            printf "${colors[namespace]}%-20s${colors[reset]}  " "$namespace"
            printf "${colors[pod]}%-40s${colors[reset]}  " "$pod"
            printf "${colors[node]}%-20s${colors[reset]}  " "$node"
            printf "${colors[container]}%-20s${colors[reset]}  " "$container"
            printf "${colors[restart]}%-8s${colors[reset]}  " "$restarts"
            printf "${colors[memory]}%-10s${colors[reset]}  " "$memory"
            printf "${colors[exit]}%-4s${colors[reset]}\n" "$exit_code"
        done

        local total=$(wc -l < "$temp_file")
        echo "\n📊 Showing $limit of $total total OOM-killed pods found"
        
        echo "\n💡 Quick commands:"
        echo "   kubectl describe pod <pod> -n <namespace>"
        echo "   kubectl logs <pod> -n <namespace> -c <container> --previous"
    else
        echo "✅ No OOM-killed pods found"
    fi

    rm -f "$temp_file"
}
