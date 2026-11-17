# Interview notes: Kubernetes deployment

## 60-second pitch

"I deploy a containerised service to Kubernetes with production basics: rolling updates
with zero unavailable pods, startup/liveness/readiness probes, CPU-based HPA, a pod
disruption budget, hardened security context and a default-deny network policy. I
packaged it both as Kustomize manifests and a Helm chart and validate both in CI."

## Design decisions

- **`maxUnavailable: 0` + `maxSurge: 1`:** a new pod must be Ready before an old one is
  removed, so capacity never dips during a deploy.
- **Three probes:** startup protects slow boots from liveness kills; liveness restarts
  hung containers; readiness removes a pod from the Service without restarting it.
- **Requests vs limits:** requests drive scheduling and HPA percentage; limits cap usage
  (CPU throttles, memory limit OOM-kills).
- **Read-only root FS + `emptyDir` on /tmp:** blocks writes by an attacker while letting
  gunicorn keep its heartbeat files.
- **PDB:** protects availability during *voluntary* disruptions (drains, upgrades) only.
- **Kustomize vs Helm:** Kustomize patches plain YAML (no templating); Helm gives
  parameterised, versioned packages and release history. Both are shown.

## Likely questions

1. **Pod stuck in `Pending`?** `kubectl describe pod`: insufficient resources, taints,
   unbound PVC, or node selector mismatch.
2. **`CrashLoopBackOff`?** `kubectl logs --previous`, check the command, env, probes
   killing it, and OOMKilled in `describe`.
3. **`ImagePullBackOff`?** Wrong tag, private registry without `imagePullSecrets`, or
   network access. (A private GHCR package triggers this here.)
4. **Service vs Ingress?** Service gives stable in-cluster networking and load balancing;
   Ingress routes external HTTP(S) by host/path via a controller.
5. **How does the HPA work?** Control loop compares observed metric to target and sets
   `desiredReplicas = ceil(current * observed / target)`; needs metrics-server and CPU requests.
6. **Deployment vs StatefulSet vs DaemonSet?** Stateless replicas / stable identity and
   storage / one pod per node.
7. **How would you do a canary or blue/green?** Two Deployments and weighted ingress
   annotations, or Argo Rollouts / Flagger for automated analysis.
8. **How do you manage secrets?** Kubernetes Secrets are only base64; use External Secrets
   Operator or Sealed Secrets, enable encryption at rest, restrict RBAC.
9. **What does a drain do?** Cordons the node and evicts pods respecting PDBs.
10. **How do you roll back?** `kubectl rollout undo` or `helm rollback`; GitOps would revert the commit.

## Next steps to mention

GitOps with Argo CD, Ingress TLS via cert-manager, Prometheus Operator
(see the monitoring project), resource quotas per namespace, and RBAC with least privilege.
