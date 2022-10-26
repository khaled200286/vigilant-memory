img="local/example"

docker build -f ./Dockerfile -t "$img" .
docker tag "$img":latest "$img":$(git rev-parse HEAD)
docker image ls "$img"

kubectl run -i --rm  --image=local/example:latest --restart=Never -- dotnet --info
