MAKEFLAGS += --silent

setup-linux:
	if ! [ -x "$$(command -v kubectl)" ]; then \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
	fi
	if ! [ -x "$$(command -v helm)" ]; then \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	fi
	#source <(kubectl completion zsh)
	alias k="kubectl"

minikube:
	echo "You are about to create minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	if ! [ -x "$$(command -v minikube)" ]; then \
		curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; \
	        sudo install minikube-linux-amd64 /usr/local/bin/minikube; \
		rm -rf minikube-linux-amd64; \
	fi
	eval $$(minikube docker-env --unset) || true
	minikube delete || true
	minikube start \
		--driver=docker \
		--kubernetes-version=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) \
		--memory=8192 \
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

minikube-status:
	minikube ssh docker images
	minikube service list

prometheus:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update # helm show values prometheus-community/prometheus
	helm upgrade --install prometheus prometheus-community/prometheus \
		--set=service.type=NodePort \
		--create-namespace --namespace=monitoring
	export POD_NAME=$$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
	kubectl --namespace monitoring port-forward $$POD_NAME 9090 &

grafana:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install grafana \
		--namespace=monitoring \
		--set=adminUser=admin \
		--set=service.type=NodePort \
		--set=adminPassword=admin \
		grafana/grafana

.PHONY: get-events
get-events:
	kubectl get events --sort-by=.metadata.creationTimestamp

.PHONY: test
test: ## Test app
	[ -f ./tests/test.sh ] && ./tests/test.sh

weather-forecast-api-build:
	cd src; ./minikube-build-local.sh; cd -

weather-forecast-api-deploy:
	kubectl apply -f ./deploy/minikube/manifest.yaml
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=weather-forecast-api"

weather-forecast-api-status:
	for pod in $$(kubectl get po --output=jsonpath={.items..metadata.name}); do echo $$pod && kubectl exec -it $$pod -- env; done

clean:
	eval $$(minikube docker-env --unset)
	kubectl delete -f deploy/minikube/manifest.yaml || true
	echo "You are about to delete minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	minikube delete
