#!/usr/bin/env bash
# Install ArgoCD and register the StockPilot application.
#   ./argocd/install.sh eks       (default)
#   ./argocd/install.sh minikube
set -euo pipefail
TARGET="${1:-eks}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.13.3}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

if [ "$TARGET" = "minikube" ]; then
  kubectl apply -f "$(dirname "$0")/application-minikube.yaml"
else
  kubectl apply -f "$(dirname "$0")/application.yaml"
fi

echo
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo
echo "UI:  kubectl port-forward svc/argocd-server -n argocd 8443:443   ->  https://localhost:8443  (user: admin)"
