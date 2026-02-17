#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="monitoring"
RELEASE_NAME="kube-prometheus-stack"
CHART="prometheus-community/kube-prometheus-stack"
VALUES_FILE="helm-values/prometheus-ha-values.yaml"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required" >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required" >&2
  exit 1
fi

echo "[1/5] Ensuring namespace exists"
kubectl apply -f k8s/namespace.yaml

echo "[2/5] Checking Thanos object storage secret"
if ! kubectl -n "${NAMESPACE}" get secret thanos-objectstore-config >/dev/null 2>&1; then
  cat >&2 <<MSG
Missing secret: thanos-objectstore-config in namespace ${NAMESPACE}
Create it from k8s/thanos-objectstore-secret.example.yaml before deployment.
MSG
  exit 1
fi

echo "[3/5] Installing/upgrading kube-prometheus-stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null
helm upgrade --install "${RELEASE_NAME}" "${CHART}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  --wait

echo "[4/5] Deploying Thanos Query"
kubectl apply -f k8s/thanos-query.yaml

echo "[5/5] Deploying Thanos Query Frontend"
kubectl apply -f k8s/thanos-query-frontend.yaml

echo "Deployment complete."
echo "Run: kubectl -n monitoring get pods"
echo "Access: kubectl -n monitoring port-forward svc/thanos-query-frontend 9091:9091"
