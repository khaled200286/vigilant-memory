#!/bin/bash
set -e
#set -x

#service="weather-forecast-api"
#url="$(minikube service $service --url)"
url="localhost:8080"

counter=0
while true; do
   counter=$((counter+1))
   echo "$counter"
   curl -skX GET "$url/WeatherForecast" -H"Host: weather-forecast-api.local" | xargs # | jq ". | length"
   sleep 1
done
