.PHONY: cluster ingress deploy helm-deploy test status logs clean

cluster:            ## create a 3-node local cluster
	kind create cluster --config kind-config.yaml

ingress:            ## install ingress-nginx and metrics-server
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller --timeout=120s
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl -n kube-system patch deployment metrics-server --type=json \
	  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

deploy:             ## deploy with plain manifests (kustomize)
	kubectl apply -k k8s
	kubectl -n demo rollout status deployment/demo-app

helm-deploy:        ## deploy with Helm instead
	helm upgrade --install demo helm/demo-app -n demo --create-namespace \
	  --set ingress.enabled=true

test:               ## hit the app through the ingress
	curl -s http://demo.localtest.me/health

status:
	kubectl -n demo get deploy,po,svc,ingress,hpa,pdb

logs:
	kubectl -n demo logs -l app=demo-app --tail=50

clean:
	kind delete cluster --name demo
