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
	echo "$@: done"

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
	kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
	export POD_NAME=$$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
	kubectl --namespace monitoring port-forward $$POD_NAME 9090 &

.PHONY: get-events
get-events:
	kubectl get events --sort-by=.metadata.creationTimestamp

.PHONY: test
test: ## Generate traffic and test app
	[ -f ./tests/test.sh ] && ./tests/test.sh

APP := weather-forecast-api

weather-forecast-api-build:
	cd src; ./minikube-build-local.sh; cd -

weather-forecast-api-deploy-RollingUpdate:
	kubectl apply -f ./deploy/strategies/RollingUpdate/manifest.yaml
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=weather-forecast-api"

weather-forecast-api-deploy-Recreate:
	kubectl apply -f ./deploy/strategies/Recreate/manifest.yaml
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=weather-forecast-api"

weather-forecast-api-clean:
	kubectl delete all -l app=$(APP)

weather-forecast-api-open:
	xdg-open $$(minikube service weather-forecast-api --url)/WeatherForecast

weather-forecast-api-status:
	kubectl get all -o wide
	for pod in $$(kubectl get po --output=jsonpath={.items..metadata.name}); do echo $$pod && kubectl exec -it $$pod -- env; done

clean:
	eval $$(minikube docker-env --unset)
	kubectl delete -f deploy/minikube/manifest.yaml || true
	echo "You are about to delete minikube cluster."
	echo "Are you sure? (Press Enter to continue or Ctrl+C to abort) "
	read _
	minikube delete
