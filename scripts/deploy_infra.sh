#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=progressive-delivery

echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "Installing Istio (assumes istioctl in PATH)..."
istioctl install -y

echo "Labeling namespace for Istio..."
kubectl label namespace ${NAMESPACE} istio-injection=enabled --overwrite

echo "Installing Prometheus via Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace ${NAMESPACE} --create-namespace \
  -f k8s/monitoring/prometheus-values.yaml

echo "Installing Grafana via Helm..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana \
  --namespace ${NAMESPACE} --set adminPassword=admin --set service.type=LoadBalancer

echo "Installing Flagger + loadtester..."
helm repo add flagger https://flagger.app
helm repo update
helm upgrade --install flagger flagger/flagger \
  --namespace istio-system \
  --set meshProvider=istio \
  --set metricsServer=http://prometheus-server.${NAMESPACE}.svc.cluster.local
helm upgrade --install flagger-loadtester flagger/loadtester \
  --namespace ${NAMESPACE}

echo "Applying Grafana dashboard..."
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml

echo "Deploying app v1 and v2 plus service and Istio configs..."
kubectl apply -f k8s/app/deployment-v1.yaml
kubectl apply -f k8s/app/deployment-v2.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/istio/gateway.yaml
kubectl apply -f k8s/istio/virtualservice.yaml
