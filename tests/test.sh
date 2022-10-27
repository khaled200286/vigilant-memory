#!/bin/sh
set -o errexit

curl -skX GET "$(minikube service example --url)/WeatherForecast" -H "accept: text/plain"
