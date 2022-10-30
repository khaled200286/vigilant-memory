MAKEFLAGS += --silent

all: minikube prometheus

bootstrap:
	if ! [ -x "$$(command -v kubectl)" ]; then \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
	fi
	if ! [ -x "$$(command -v helm)" ]; then \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	fi
	#source <(kubectl completion zsh)
	alias k="kubectl"
	echo "$@: done."

.PHONY: minikube
minikube: bootstrap
	set -x
	echo "You are about to create minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	if ! [ -x "$$(command -v minikube)" ]; then \
		curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; \
	        sudo install minikube-linux-amd64 /usr/local/bin/minikube; \
		rm -rf minikube-linux-amd64; \
	fi
	eval $$(minikube docker-env --unset) || true
	minikube start \
		--driver=docker \
		--kubernetes-version=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) \
		--memory=8g \
		--cpus=2 \
		--bootstrapper=kubeadm \
		--extra-config=kubeadm.node-name=minikube \
		--extra-config=kubelet.hostname-override=minikube
	minikube addons disable metrics-server
	#minikube addons enable ingress
	#minikube addons enable ingress-dns
	#minikube addons list
	kubectl config set-context minikube --namespace default
	kubectl cluster-info
	kubectl get nodes
	kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s
	kubectl get all -A

.PHONY: minikube-status
minikube-status:
	minikube ssh docker images
	minikube service list

.PHONY: prometheus
prometheus:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update
	helm upgrade --install prometheus prometheus-community/prometheus \
		--set=service.type=NodePort \
		--create-namespace --namespace=monitoring
	kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
	kubectl wait deployment prometheus-server -n monitoring --for condition=Available=True --timeout=90s
	helm list -n monitoring
	#killall kubectl || kubectl -n monitoring port-forward svc/prometheus-server 9090:80 &
	minikube service -n monitoring prometheus-server &

.PHONY: nginx
nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
	helm repo add nginx-stable https://helm.nginx.com/stable || true
	helm repo update
	helm upgrade --install nginx nginx-stable/nginx-ingress \
		--create-namespace --namespace=nginx

.PHONY: get-events
get-events:
	kubectl get events --sort-by=.metadata.creationTimestamp

.PHONY: test
test: ## Generate traffic and test app
	[ -f ./tests/test.sh ] && ./tests/test.sh

.PHONY: clean
clean:
	echo "You are about to stop minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	eval $$(minikube docker-env --unset)
	minikube stop # delete

-include include.mk
