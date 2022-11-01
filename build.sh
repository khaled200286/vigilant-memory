#!/usr/bin/env bash
# Build a docker image inside minikube

#set -x
set -e
set -o pipefail

app="$1"
img="minikube/$app" # must be lowercase

pushd src
eval "$(minikube -p minikube docker-env)"

docker build -f ./Dockerfile -t "$img" .

tag="$(git rev-parse HEAD)" #"$(git describe --tags $(git rev-list --tags --max-count=1))"

if [ -z "$(git status --porcelain)" ]; then 
  docker tag "$img":latest "$img":"$tag"
else
  # Only for testing
  docker tag "$img":latest "$img":"v0.0.1"
  docker tag "$img":latest "$img":"v0.0.2"
fi

docker image ls --no-trunc "$img"
# kubectl run foo -it --rm --image="$img":"$tag" --restart=Never --image-pull-policy=Never -- "dotnet --info"
eval "$(minikube docker-env --unset)"
popd
