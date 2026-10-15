#!/usr/bin/env bash
# One-shot bootstrap of a fresh EKS cluster created by terraform/:
# kubeconfig -> ingress-nginx -> metrics-server -> monitoring -> ArgoCD (deploys the app)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="${CLUSTER_NAME:-stockpilot-eks}"

echo "==> kubeconfig"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"
kubectl get nodes

echo "==> namespace"
kubectl apply -f "$ROOT/k8s/namespace.yaml"

echo "==> ingress-nginx (creates an AWS load balancer)"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer --wait --timeout 5m

echo "==> metrics-server (needed by the HPA)"
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --wait

echo "==> Prometheus + Grafana"
"$ROOT/monitoring/install.sh"

echo "==> ArgoCD + StockPilot application"
"$ROOT/argocd/install.sh" eks

echo
echo "Waiting for the ingress load balancer hostname ..."
for i in $(seq 1 30); do
  LB=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  [ -n "$LB" ] && break; sleep 10
done
echo "App URL: http://${LB:-<pending>}/"
