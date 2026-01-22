#!/bin/bash

# This script fetches logs from all pods in a specified Kubernetes namespace,
# filtering for a user-defined search term and optionally for a time duration.

# Check if required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <kubeconfig_path> <namespace_or_ALL> <search_term> [last_N_hours]"
  echo "Example: $0 /home/ubuntu/rancher/turing1/kube_config_cluster.yml regproc ERROR"
  echo "Example: $0 /home/ubuntu/rancher/turing1/kube_config_cluster.yml ALL warning 24"
  echo "  <kubeconfig_path>  : Path to the kubeconfig file (mandatory)."
  echo "  <namespace_or_ALL> : The Kubernetes namespace to check, or 'ALL' for all namespaces."
  echo "  <search_term>      : The term to filter logs by (case-insensitive)."
  echo "  [last_N_hours]     : (Optional) View logs from the last N hours. If omitted, all available logs are checked."
  exit 1
fi

KUBECONFIG_PATH="$1"
NAMESPACE_OR_ALL="$2"
SEARCH_TERM="$3" # The third argument is now the search term
LAST_N_HOURS="$4" # The fourth argument is the optional number of hours

# Validate that kubeconfig file exists
if [ ! -f "$KUBECONFIG_PATH" ]; then
  echo "Error: Kubeconfig file not found: $KUBECONFIG_PATH"
  exit 1
fi

# Initialize the --since argument for kubectl logs
SINCE_ARG=""
if [ -n "$LAST_N_HOURS" ]; then
  # Validate that LAST_N_HOURS is a positive integer
  if ! [[ "$LAST_N_HOURS" =~ ^[0-9]+$ ]] || [ "$LAST_N_HOURS" -le 0 ]; then
    echo "Error: 'last_N_hours' must be a positive integer."
    exit 1
  fi
  SINCE_ARG="--since=${LAST_N_HOURS}h"
  echo "Viewing logs from the last $LAST_N_HOURS hours."
else
  echo "Viewing all available logs."
fi

echo "Filtering for term: '$SEARCH_TERM' (case-insensitive)"
echo "----------------------------------------------------"

# Determine how to get pods based on NAMESPACE_OR_ALL
if [ "$NAMESPACE_OR_ALL" == "ALL" ]; then
  echo "Fetching logs for all pods across ALL namespaces."
  # When using --all-namespaces, we need to get both namespace and pod name
  # to correctly target logs for each pod.
  PODS_INFO=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers)
  if [ -z "$PODS_INFO" ]; then
    echo "No pods found across all namespaces."
    exit 0
  fi
else
  NAMESPACE="$NAMESPACE_OR_ALL"
  echo "Fetching logs for all pods in namespace: $NAMESPACE."
  # For a single namespace, we only need the pod name
  PODS_INFO=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name --no-headers)
  if [ -z "$PODS_INFO" ]; then
    echo "No pods found in namespace '$NAMESPACE'."
    exit 0
  fi
fi

# Loop through each pod and fetch its logs, filtering for the specified search term and time
# Read each line from PODS_INFO
echo "$PODS_INFO" | while read -r line; do
  if [ "$NAMESPACE_OR_ALL" == "ALL" ]; then
    # For --all-namespaces, split the line into namespace and pod name
    CURRENT_NAMESPACE=$(echo "$line" | awk '{print $1}')
    POD_NAME=$(echo "$line" | awk '{print $2}')
    echo ""
    echo "--- Pod: $CURRENT_NAMESPACE/$POD_NAME ---"
    # Use 'kubectl logs' with both namespace and pod name
    kubectl --kubeconfig="$KUBECONFIG_PATH" logs -n "$CURRENT_NAMESPACE" "$POD_NAME" $SINCE_ARG 2>/dev/null | grep -i "$SEARCH_TERM" || true
  else
    # For a single namespace, the line is just the pod name
    POD_NAME="$line"
    echo ""
    echo "--- Pod: $NAMESPACE/$POD_NAME ---"
    # Use 'kubectl logs' with the predefined namespace and pod name
    kubectl --kubeconfig="$KUBECONFIG_PATH" logs -n "$NAMESPACE" "$POD_NAME" $SINCE_ARG 2>/dev/null | grep -i "$SEARCH_TERM" || true
  fi
done

echo "----------------------------------------------------"
echo "Finished checking logs."