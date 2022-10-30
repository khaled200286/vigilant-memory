#!/bin/bash
set -x
set -e
set -o pipefail

SCRIPT_ROOT=$(dirname "${BASH_SOURCE[0]}")
COLOR="$1"

service="weather-forecast-api"
items=("blue" "green")
        
switch_incoming_traffic() { 
  case "$COLOR" in
    blue)
      patch_service "$COLOR" green
      exit ;;
    green) 
      patch_service "$COLOR" blue
      exit ;;
    *)
      get_status
       exit;;
  esac
}

patch_service() {
  local new="$1"
  local old="$2"
  kubectl apply -f "$SCRIPT_ROOT"/app-"$new".yaml || true
  kubectl wait --for=condition=Ready pods --timeout=300s -l "color=$new"
  kubectl patch service "$service" -p "{\"spec\":{\"selector\":{\"color\": \"${new}\" }}}"
  # Delete old deployment if exists
  kubectl delete -f "$SCRIPT_ROOT"/app-"$old".yaml 2> /dev/null|| true
  get_status
}

get_status() {
  kubectl get po -o wide
  kubectl get svc/$service -o wide
}

if [ -z "$COLOR" ]; then
  echo "[$SCRIPT_ROOT/$(basename "$0")] Choose the color to run from the blue/green deployment strategy:"
  select COLOR in "${items[@]}";
  do
    switch_incoming_traffic
  done
else
  switch_incoming_traffic "$COLOR"
fi
