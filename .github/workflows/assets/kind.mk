cluster := demo
kind:
	if ! [ -x "$$(command -v kind)" ]; then \
		curl -sLo ./kind https://kind.sigs.k8s.io/dl/v0.16.0/kind-linux-amd64; \
		chmod +x ./kind; \
		sudo mv ./kind /usr/local/bin/kind; \
	fi
	kind create cluster --name $(cluster) --config=kind.yaml #--retain
	# kind export logs --name $(cluster) || #docker logs $(cluster)-control-plane
	kind get clusters
	kubectl config set-context kind-$(cluster) --namespace default

kind-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

clean-kind: 
	kind delete clusters $(cluster)
