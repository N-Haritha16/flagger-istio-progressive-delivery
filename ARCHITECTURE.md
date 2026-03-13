## Architecture: Flagger + Istio Progressive Delivery
This document describes the architecture of the progressive delivery system implemented in this repository using Kubernetes, Istio, Flagger, Prometheus, and Grafana.
​

1. High-level overview
The goal is to automate safe application rollouts using canary and blue‑green deployment strategies. The system:

Routes traffic through Istio (service mesh and ingress).

Uses Flagger to orchestrate canary and blue‑green rollouts.

Relies on Prometheus metrics for analysis.

Visualizes behavior in Grafana.

Manages all infrastructure and app configuration as code in this GitHub repository.
​

At a high level, the request flow is:

Client → Istio Ingress Gateway.

Gateway → Istio VirtualService (demo-app).

VirtualService → Kubernetes Service (demo-app).

Service → Deployments:

demo-app-v1 (stable / blue).

demo-app-v2 (canary / green) and/or demo-app-v2-primary depending on the strategy.

Flagger monitors traffic and metrics and updates Istio routing rules.

2. Components
2.1 Kubernetes cluster
Runs all workloads:

Sample application Pods (v1, v2, v2-primary).

Istio control plane and sidecars.

Flagger controller.

Prometheus and Grafana.
​
​

Namespace progressive-delivery is used for the demo app and Flagger loadtester.

Namespace istio-system hosts Istio, Prometheus, Grafana, and Flagger.

2.2 Sample application
Two main versions:

demo-app-v1 Deployment: stable version receiving 100% of traffic initially.

demo-app-v2 Deployment: candidate version used for canary and blue‑green tests.

Optional demo-app-v2-primary Deployment:

Used by Flagger during blue‑green scenarios to act as the “green” target.

demo-app Service:

Stable service name that VirtualService targets.

Points to Pods labeled app=demo-app (v1/v2) depending on routing.
​
​

Configuration stored in ConfigMap demo-app-canary-config to control fault rate and latency for failure scenarios.

2.3 Istio
Gateway (demo-gateway):

Exposes the demo-app VirtualService outside the cluster.

Terminates external traffic and forwards it into the mesh.

VirtualService (demo-app):

Defines host and route rules.

Routes HTTP traffic to the demo-app Service.

Flagger updates this resource during canary and blue‑green rollouts to change traffic weights between v1/v2.

DestinationRule (demo-app):

Groups versions of the service into subsets (e.g., v1, v2).

Flagger references these subsets when adjusting traffic splits.
​

Istio also generates telemetry (metrics) consumed by Prometheus (e.g., request success rate, latency).

2.4 Flagger
Runs as a controller in the istio-system namespace.

## Watches:

Canary custom resources (in progressive-delivery).

Corresponding Deployments, VirtualService, and DestinationRule.

Metrics in Prometheus.

Key responsibilities:

## Canary analysis:

Gradually shifts traffic from v1 to v2 according to stepWeight and maxWeight.

Queries Prometheus for:

Request success rate.

Request duration (latency).

Decides whether to promote or roll back based on thresholds.
​

## Automated rollback:

If metrics violate thresholds or the new version is not ready, Flagger:

Halts escalation.

Scales down the canary.

Restores traffic to the stable version (v1).

This happens without manual intervention.
​

## Blue‑green switching:

For blue‑green, Flagger switches traffic from blue to green in a single step once health checks pass.
​

Uses Flagger Loadtester (installed via Helm) to generate synthetic traffic during analysis using hey (configured via webhooks).

2.5 Monitoring: Prometheus and Grafana
Prometheus:

Scrapes Istio metrics (success rate, latency) and Flagger metrics.

Flagger uses Prometheus queries to evaluate the health of the canary.

Grafana:

Connects to Prometheus and visualizes:

Traffic percentage per version.

Error rates and latencies.

Flagger status/metrics over time.

progressive-delivery-dashboard.yaml provides a prebuilt dashboard tailored to this scenario.
​

3. Flagger CRDs and deployment strategies
3.1 Canary (success path)
k8s/flagger/canary-success.yaml defines:

spec.targetRef → demo-app-v2 Deployment.

spec.service → demo-app Service with demo-gateway and wildcard host.

spec.analysis parameters:

interval: how often analysis runs (e.g., 30s).

maxWeight: final canary weight (100%).

stepWeight: increment per step (e.g., 20%).

threshold: number of failed checks before rollback.

## metrics:

request-success-rate with a min threshold.

request-duration with a max threshold.

webhooks: load test commands run against the app to generate traffic.

## Flow:

Flagger detects a new demo-app-v2 revision.

Starts canary analysis and shifts traffic in steps.

If metrics stay within thresholds, Flagger promotes v2 to 100% and marks the canary as successful.

If metrics fail, Flagger rolls back to v1.
​

3.2 Canary (failure/rollback path)
k8s/flagger/canary-failure.yaml is similar but configured to intentionally fail:

Stricter thresholds (e.g., success rate ≥ 99%, latency ≤ 500 ms).

Or a faulty configuration (higher FAULT_RATE or EXTRA_LATENCY).

When triggered, the canary quickly violates these metrics and Flagger rolls back.
​

## Flow:

New revision is rolled out.

Flagger runs load tests and measures metrics.

Threshold violations occur; Flagger halts advancement.

Flagger scales down the canary and restores 100% traffic to v1.
​

This demonstrates automated rollback as required by the assignment.
​

3.3 Blue‑green strategy
k8s/flagger/bluegreen.yaml uses Flagger’s blue‑green semantics:

Flagger prepares a “green” version (e.g., demo-app-v2-primary subset).

Once health checks pass, it switches traffic from blue (v1) to green (v2) in a single step (0 → 100%).
​
​
## Flow:

Flagger detects a new green version.

Runs health checks and optional test traffic.

If healthy, Flagger updates routing so all traffic goes to green.

Optionally, blue remains running for fast rollback or is scaled down.
​
​

4. Deployment and test flows
4.1 Successful canary flow
demo-app-v1 runs and serves 100% of traffic.

A new version demo-app-v2 is rolled out (e.g., via kubectl rollout restart).

Flagger starts canary analysis:

shifts traffic v1→v2 incrementally.

runs Prometheus checks at each step.

If all checks pass, v2 becomes the new stable version with 100% traffic.

4.2 Failed canary flow
A faulty version or strict thresholds are deployed via canary-failure.yaml.

Flagger starts analysis and quickly observes:

low success rate,

high latency,

or no traffic.

Once the failure threshold is reached, Flagger scales down the canary and restores traffic to the previous stable version automatically.
​

4.3 Blue‑green flow
Blue (current production) version is serving 100% of traffic.

Green (new) version is deployed alongside blue.

Flagger verifies green’s health.

On success, Flagger switches routing so that 100% of traffic goes to green immediately.
​
​

5. Files mapping
Application: k8s/app/*.yaml

Istio: k8s/istio/*.yaml

Monitoring: k8s/monitoring/progressive-delivery-dashboard.yaml

Flagger canaries:

k8s/flagger/canary-success.yaml

k8s/flagger/canary-failure.yaml

k8s/flagger/bluegreen.yaml

Submission automation: submission.yml

Diagram: docs/architecture-diagram.png (referenced by this document).
​

This architecture satisfies the assignment’s requirements for canary, automated rollback, blue‑green deployment, observability, and Infrastructure as Code.