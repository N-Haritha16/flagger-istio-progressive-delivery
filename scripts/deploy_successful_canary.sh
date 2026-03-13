#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=progressive-delivery

echo "Configuring canary version as healthy..."
kubectl -n ${NAMESPACE} patch configmap demo-app-canary-config \
  -p '{"data":{"mode":"stable","fault_rate":"0.0","extra_latency":"0.0"}}'

echo "Re-deploying v2 (healthy)..."
kubectl -n ${NAMESPACE} rollout restart deployment demo-app-v2

echo "Applying Flagger successful canary definition..."
kubectl apply -f k8s/flagger/canary-success.yaml

echo "Waiting for canary promotion (this may take several minutes)..."
kubectl -n ${NAMESPACE} get canary
