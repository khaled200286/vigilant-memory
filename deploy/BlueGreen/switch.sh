#!/bin/bash

service="weather-forecast-api"
items=("blue" "green")

echo "Choose the color to run from the blue/green deployment strategy:"
select COLOR in "${items[@]}";
do
  case "$COLOR" in
    blue)
      kubectl apply -f app-blue.yaml || true
      kubectl wait --for=condition=Ready pods --timeout=300s -l "color=blue"
      kubectl patch service $service -p '{"spec":{"selector":{"color":"blue"}}}'; 
      kubectl delete -f app-green.yaml 2> /dev/null|| true
      kubectl get svc/$service -o wide
      exit ;;
    green) 
      kubectl apply -f app-green.yaml || true
      kubectl wait --for=condition=Ready pods --timeout=300s -l "color=green"
      kubectl patch service $service -p '{"spec":{"selector":{"color":"green"}}}'; 
      kubectl delete -f app-blue.yaml 2> /dev/null || true
      kubectl get svc/$service -o wide
      exit ;;
    *)
      kubectl get po -o wide
      kubectl get svc/$service -o wide
      exit;;
  esac
done
