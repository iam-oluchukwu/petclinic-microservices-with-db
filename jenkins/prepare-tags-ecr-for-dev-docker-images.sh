#!/bin/bash

: "${WORKSPACE:?WORKSPACE is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"
: "${APP_REPO_NAME:?APP_REPO_NAME is required}"
: "${BUILD_NUMBER:?BUILD_NUMBER is required}"

mvn_version() {
  local file="$WORKSPACE/$1/target/maven-archiver/pom.properties"
  local version

  version=$(sed -n 's/^version=//p' "$file" | head -n 1)
  if [ -z "$version" ]; then
    echo "Missing Maven version in $file" >&2
    return 1
  fi

  printf '%s' "$version"
}

export IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-v$(mvn_version spring-petclinic-admin-server)-b${BUILD_NUMBER}"

export IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-v$(mvn_version spring-petclinic-api-gateway)-b${BUILD_NUMBER}"

export IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-v$(mvn_version spring-petclinic-config-server)-b${BUILD_NUMBER}"

export IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-v$(mvn_version spring-petclinic-customers-service)-b${BUILD_NUMBER}"

export IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-v$(mvn_version spring-petclinic-discovery-server)-b${BUILD_NUMBER}"

export IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-v$(mvn_version spring-petclinic-hystrix-dashboard)-b${BUILD_NUMBER}"

export IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-v$(mvn_version spring-petclinic-vets-service)-b${BUILD_NUMBER}"

export IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-v$(mvn_version spring-petclinic-visits-service)-b${BUILD_NUMBER}"

export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"

export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
