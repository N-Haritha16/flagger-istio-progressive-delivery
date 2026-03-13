## Flagger Istio Progressive Delivery

Automated progressive delivery on Kubernetes using Istio, Flagger, Prometheus, and Grafana with canary and blue‑green deployments. This project implements metric‑driven canary releases, automated rollbacks, and blue‑green traffic switching for a sample web application.
​

1. Architecture overview
The system consists of:

A Kubernetes cluster (Minikube or any CNCF‑compatible cluster).

Istio service mesh for traffic routing and telemetry.

Flagger operator for progressive delivery automation (canary, rollback, blue‑green).

Prometheus for metrics collection.

Grafana for visualization.

A sample web application with two versions:

demo-app-v1 (stable / blue).

demo-app-v2 (canary / green).
​

2. Traffic flow:

External client → Istio Ingress Gateway (demo-gateway).

Gateway → Istio VirtualService (demo-app).

VirtualService routes traffic between Kubernetes Services/Deployments:

stable deployment (demo-app-v1),

canary/green deployments (demo-app-v2, demo-app-v2-primary depending on strategy).

Flagger watches the application deployment and metrics in Prometheus and updates Istio routing rules based on canary analysis.
​

See ARCHITECTURE.md for a diagram and detailed component interactions.
​

##  Repository structure
text
.
├─ k8s/
│  ├─ app/
│  │  ├─ demo-app-v1-deployment.yaml
│  │  ├─ demo-app-v2-deployment.yaml
│  │  ├─ demo-app-canary-config.yaml
│  │  └─ demo-app-service.yaml
│  ├─ istio/
│  │  ├─ demo-gateway.yaml
│  │  ├─ demo-app-virtualservice.yaml
│  │  └─ demo-app-destinationrule.yaml
│  ├─ monitoring/
│  │  ├─ progressive-delivery-dashboard.yaml
│  │  └─ prometheus-values.yaml   # Helm values only (not applied with kubectl)
│  └─ flagger/
│     ├─ canary-success.yaml
│     ├─ canary-failure.yaml
│     └─ bluegreen.yaml
├─ ARCHITECTURE.md
├─ README.md
├─ submission.yml
└─ docs/
   └─ architecture-diagram.png (optional)
Adjust file names to match your actual manifests. The important part is that app, Istio, monitoring, and Flagger configs are logically separated.
​

## Prerequisites
Kubernetes cluster (Minikube, Kind, or managed K8s).

kubectl configured to talk to the cluster.

helm for installing Flagger loadtester and optionally Prometheus/Grafana.

Istio CLI (istioctl).

## Installation steps
4.1 Install Istio with telemetry
Follow the official Istio install (profile default with Prometheus addon). Example:

bash
istioctl install --set profile=default -y

## Install Prometheus addon if not included
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/prometheus.yaml

## (Optional) Install Grafana addon
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/grafana.yaml
Make sure Prometheus and Grafana pods are running in the istio-system namespace.

##  Install Flagger and CRDs
bash
1. Install Flagger CRDs and controller for Istio
kubectl apply -k github.com/fluxcd/flagger//kustomize/istio
This installs Flagger in the istio-system namespace configured for Istio.

-  Create application namespace and label for Istio
bash
kubectl create namespace progressive-delivery
kubectl label namespace progressive-delivery istio-injection=enabled

- Install Flagger loadtester (Helm)
bash
helm repo add flagger https://flagger.app
helm repo update

helm upgrade --install flagger-loadtester flagger/loadtester \
  --namespace progressive-delivery
The loadtester service is used by Flagger webhooks to generate traffic during analysis.

##  Deploy application, Istio config, and monitoring
From the repo root:

bash
## Application deployments and service
kubectl apply -f k8s/app/ -n progressive-delivery

## Istio Gateway, VirtualService, DestinationRule
kubectl apply -f k8s/istio/

## Grafana dashboard for progressive delivery (optional)
kubectl apply -f k8s/monitoring/progressive-delivery-dashboard.yaml

## DO NOT kubectl apply prometheus-values.yaml (it is a Helm values file)
Verify:

bash
kubectl -n progressive-delivery get deploy
kubectl -n progressive-delivery get pods
You should see:

demo-app-v1 and demo-app-v2 deployments.

