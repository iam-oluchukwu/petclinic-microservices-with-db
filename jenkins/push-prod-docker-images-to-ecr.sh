#!/bin/bash
# MSP 27 - Push production Docker images to AWS ECR

set -euo pipefail

echo "=== Authenticating Docker with AWS ECR ==="

aws ecr get-login-password --region "${AWS_REGION}" | \
docker login --username AWS \
  --password-stdin "${ECR_REGISTRY}"

echo "=== Pushing production Docker images ==="

docker push "${IMAGE_TAG_ADMIN_SERVER}"

docker push "${IMAGE_TAG_API_GATEWAY}"

docker push "${IMAGE_TAG_CONFIG_SERVER}"

docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"

docker push "${IMAGE_TAG_DISCOVERY_SERVER}"

docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"

docker push "${IMAGE_TAG_VETS_SERVICE}"

docker push "${IMAGE_TAG_VISITS_SERVICE}"

docker push "${IMAGE_TAG_GRAFANA_SERVICE}"

docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"

echo "=== All production Docker images pushed successfully ==="
