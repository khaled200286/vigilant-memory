#!/usr/bin/env bash
# Build a docker image inside minikube

set -x
set -e
set -o pipefail

img="minikube/weather-forecast-api" # must be lowercase
tag="$(git rev-parse HEAD)"

pushd src
eval "$(minikube -p minikube docker-env)"
docker build -f ./Dockerfile -t "$img" .
docker tag "$img":latest "$img":"$tag"
docker image ls --no-trunc "$img"
# kubectl run foo -it --rm --image="$img":"$tag" --restart=Never --image-pull-policy=Never -- "dotnet --info"
eval "$(minikube docker-env --unset)"
popd
