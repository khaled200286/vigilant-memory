#!/usr/bin/env bash

set -x
set -e
set -o pipefail

eval "$(minikube -p minikube docker-env)"

img="local/example"
tag="$(git rev-parse HEAD)"
docker build -f ./Dockerfile -t "$img" .
docker tag "$img":latest "$img":"$tag"
docker image ls --no-trunc "$img"
# kubectl run demo -it --rm --image="$img":"$tag" --restart=Never --image-pull-policy=Never -- "dotnet --info"
eval "$(minikube docker-env --unset)"
