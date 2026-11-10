#!/bin/bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-$(pwd)}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
AWS_REGION="us-east-1"
APP_REPO_NAME="clarusway-repo/petclinic-app-staging"

AWS_ACCOUNT=$(aws sts get-caller-identity \
  --query Account --output text)

ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

prepare_tag() {
  local variable="$1"
  local module="$2"
  local service="$3"

  local properties="${WORKSPACE}/${module}/target/maven-archiver/pom.properties"

  if [[ ! -f "$properties" ]]; then
    echo "ERROR: Maven build artifact missing: $properties"
    return 1
  fi

  local version
  version=$(awk -F= '$1 == "version" {print $2; exit}' "$properties")

  if [[ -z "$version" ]]; then
    echo "ERROR: Could not read Maven version for $module"
    return 1
  fi

  printf -v "$variable" '%s' \
    "${ECR_REGISTRY}/${APP_REPO_NAME}:${service}-staging-v${version}-b${BUILD_NUMBER}"

  export "$variable"
  echo "${variable}=${!variable}"
}

prepare_tag IMAGE_TAG_ADMIN_SERVER \
  spring-petclinic-admin-server admin-server

prepare_tag IMAGE_TAG_API_GATEWAY \
  spring-petclinic-api-gateway api-gateway

prepare_tag IMAGE_TAG_CONFIG_SERVER \
  spring-petclinic-config-server config-server

prepare_tag IMAGE_TAG_CUSTOMERS_SERVICE \
  spring-petclinic-customers-service customers-service

prepare_tag IMAGE_TAG_DISCOVERY_SERVER \
  spring-petclinic-discovery-server discovery-server

prepare_tag IMAGE_TAG_HYSTRIX_DASHBOARD \
  spring-petclinic-hystrix-dashboard hystrix-dashboard

prepare_tag IMAGE_TAG_VETS_SERVICE \
  spring-petclinic-vets-service vets-service

prepare_tag IMAGE_TAG_VISITS_SERVICE \
  spring-petclinic-visits-service visits-service

export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"

export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"

echo "IMAGE_TAG_GRAFANA_SERVICE=${IMAGE_TAG_GRAFANA_SERVICE}"
echo "IMAGE_TAG_PROMETHEUS_SERVICE=${IMAGE_TAG_PROMETHEUS_SERVICE}"

echo "Staging image tags prepared successfully."
