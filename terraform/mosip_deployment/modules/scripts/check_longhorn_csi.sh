#!/bin/bash

KUBECONFIG="$1"
NAMESPACE="$2"

# Check if all required deployments are ready
DEPLOYMENTS=("csi-attacher" "csi-provisioner" "csi-resizer" "csi-snapshotter" "longhorn-driver-deployer")

for deployment in "${DEPLOYMENTS[@]}"; do
    if ! kubectl --kubeconfig="$KUBECONFIG" get deployment -n "$NAMESPACE" "$deployment" -o json | \
        jq -e '.status.readyReplicas == .status.replicas and .status.replicas > 0' >/dev/null 2>&1; then
        echo "{\"ready\": \"false\", \"message\": \"Deployment $deployment is not ready\"}"
        exit 1
    fi
done

echo '{"ready": "true", "message": "All CSI components are ready"}'
exit 0 