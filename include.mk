APP := weather-forecast-api

build weather-forecast-api-build:
	./build.sh

weather-forecast-api-deploy-ingress:
	kubectl create ingress weather-forecast-api --class=nginx --rule="$(APP).local/*=$(APP):80" || true
	curl -D- http://localhost:8080 -H "Host: $(APP).local"

weather-forecast-api-deploy weather-forecast-api-deploy-RollingUpdate:
	kubectl apply -f ./deploy/RollingUpdate/manifest.yaml
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=weather-forecast-api"

weather-forecast-api-deploy-Recreate:
	kubectl apply -f ./deploy/Recreate/manifest.yaml
	kubectl wait --for=condition=Ready pods --timeout=300s -l "app=weather-forecast-api"

weather-forecast-api-deploy-BlueGreen:
	kubectl apply -f ./deploy/BlueGreen/app-blue.yaml
	kubectl apply -f ./deploy/BlueGreen/app-green.yaml
	kubectl apply -f ./deploy/BlueGreen/service.yaml

weather-forecast-api-deploy-BlueGreen-switch:
	./deploy/BlueGreen/switch.sh

weather-forecast-api-open:
	xdg-open $$(minikube service weather-forecast-api --url)/WeatherForecast

weather-forecast-api-status:
	kubectl get all -o wide
	for pod in $$(kubectl get po --output=jsonpath={.items..metadata.name}); do echo $$pod && kubectl exec -it $$pod -- env; done

weather-forecast-api-curl-test:
	kubectl run -it --rm --image=curlimages/curl --restart=Never curl-test -- \
		curl -sSL http://$$(kubectl get service weather-forecast-api --output=jsonpath='{.spec.clusterIPs[0]}')

weather-forecast-api-clean:
	kubectl delete all -l app=$(APP)

