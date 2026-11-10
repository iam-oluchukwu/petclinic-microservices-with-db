#!/bin/bash
# MSP 27 - Deploy Petclinic to Production EKS

set -euo pipefail

echo "=== Verify production Kubernetes cluster ==="

CURRENT_CONTEXT=$(kubectl config current-context)

case "$CURRENT_CONTEXT" in
  *"@petclinic-cluster.us-east-1.eksctl.io")
    echo "Production EKS context verified"
    ;;
  *)
    echo "ERROR: Wrong Kubernetes context: $CURRENT_CONTEXT"
    exit 1
    ;;
esac

echo "=== Verify Jenkins environment ==="
: "${WORKSPACE:?WORKSPACE is required}"
: "${BUILD_NUMBER:?BUILD_NUMBER is required}"
: "${AWS_REGION:?AWS_REGION is required}"
: "${DNS_NAME:?DNS_NAME is required}"

cd "$WORKSPACE"

echo "=== Create production namespace ==="

kubectl create namespace petclinic-prod-ns \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== Verify database credentials ==="

kubectl get secret petclinic-mysql-credentials \
  -n petclinic-prod-ns >/dev/null

echo "=== Prepare Helm values ==="

envsubst < k8s/petclinic_chart/values-template.yaml \
  > k8s/petclinic_chart/values.yaml

sed -i "s/HELM_VERSION/${BUILD_NUMBER}/" \
  k8s/petclinic_chart/Chart.yaml

echo "=== Configure production Helm repository ==="

helm repo add stable-petclinic \
  "s3://petclinic-helm-charts-083127296249-msp17/stable/myapp/" --force-update

helm repo update

echo "=== Package Helm chart ==="

helm package k8s/petclinic_chart

echo "=== Push Helm chart to S3 ==="

helm s3 push --force \
  "petclinic_chart-${BUILD_NUMBER}.tgz" stable-petclinic

echo "=== Create or update image pull credentials ==="

kubectl create secret generic regcred \
  -n petclinic-prod-ns \
  --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== Deploy production application ==="

helm repo update

helm upgrade --install petclinic-app-release \
  stable-petclinic/petclinic_chart \
  --version "${BUILD_NUMBER}" \
  --namespace petclinic-prod-ns \
  --wait \
  --timeout 10m

echo "=== Production deployment completed ==="
