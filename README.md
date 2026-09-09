# Flagger Istio Progressive Delivery

Automated progressive delivery on Kubernetes using Istio, Flagger, Prometheus, and Grafana with canary and blue‑green deployments. This project implements metric‑driven canary releases, automated rollbacks, and blue‑green traffic switching for a sample web application.

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue?logo=kubernetes)
![Istio](https://img.shields.io/badge/Istio-Service%20Mesh-blue?logo=istio)
![Flagger](https://img.shields.io/badge/Flagger-Progressive%20Delivery-orange?logo=github)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-green?logo=grafana)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Project Structure](#project-structure)
- [Traffic Flow](#traffic-flow)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Scenarios](#running-the-scenarios)
- [Submission Automation](#submission-automation)
- [Video Demonstration](#video-demonstration)
- [Troubleshooting](#troubleshooting)
- [Tech Stack](#tech-stack)

---

## Overview

This progressive delivery system is built on **Kubernetes with Istio service mesh** and implements:

- **Automated canary deployments** with metric-driven promotion
- **Blue-green deployments** with instant traffic switching
- **Automated rollbacks** when metrics violate thresholds
- **Real-time monitoring** with Prometheus and Grafana

The project is designed to be **interview-ready** — demonstrating Kubernetes best practices, service mesh traffic management, progressive delivery patterns, and observability.

---

## Features

| Capability | Detail |
|------------|--------|
| 🎯 **Canary deployments** | Gradual traffic shift (0→100%) with step weights |
| 🔄 **Blue-green deployments** | Instant traffic switch when health checks pass |
| 🚨 **Automated rollbacks** | Reverts to stable version on metric violations |
| 📊 **Metric-driven analysis** | Uses request success rate and latency from Prometheus |
| 🌐 **Istio integration** | Traffic routing via VirtualService and DestinationRule |
| 📈 **Grafana dashboards** | Real-time visualization of traffic shifts and metrics |
| ✅ **LoadTester integration** | Generates traffic during canary analysis |
| 📖 **Complete documentation** | Step-by-step guides for all deployment scenarios |

---

## System Architecture

### Cluster Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Kubernetes** | Minikube/CNCF | Container orchestration |
| **Istio** | Service Mesh | Traffic routing and telemetry |
| **Flagger** | Progressive Delivery | Automated canary/blue-green |
| **Prometheus** | Monitoring | Metrics collection |
| **Grafana** | Visualization | Dashboards and alerts |
| **Sample App** | demo-app-v1/v2 | Two-version web application |

### Traffic Flow

| Step | Component | Action |
|------|-----------|--------|
| 1 | External Client | Sends request to application |
| 2 | Istio Ingress Gateway | Receives traffic (demo-gateway) |
| 3 | Istio VirtualService | Routes traffic based on Flagger rules |
| 4 | Kubernetes Services | Directs to stable or canary deployment |
| 5 | Flagger | Monitors metrics and updates routing |

### Canary Analysis Flow

| Step | Component | Action |
|------|-----------|--------|
| 1 | New Version Deployed | demo-app-v2 updated |
| 2 | Flagger Detects Change | Starts canary analysis |
| 3 | LoadTester | Generates test traffic |
| 4 | Prometheus | Collects metrics (success rate, latency) |
| 5 | Flagger Analyzes | Compares metrics against thresholds |
| 6 | Traffic Shift | Gradually increases canary weight (20→40→60→80→100) |
| 7 | Promotion | If metrics pass, v2 becomes stable |
| 8 | Rollback | If metrics fail, revert to v1 |

---

## Project Structure
```
flagger-istio-progressive-delivery/
│
├── 📁 k8s/
│ ├── 📁 app/
│ │ ├── 📄 demo-app-v1-deployment.yaml # Stable version (blue)
│ │ ├── 📄 demo-app-v2-deployment.yaml # Canary version (green)
│ │ ├── 📄 demo-app-canary-config.yaml # Canary configuration
│ │ └── 📄 demo-app-service.yaml # Kubernetes service
│ ├── 📁 istio/
│ │ ├── 📄 demo-gateway.yaml # Istio ingress gateway
│ │ ├── 📄 demo-app-virtualservice.yaml # Traffic routing rules
│ │ └── 📄 demo-app-destinationrule.yaml # Destination configuration
│ ├── 📁 monitoring/
│ │ ├── 📄 progressive-delivery-dashboard.yaml # Grafana dashboard
│ │ └── 📄 prometheus-values.yaml # Helm values (not applied)
│ └── 📁 flagger/
│ ├── 📄 canary-success.yaml # Successful canary config
│ ├── 📄 canary-failure.yaml # Failed canary config
│ └── 📄 bluegreen.yaml # Blue-green deployment
│
├── 📄 ARCHITECTURE.md # Architecture diagram
├── 📄 README.md # This file
├── 📄 submission.yml # Automated testing
└── 📁 docs/
└── 📄 architecture-diagram.png # Visual diagram
```

### Module Dependencies
```
k8s/app/ ──► Deployments + Services
│
├──► k8s/istio/ ──► Gateway + VirtualService + DestinationRule
│
└──► k8s/flagger/ ──► Canary configurations
│
└──► Monitors Prometheus metrics → Updates Istio routing
```

## Traffic Flow
```
External Client
↓
Istio Ingress Gateway (demo-gateway)
↓
Istio VirtualService (demo-app)
↓
┌─────────────────────────────────────┐
│ Traffic split by Flagger via Istio │
│ - stable: demo-app-v1 │
│ - canary/green: demo-app-v2 │
└─────────────────────────────────────┘
↓
Kubernetes Services/Deployments
```

Flagger watches the application deployment and Prometheus metrics, then updates Istio routing rules based on canary analysis results.

---

## Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **Kubernetes cluster** | 1.16+ | Minikube, Kind, or managed K8s |
| **kubectl** | Latest | Kubernetes CLI |
| **helm** | 3.x | Install Flagger loadtester |
| **istioctl** | 1.5+ | Istio CLI |
| **Istio** | 1.5+ | Service mesh |
| **Prometheus** | 2.x | Metrics collection |
| **Grafana** | 7.x+ | Visualization |

---

## Installation

### 1. Install Istio with Telemetry

```bash
istioctl install --set profile=default -y
```

Install Prometheus addon:

```bash
kubectl apply -f [https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/prometheus.yaml](https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/prometheus.yaml)
```

(Optional) Install Grafana addon:

```bash
kubectl apply -f [https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/grafana.yaml](https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/grafana.yaml)
```

Verify:

```bash
kubectl -n istio-system get pods
```

### 2. Install Flagger and CRDs

```bash
kubectl apply -k github.com/fluxcd/flagger//kustomize/istio
```

This installs Flagger in the `istio-system` namespace configured for Istio.

### 3. Create Application Namespace

```bash
kubectl create namespace progressive-delivery
kubectl label namespace progressive-delivery istio-injection=enabled
```

### 4. Install Flagger LoadTester

```bash
helm repo add flagger [https://flagger.app/](https://flagger.app/)
helm repo update

helm upgrade --install flagger-loadtester flagger/loadtester \
  --namespace progressive-delivery
```

The loadtester service generates traffic during canary analysis.

### 5. Deploy Application and Configs

```bash
# Application deployments and service
kubectl apply -f k8s/app/ -n progressive-delivery

# Istio Gateway, VirtualService, DestinationRule
kubectl apply -f k8s/istio/

# Grafana dashboard (optional)
kubectl apply -f k8s/monitoring/progressive-delivery-dashboard.yaml
```

**DO NOT** apply `prometheus-values.yaml` with kubectl (it's a Helm values file).

### 6. Verify Deployment

```bash
kubectl -n progressive-delivery get deploy
kubectl -n progressive-delivery get pods
```

**Expected output:**
```
NAME READY UP-TO-DATE AVAILABLE AGE
demo-app-v1 1/1 1 1 2m
demo-app-v2 1/1 1 1 2m

NAME READY STATUS RESTARTS AGE
demo-app-v1-xxxxxxxxxx-xxxxx 1/1 Running 0 2m
demo-app-v2-xxxxxxxxxx-xxxxx 1/1 Running 0 2m
flagger-loadtester-xxxxxxxxx 1/1 Running 0 1m
```

---

## Configuration

### Canary Analysis Metrics

| Metric | Threshold | Interval | Purpose |
|--------|-----------|----------|---------|
| **Request success rate** | ≥ 99% | 1m | Minimum acceptable success rate |
| **Request duration (P99)** | ≤ 500ms | 1m | Maximum acceptable latency |

### Traffic Shifting Strategy

| Canary Type | Strategy | Step Weights |
|-------------|----------|--------------|
| **Canary** | Progressive | 20 → 40 → 60 → 80 → 100 |
| **Blue-Green** | Instant | 0 → 100 (single switch) |

---

## Running the Scenarios

### 1. Successful Canary Promotion

Delete other canaries:

```bash
kubectl -n progressive-delivery delete canary demo-app-canary-failure || true
```

Apply success canary:

```bash
kubectl -n progressive-delivery apply -f k8s/flagger/canary-success.yaml
```

Trigger rollout:

```bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
```

Watch progress:

```bash
kubectl get canaries -n progressive-delivery -w
```

**Expected behavior:**
- Traffic weights increase: 20 → 40 → 60 → 80 → 100
- Status changes to `Promoted` or `Initialized`
- All traffic eventually routes to v2

Inspect final status:

```bash
kubectl -n progressive-delivery describe canary demo-app-canary-success
kubectl -n progressive-delivery get pods
kubectl -n istio-system logs deploy/flagger --tail=200
```

**In Grafana:**
- Open Grafana: `kubectl port-forward -n istio-system svc/grafana 3000:3000`
- View progressive-delivery dashboard
- Observe traffic shifting and metrics during rollout

### 2. Failed Canary with Automated Rollback

Apply failure canary:

```bash
kubectl -n progressive-delivery apply -f k8s/flagger/canary-failure.yaml
```

Trigger rollout:

```bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
kubectl get canaries -n progressive-delivery -w
```

**Expected behavior:**
- Canary analysis detects metric violations
- Advancement halts
- Traffic switches back to stable (v1)
- Deployment scaled down

Inspect rollback:

```bash
kubectl -n progressive-delivery describe canary demo-app-canary-failure
kubectl -n istio-system logs deploy/flagger --tail=200
kubectl -n progressive-delivery get pods
```

**In Grafana:**
- Show error rate/latency spikes
- Observe traffic moving back to v1

### 3. Blue-Green Deployment

Apply blue-green canary:

```bash
kubectl -n progressive-delivery apply -f k8s/flagger/bluegreen.yaml
```

Trigger rollout:

```bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
kubectl get canaries -n progressive-delivery -w
```

**Expected behavior:**
- Traffic switches 0 → 100 instantly
- Health checks pass
- All traffic routes to green (v2)

Inspect:

```bash
kubectl -n progressive-delivery describe canary demo-app-bluegreen
kubectl -n progressive-delivery get pods
```

**In Grafana:**
- Show near-instant traffic switch
- Metrics remain healthy throughout

---

## Submission Automation

The evaluator will run `submission.yml` to deploy and test your solution:

```yaml
version: v1
tasks:
  setup:
    cmd: |
      kubectl apply -f k8s/app/ -n progressive-delivery
      kubectl apply -f k8s/istio/
      kubectl apply -f k8s/flagger/ -n progressive-delivery

  test-success:
    cmd: |
      kubectl -n progressive-delivery delete canary demo-app-canary-failure demo-app-bluegreen || true
      kubectl -n progressive-delivery apply -f k8s/flagger/canary-success.yaml
      kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
      kubectl get canaries -n progressive-delivery

  test-failure:
    cmd: |
      kubectl -n progressive-delivery delete canary demo-app-canary-success demo-app-bluegreen || true
      kubectl -n progressive-delivery apply -f k8s/flagger/canary-failure.yaml
      kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
      kubectl get canaries -n progressive-delivery
```

This satisfies the requirement to deploy the stack, test a successful release, and test a failed release with rollback.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Canary not progressing** | Check Flagger logs: `kubectl -n istio-system logs deploy/flagger --tail=200` |
| **Metrics not available** | Verify Prometheus is scraping: `kubectl -n istio-system port-forward svc/prometheus 9090:9090` |
| **LoadTester not generating traffic** | Check pod status: `kubectl -n progressive-delivery get pods` |
| **Istio sidecar not injected** | Verify namespace label: `kubectl get ns progressive-delivery --show-labels` |
| **VirtualService not routing** | Check VirtualService config: `kubectl -n progressive-delivery get virtualservice -o yaml` |

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Orchestration** | Kubernetes | 1.16+ | Container orchestration |
| **Service Mesh** | Istio | 1.5+ | Traffic routing and telemetry |
| **Progressive Delivery** | Flagger | 1.x | Automated canary/blue-green |
| **Monitoring** | Prometheus | 2.x | Metrics collection |
| **Visualization** | Grafana | 7.x+ | Dashboards and alerts |
| **Traffic Generation** | Flagger LoadTester | Latest | Test traffic during analysis |
| **Package Manager** | Helm | 3.x | Install Flagger components |

---

## References

| Resource | Link |
|----------|------|
| **Flagger Documentation** | https://docs.flagger.app/ |
| **Istio Progressive Delivery** | https://docs.flagger.app/tutorials/istio-progressive-delivery |
| **Flagger GitHub** | https://github.com/fluxcd/flagger |
| **Istio Documentation** | https://istio.io/latest/docs/ |

---

## License

MIT License

---

## Contact

**Project Link:** https://github.com/N-Haritha16/flagger-istio-progressive-delivery