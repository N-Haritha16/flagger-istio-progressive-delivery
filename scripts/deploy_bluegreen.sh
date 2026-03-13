#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=progressive-delivery

echo "Ensuring v1 is treated as blue and v2 as green..."
kubectl -n ${NAMESPACE} patch deployment demo-app-v1 \
  -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1"}}}}}'
kubectl -n ${NAMESPACE} patch deployment demo-app-v2 \
  -p '{"spec":{"template":{"metadata":{"labels":{"version":"v2"}}}}}'

echo "Configuring green as healthy stable mode..."
kubectl -n ${NAMESPACE} patch configmap demo-app-canary-config \
  -p '{"data":{"mode":"stable","fault_rate":"0.0","extra_latency":"0.0"}}'
kubectl -n ${NAMESPACE} rollout restart deployment demo-app-v2

echo "Applying BlueGreen Flagger config..."
kubectl apply -f k8s/flagger/bluegreen.yaml

echo "Check BlueGreen status..."
kubectl -n ${NAMESPACE} get canary demo-app-bluegreen
