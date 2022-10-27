#!/bin/sh
set -o errexit

service="weather-forecast-api"
URL="$(minikube service $service --url)"

while true; do 
   curl -skX GET "$URL/WeatherForecast" -H "accept: text/plain" | xargs # | jq ". | length"
   sleep 1 
done
