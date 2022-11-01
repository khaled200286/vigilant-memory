#!/usr/bin/env bash

set -e
set -o pipefail

# Deploy web app infrastructure for Linux containers.
#
# Usage:
# Include in your builds via
# \curl -sSL https://raw.githubusercontent.com/atrakic/azure-webapps-deploy-github-actions/main/infra/setup.sh | \
#  WEB_APP_NAME=app-$RANDOM IMAGE_NAME=ghcr.io/atrakic/azure-webapps-deploy-github-actions:latest bash -s

WEB_APP_NAME=${WEB_APP_NAME:?'You need to configure the WEB_APP_NAME environment variable; eg. app-testaaaay'}
IMAGE_NAME=${IMAGE_NAME:?'You need to configure IMAGE_NAME environment variable; eg. docker.io/nginx:latest'}

# Optionals:
LOCATION_NAME=${LOCATION_NAME:-westeurope}
APP_SERVICE_PLAN_NAME=${APP_SERVICE_PLAN_NAME:-MyPlan}
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-rg-$RANDOM}
SKU_NAME=${SKU_NAME:-S1}

# https://learn.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest
az group create --location "$LOCATION_NAME" --name "$RESOURCE_GROUP_NAME"

# https://learn.microsoft.com/en-us/cli/azure/appservice?view=azure-cli-latest
az appservice plan create --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --sku "$SKU_NAME" --is-linux

# https://learn.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest
az webapp create --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --plan "$APP_SERVICE_PLAN_NAME" -i "$IMAGE_NAME" ### -s username -w password
