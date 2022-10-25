#!/bin/sh
set -o errexit

curl -skX GET "http://localhost/WeatherForecast" -H "accept: text/plain"
