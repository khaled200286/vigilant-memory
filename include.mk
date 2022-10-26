setup-linux:
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
	if ! [ -x "$$(command -v minikube)" ]; then \
		curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; \
	        sudo install minikube-linux-amd64 /usr/local/bin/minikube; \
		rm -rf minikube-linux-amd64; \
	fi
	#source <(kubectl completion zsh)
	alias k="kubectl"

cluster := demo
kind:
	kind create cluster --name $(cluster) --config=.github/workflows/assets/kind.yaml #--retain
	# kind export logs --name $(cluster) || #docker logs $(cluster)-control-plane
	kind get clusters
	kubectl config set-context kind-$(cluster) --namespace default

minikube:
	echo "You are about to create minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	minikube delete || true
	minikube start \
		--driver=docker \
		--kubernetes-version=v1.25.2 \
		--memory=8192 --bootstrapper=kubeadm
		#--extra-config=kubelet.authentication-token-webhook=true \
		#--extra-config=kubelet.authorization-mode=Webhook \
		#--extra-config=scheduler.address=0.0.0.0 \
		#--extra-config=controller-manager.address=0.0.0.0
	# $$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) \
	#minikube addons disable metrics-server
	minikube addons enable ingress
	minikube addons enable ingress-dns
	#minikube addons list

kubectl-init:
	kubectl cluster-info
	kubectl get nodes
	kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s
	kubectl get all -A

kind-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

prometheus:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update
	helm  upgrade --install prometheus prometheus-community/prometheus \
		--create-namespace --namespace=monitoring

grafana:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install grafana \
		--namespace=monitoring \
		--set=adminUser=admin \
		--set=service.type=NodePort \
		--set=adminPassword=admin \
		grafana/grafana

events:
	kubectl get events --sort-by=.metadata.creationTimestamp

clean-kind: 
	kind delete clusters $(cluster)