Pods for v1 and v2 in Running state.

flagger-loadtester running.

##  Flagger canary configurations
6.1 Successful canary
k8s/flagger/canary-success.yaml defines a Flagger Canary resource that:

Targets demo-app-v2 deployment.

Uses Prometheus metrics:

request success rate.

request duration (latency).

Gradually shifts traffic from 0 → 100% with step weights (for example 20, 40, 60, 80, 100).

Uses a loadtester webhook to generate traffic.
​

## Apply:

bash
kubectl apply -f k8s/flagger/canary-success.yaml -n progressive-delivery
kubectl get canaries -n progressive-delivery
6.2 Failed canary
k8s/flagger/canary-failure.yaml defines a stricter canary analysis or a faulty app version (high latency, error rate) to intentionally violate thresholds and trigger rollback.
​

## Apply when testing failure:

bash
kubectl apply -f k8s/flagger/canary-failure.yaml -n progressive-delivery
6.3 Blue‑green deployment
k8s/flagger/bluegreen.yaml defines a Flagger Canary using a blue‑green strategy: traffic switches 0 → 100% when health checks pass.
​
​

## Apply:

bash
kubectl apply -f k8s/flagger/bluegreen.yaml -n progressive-delivery
## Running the scenarios
1.  Successful canary promotion
Ensure only the success canary is active for demo-app-v2 (delete failure canary if needed):

bash
kubectl -n progressive-delivery delete canary demo-app-canary-failure || true
Trigger a new version rollout:

bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
Watch the canary progress:

bash
kubectl get canaries -n progressive-delivery -w
You should see demo-app-canary-success weights increasing until 100 and status moving to Promoted/Initialized.

Inspect final status:

bash
kubectl -n progressive-delivery describe canary demo-app-canary-success
kubectl -n progressive-delivery get pods
kubectl -n istio-system logs deploy/flagger --tail=200
In Grafana:

Open Grafana (e.g., kubectl port-forward -n istio-system svc/grafana 3000:3000).

Import/use the progressive-delivery dashboard.

Observe traffic shifting and metrics during the canary.
​

2.  Failed canary with automated rollback
Ensure the failure canary is applied:

bash
kubectl apply -f k8s/flagger/canary-failure.yaml -n progressive-delivery
Trigger rollout:

bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
kubectl get canaries -n progressive-delivery -w
After it fails:

bash
kubectl -n progressive-delivery describe canary demo-app-canary-failure
kubectl -n istio-system logs deploy/flagger --tail=200
kubectl -n progressive-delivery get pods
You should see messages indicating halted advancement, failed checks, and rollback (deployment scaled down / traffic switched back to stable).
​

Grafana:

Show error rate/latency spikes and traffic being moved back to v1.
​

3. Blue‑green deployment
Ensure the blue‑green canary is applied:

bash
kubectl apply -f k8s/flagger/bluegreen.yaml -n progressive-delivery
Trigger rollout:

bash
kubectl -n progressive-delivery rollout restart deploy/demo-app-v2
kubectl get canaries -n progressive-delivery -w
Inspect:

bash
kubectl -n progressive-delivery describe canary demo-app-bluegreen
kubectl -n progressive-delivery get pods
Grafana:

Show the traffic switching almost instantly from blue to green, with metrics remaining healthy.
​
​

## Submission automation (submission.yml)
The evaluator will run submission.yml to deploy and test your solution. Example:
​

text
version: v1
tasks:
  setup:
    cmd: |
      # assumes Istio, Prometheus, Grafana, Flagger are installed per README
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
This satisfies the PDF’s requirement that your submission defines commands to deploy the stack, test a successful release, and test a failed release triggering rollback.
​

## Video demonstration checklist
Your 5–10 minute video should show:
​

Brief architecture overview (use ARCHITECTURE.md diagram).

Successful canary:

kubectl get canaries -n progressive-delivery -w.

kubectl describe canary demo-app-canary-success.

Grafana dashboard during the rollout.

Failed canary with rollback:

kubectl describe canary demo-app-canary-failure.

Flagger logs showing rollback.

Grafana showing degraded metrics and traffic moving back.

Blue‑green deployment:

kubectl describe canary demo-app-bluegreen.

Grafana showing near‑instant traffic switch.