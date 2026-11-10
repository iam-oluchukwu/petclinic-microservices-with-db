#!/bin/bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${WORKSPACE}/jenkins/prepare-tags-ecr-for-staging-docker-images.sh"

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"
: "${APP_REPO_NAME:?APP_REPO_NAME is required}"

IMAGES=(
  "$IMAGE_TAG_ADMIN_SERVER"
  "$IMAGE_TAG_API_GATEWAY"
  "$IMAGE_TAG_CONFIG_SERVER"
  "$IMAGE_TAG_CUSTOMERS_SERVICE"
  "$IMAGE_TAG_DISCOVERY_SERVER"
  "$IMAGE_TAG_HYSTRIX_DASHBOARD"
  "$IMAGE_TAG_VETS_SERVICE"
  "$IMAGE_TAG_VISITS_SERVICE"
  "$IMAGE_TAG_GRAFANA_SERVICE"
  "$IMAGE_TAG_PROMETHEUS_SERVICE"
)

echo "=== Checking local Docker images ==="

for IMAGE in "${IMAGES[@]}"; do
  docker image inspect "$IMAGE" >/dev/null
  echo "FOUND: $IMAGE"
done

echo "=== Checking staging ECR repository ==="

aws ecr describe-repositories \
  --repository-names "$APP_REPO_NAME" \
  --region "$AWS_REGION" \
  --output table

echo "=== Login to Amazon ECR ==="

aws ecr get-login-password \
  --region "$AWS_REGION" |
  docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

echo "=== Pushing staging images to ECR ==="

for IMAGE in "${IMAGES[@]}"; do
  echo "Pushing: $IMAGE"
  docker push "$IMAGE"
done

echo "=== All staging images pushed successfully ==="
