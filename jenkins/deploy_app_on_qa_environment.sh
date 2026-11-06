#!/bin/bash
set -e

echo 'Deploying App on Kubernetes'

HELM_REPO_URL="s3://petclinic-helm-charts-083127296249-msp17/stable/myapp/"
HELM_CHART_VERSION="0.20.${BUILD_NUMBER}"

: "${DNS_NAME:?DNS_NAME must be configured for QA deployment}"

# Prepare the Helm chart
mkdir -p .qa-chart
cp -a k8s/petclinic_chart/. .qa-chart/

envsubst < k8s/petclinic_chart/values-template.yaml > .qa-chart/values.yaml

sed -i "s/^version: HELM_VERSION$/version: ${HELM_CHART_VERSION}/" .qa-chart/Chart.yaml

# Package and upload the Helm chart
helm repo add stable-petclinic "${HELM_REPO_URL}" --force-update

AWS_REGION="${AWS_REGION}" helm repo update

helm package .qa-chart --destination .

HELM_S3_MODE=3 AWS_REGION="${AWS_REGION}" \
  helm s3 push --force \
  "petclinic_chart-${HELM_CHART_VERSION}.tgz" stable-petclinic

# Create QA namespace
kubectl create namespace petclinic-qa \
  --dry-run=client -o yaml | kubectl apply -f -

# Configure ECR image pull credentials
kubectl create secret generic regcred \
  -n petclinic-qa \
  --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy the application
AWS_REGION="${AWS_REGION}" helm repo update

AWS_REGION="${AWS_REGION}" helm upgrade --install \
  petclinic-app-release \
  stable-petclinic/petclinic_chart \
  --version "${HELM_CHART_VERSION}" \
  --namespace petclinic-qa

echo 'QA application deployment completed'
