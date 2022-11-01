## Introduction 
Examples for deployment pipelines and strategies with GitHub Actions.

## Requirements
Linux with sudo and [docker](https://docs.docker.com/engine/install/).

## Getting Started
1. Fork this repo
2. Install developer environment with additional tools:

```
## Bootstrap
make 

## Build image with demo .NET app
make build

## Test
make test

# Clean up
make clean
```

## Deployment strategies examples covered in demo
- Recreate
- RollingUpdate
- BlueGreen

## Github Actions
- .github/workflows/ci.yaml - build, deploy and test local image with [docker-compose](https://docs.docker.com/compose/)
- .github/workflows/minikube.yaml - build and and test local image with [minikube](https://minikube.sigs.k8s.io/docs/)
- .github/workflows/release.yaml - build and promote public image and optionally deploy with [Azure App Services](https://learn.microsoft.com/en-us/azure/app-service/)

## Contributing

1. Have an idea for a cool workflow
2. Fork the repository
3. Implement and test your workflow
4. Describe it shortly in the README
5. Open a pull request
