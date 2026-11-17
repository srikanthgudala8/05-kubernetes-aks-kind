# AKS (Azure Kubernetes Service) - Day 48

Everything you practised on kind works on AKS. The differences are cluster creation,
authentication, ingress/load balancers, and identity.

## Create a small, cheap cluster

```bash
az login
az group create -n rg-aks-demo -l centralindia

az aks create \
  -g rg-aks-demo -n aks-demo \
  --node-count 2 --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --generate-ssh-keys

az aks get-credentials -g rg-aks-demo -n aks-demo
kubectl get nodes
```

## Deploy the same app

```bash
kubectl apply -k k8s              # namespace, deployment, service, hpa, pdb, network policy
kubectl -n demo get pods
# Expose it with a cloud load balancer instead of ingress:
kubectl -n demo patch svc demo-app -p '{"spec":{"type":"LoadBalancer"}}'
kubectl -n demo get svc demo-app -w     # wait for EXTERNAL-IP, then curl it
```

Network policies need the network policy engine enabled on the cluster
(`--network-policy azure` or `calico` at creation). Without it they are silently ignored.

## Things to explore
- `az aks scale`, `az aks upgrade`, node pools (`az aks nodepool add`)
- Managed ingress: `az aks approuting enable`
- Azure Container Registry: `az acr create` + `az aks update --attach-acr`
- Workload identity (pods get Azure access without secrets)
- Azure Monitor Container Insights and Managed Prometheus/Grafana (ties into Phase 6)

## Clean up (AKS nodes bill while running)
```bash
az group delete -n rg-aks-demo --yes --no-wait
```

## AWS equivalent (EKS) in one paragraph
`eksctl create cluster --name demo --nodes 2` creates the control plane, a managed node
group and your kubeconfig. Load balancers come from the AWS Load Balancer Controller,
identity from IAM Roles for Service Accounts (IRSA). Concepts are identical.
