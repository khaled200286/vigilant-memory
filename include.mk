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
