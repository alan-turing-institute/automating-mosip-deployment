#!/bin/bash

KUBECONFIG="$1"

if ! command -v kubectl &> /dev/null; then
  echo '{"ready": "false", "message": "kubectl is not installed"}'
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo '{"ready": "false", "message": "jq is not installed"}'
  exit 1
fi

if ! kubectl --kubeconfig="$KUBECONFIG" cluster-info &> /dev/null; then
  echo '{"ready": "false", "message": "kubectl cannot connect to cluster"}'
  exit 1
fi

echo '{"ready": "true", "message": "All prerequisites checks passed successfully"}'
exit 0 