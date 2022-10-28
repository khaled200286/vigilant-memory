#!/bin/bash
set -e

service="weather-forecast-api"
url="$(minikube service $service --url)"

counter=0
while true; do
   counter=$((counter+1))
   echo "$counter"
   curl -skX GET "$url/WeatherForecast" -H "accept: text/plain" | xargs # | jq ". | length"
   sleep 1
done
