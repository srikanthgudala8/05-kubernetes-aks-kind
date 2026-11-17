> **Phase 5 of the 60-day journey** (Days 39-49). Day-by-day plan: **[LEARNING.md](LEARNING.md)**.
> Extra material: `labs/broken/` (troubleshooting drills), `labs/examples/`, `aks/` (Azure Kubernetes Service).

# Kubernetes App Deployment (kind + Kustomize + Helm)

Deploys a containerised Flask service to Kubernetes the way you would in production:
probes, resource limits, autoscaling, disruption budgets, hardened pods and
network policy. Provided twice, as plain manifests (Kustomize) and as a Helm chart.

```
 Browser ─► ingress-nginx ─► Service (ClusterIP) ─► Pods (2–6, HPA)
                                                      ├─ startup/liveness/readiness probes
                                                      ├─ non-root, read-only FS, no capabilities
                                                      └─ spread across nodes
```

## What it demonstrates

| Concern | Where |
|---------|-------|
| Zero-downtime rollouts | `maxUnavailable: 0`, readiness probe (`k8s/deployment.yaml`) |
| Self-healing | liveness + startup probes |
| Autoscaling | HPA on CPU (`k8s/hpa.yaml`); needs metrics-server |
| Availability during node drains | PodDisruptionBudget, topology spread |
| Pod hardening | `restricted` Pod Security level, non-root, read-only root FS, dropped capabilities |
| Network security | default-deny ingress NetworkPolicy, allow only the ingress controller |
| Config | ConfigMap via `envFrom` |
| Packaging | Helm chart with values, helpers, optional HPA/Ingress |
| Validation | CI runs `helm lint`, `helm template`, and `kubeconform` |

## Run it locally

Prerequisites: Docker, [kind](https://kind.sigs.k8s.io), kubectl, and optionally Helm.

```bash
make cluster      # 3-node cluster
make ingress      # ingress-nginx + metrics-server
make deploy       # plain manifests
make test         # curl http://demo.localtest.me/health  (resolves to 127.0.0.1)
make status
```

Or with Helm: `make helm-deploy`.

The image comes from the sibling `03-github-actions-cicd` project on GHCR. Make that
package public (GitHub → Packages → Package settings), or build locally and load it:

```bash
docker build -t demo-app:local ../03-github-actions-cicd
kind load docker-image demo-app:local --name demo
kubectl -n demo set image deployment/demo-app app=demo-app:local
```

Cleanup: `make clean`.

## Try these in a demo

```bash
kubectl -n demo scale deploy/demo-app --replicas=4        # scale manually
kubectl -n demo set image deploy/demo-app app=<bad-image> # watch the rollout stall safely
kubectl -n demo rollout undo deploy/demo-app              # roll back
kubectl drain <node> --ignore-daemonsets                  # PDB keeps >=1 pod up
```
