MAKEFLAGS += --silent

.DEFAULT_GOAL := all

.PHONY: all
all: clean setup minikube install-prometheus install-ingress-nginx
	echo ""
	echo "URL: 'http://localhost:8080'"

.PHONY: setup
setup:
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
minikube: setup
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

.PHONY: install-prometheus
install-prometheus:
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

.PHONY: install-ingress-nginx
install-ingress-nginx:
	# helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
	helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
    --set controller.updateStrategy.rollingUpdate.maxUnavailable=25% \
		--set controller.updateStrategy.type=RollingUpdate \
    --set controller.metrics.enabled=true \
		--set=controller.service.type=NodePort \
		--namespace ingress-nginx \
		--create-namespace
	kubectl get pods --namespace=ingress-nginx
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s
	
ingress-nginx-port-forward:
	killall kubectl || kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &
	curl -D- http://localhost:8080

.PHONY: ingress-nginx
ingress-nginx-demo:
	kubectl create deployment demo --image=httpd --port=80
	kubectl expose deployment demo
	kubectl create ingress demo --class=nginx --rule="www.demo.io/*=demo:80" # --tls:- hosts: - www.demo.io secretName: demo-tls
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=demo"
	sleep 1
	curl -D- http://localhost:8080 -H "Host: www.demo.io"
	sleep 3
	kubectl delete ing demo
	kubectl delete pods,services,deployments -l app=demo

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
	minikube stop

-include include.mk
