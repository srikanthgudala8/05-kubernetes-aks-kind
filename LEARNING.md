# Phase 5 - Kubernetes (Days 39-49)

**Goal:** run, expose, scale, secure and troubleshoot applications on Kubernetes, locally
with kind and in the cloud with AKS.

**Setup:** Docker, `kind`, `kubectl`, `helm`. Optional: `k9s` (terminal UI), `kubectx`.
Add `alias k=kubectl` and enable autocomplete. The project manifests are in `k8s/`, the
Helm chart in `helm/`, exercises in `labs/`, and cloud notes in `aks/`.

---

## Day-by-day plan

### Day 39 - Architecture and first cluster
- **Learn:** control plane (API server, etcd, scheduler, controller manager) and nodes (kubelet, container runtime, kube-proxy). Declarative desired state and reconciliation loops.
- **Lab:** `make cluster` to create a 3-node kind cluster. `kubectl get nodes -o wide`, `kubectl get pods -A`, `kubectl cluster-info`.
- **Done when:** you can explain what happens when you run `kubectl apply`.

### Day 40 - Pods and Deployments
- **Learn:** Pod, ReplicaSet, Deployment, labels and selectors, namespaces, rolling updates and rollbacks.
- **Lab:** run a pod imperatively, then declaratively. Scale a deployment, change the image, watch `kubectl rollout status`, then `kubectl rollout undo`.
- **Done when:** you understand why you never create bare Pods in production.

### Day 41 - Services and Ingress
- **Learn:** ClusterIP, NodePort, LoadBalancer, DNS names (`svc.namespace.svc.cluster.local`), Ingress and ingress controllers.
- **Lab:** `make ingress` then `make deploy`, then `curl http://demo.localtest.me/health`. Use `kubectl port-forward` to reach the Service directly.
- **Done when:** you can trace a request from browser to pod.

### Day 42 - Configuration and secrets
- **Learn:** ConfigMap, Secret (base64 is not encryption), env vs mounted files, immutable config, external secrets (Key Vault CSI driver, External Secrets Operator).
- **Lab:** apply `labs/examples/config-and-secret.yaml`, read the pod logs, change the ConfigMap and see what updates automatically and what needs a restart.
- **Done when:** you know why committing a Secret manifest with real values is a bad idea.

### Day 43 - Probes and resources
- **Learn:** startup, liveness and readiness probes, requests vs limits, QoS classes, OOMKilled, CPU throttling.
- **Lab:** read `k8s/deployment.yaml`. Set the memory limit to `10Mi` and watch the pod get OOMKilled. Break the readiness path and see what the rollout does.
- **Done when:** you can choose sensible requests and limits and justify them.

### Day 44 - Scaling and updates
- **Learn:** HPA (needs metrics-server), PodDisruptionBudget, topology spread, rolling update parameters, readiness gates. Cluster autoscaler concept.
- **Lab:** generate load against `/slow` with a loop of `curl` (or `hey`) and watch `kubectl get hpa -w`. Drain a node with `kubectl drain` and watch the PDB protect availability.
- **Done when:** you can explain `maxSurge` and `maxUnavailable`.

### Day 45 - Storage and stateful apps
- **Learn:** volumes, PersistentVolume, PersistentVolumeClaim, StorageClass, StatefulSet vs Deployment, headless Service.
- **Lab:** apply `labs/examples/statefulset-storage.yaml`, write data to `redis-0`, delete the pod and verify the data survives.
- **Done when:** you can say when *not* to run a database in Kubernetes.

### Day 46 - Security: RBAC, namespaces, network policies
- **Learn:** Role/ClusterRole, bindings, ServiceAccounts, Pod Security Standards, NetworkPolicy, image pull secrets.
- **Lab:** apply `labs/examples/rbac-readonly.yaml` and test with `kubectl auth can-i`. Read `k8s/networkpolicy.yaml`, then try to `curl` the pod from another namespace and observe the block.
- **Done when:** you can describe least privilege in Kubernetes terms.

### Day 47 - Helm
- **Learn:** charts, values, templates, releases, `helm lint/template/install/upgrade/rollback`, chart repositories.
- **Lab:** `helm template demo helm/demo-app` and read the output. `make helm-deploy`, then `helm upgrade --set replicaCount=3`, then `helm rollback demo 1`. Install `ingress-nginx` or `kube-prometheus-stack` from a public chart.
- **Done when:** you can package your own app as a chart.

### Day 48 - Managed Kubernetes: AKS (and EKS notes)
- **Learn:** what the cloud manages vs what you manage, node pools, cloud load balancers, registry integration, managed identity.
- **Lab:** follow `aks/README.md`: create an AKS cluster, deploy the same app, expose it, then delete the resource group.
- **Done when:** you have run the same manifests on kind and AKS.

### Day 49 - Troubleshooting drills and capstone
- **Lab:** apply each file in `labs/broken/`, diagnose using only `kubectl get/describe/logs/events`, fix it, write the root cause in `notes/`. Answers are in the *Answers* section below, try first.
- **Capstone:** deploy your Phase 2 three-tier app on Kubernetes (Deployments, Service, Ingress, a Redis StatefulSet, HPA, resource limits, probes) with Helm or Kustomize.
- **Done when:** the app survives a node drain and a bad deploy rollback.

---

## Answers to `labs/broken/`
1. **ImagePullBackOff:** the tag does not exist. Fix the image tag. (`describe` Events: "manifest unknown")
2. **CrashLoopBackOff:** the container reads `/config/settings.yaml`, which is not mounted, so `cat` fails and the container exits. Mount a ConfigMap at `/config`.
3. **Pending:** requests of 64 CPUs and 512 Gi cannot be satisfied by any node ("Insufficient cpu/memory"). Lower the requests.
4. **Service with no endpoints:** selector `app: webapp` does not match pod label `app: web`. Fix the selector.
5. **Not Ready:** the probe checks port 8080 and `/healthz` but nginx listens on 80 and has no such path. Fix the probe.

## kubectl survival kit
```bash
kubectl get pods -A -o wide                 # everything, with node and IP
kubectl describe pod <p>                    # events are at the bottom: read them first
kubectl logs <p> [-c container] --previous  # logs of the crashed instance
kubectl get events --sort-by=.lastTimestamp
kubectl exec -it <p> -- sh
kubectl port-forward svc/<svc> 8080:80
kubectl rollout status|history|undo deploy/<d>
kubectl top pods; kubectl top nodes
kubectl explain deployment.spec.strategy    # built-in docs
kubectl get deploy <d> -o yaml              # the real, full object
kubectl auth can-i <verb> <resource> --as <user>
kubectl diff -f file.yaml                   # preview a change
```

## Pod troubleshooting flow
`Pending` -> scheduling (resources, taints, PVC)  |  `ImagePullBackOff` -> image name, tag, registry auth
`CrashLoopBackOff` -> logs --previous, config, probes  |  `Running but not Ready` -> readiness probe
`Ready but unreachable` -> Service selector/endpoints, NetworkPolicy, Ingress

## Check yourself
1. What happens between `kubectl apply` and a running pod?
2. Deployment vs StatefulSet vs DaemonSet vs Job?
3. How do liveness and readiness probes differ in effect?
4. Requests vs limits: what happens when each is exceeded?
5. How does a Service find its pods? What are Endpoints?
6. How would you do zero-downtime updates and fast rollbacks?
7. Why is a Kubernetes Secret not "secure" by default and how do you improve it?
8. What do managed services like AKS/EKS take care of for you?
