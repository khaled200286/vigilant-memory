setup:
	if ! [ -x "$$(command -v kubectl)" ]; then \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
	fi
	if ! [ -x "$$(command -v helm)" ]; then \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	fi
	if ! [ -x "$$(command -v kind)" ]; then \
		curl -sLo ./kind https://kind.sigs.k8s.io/dl/v0.16.0/kind-linux-amd64; \
		chmod +x ./kind; \
		sudo mv ./kind /usr/local/bin/kind; \
	fi
	#source <(kubectl completion zsh)
	alias k="kubectl"

cluster := demo
kind: setup
	kind create cluster --name $(cluster) --config=.github/workflows/assets/kind.yaml #--retain
	# kind export logs --name $(cluster) || #docker logs $(cluster)-control-plane
	kind get clusters
	kubectl config set-context $(cluster) --namespace default
	kubectl cluster-info
	kubectl get nodes
	kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s
	kubectl get all -A	
	
ingress: setup
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

prometheus: setup
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update
	helm install prometheus prometheus-community/prometheus \
		--create-namespace --namespace=monitoring

grafana: setup
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm install grafana \
		--namespace=monitoring \
		--set=adminUser=admin \
		--set=adminPassword=admin \
		--set=service.type=NodePort \
		grafana/grafana

events: setup
	kubectl get events --sort-by=.metadata.creationTimestamp

clean-kind: setup
	kind delete clusters $(cluster)
