#!/bin/bash

KUBECONFIG="$1"

if kubectl --kubeconfig="$KUBECONFIG" get sc longhorn -o json | jq -e '.provisioner == "driver.longhorn.io"' >/dev/null 2>&1; then
    echo '{"ready": "true", "message": "Longhorn storage class is properly configured"}'
    exit 0
else
    echo '{"ready": "false", "message": "Longhorn storage class is not properly configured"}'
    exit 1
fi 