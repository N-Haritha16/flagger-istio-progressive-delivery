#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=progressive-delivery

echo "Configuring canary version as faulty..."
kubectl -n ${NAMESPACE} patch configmap demo-app-canary-config \
  -p '{"data":{"mode":"faulty","fault_rate":"0.6","extra_latency":"0.8"}}'

echo "Re-deploying v2 (faulty)..."
kubectl -n ${NAMESPACE} rollout restart deployment demo-app-v2

echo "Applying Flagger failing canary definition..."
kubectl apply -f k8s/flagger/canary-failure.yaml

echo "Waiting for rollback (this may take several minutes)..."
kubectl -n ${NAMESPACE} get canary
