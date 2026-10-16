#!/usr/bin/env bash
# Local rehearsal of the full Kubernetes stack on minikube.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

minikube status >/dev/null 2>&1 || minikube start --cpus 4 --memory 6g --driver docker
minikube addons enable ingress
minikube addons enable metrics-server
kubectl apply -f "$ROOT/k8s/namespace.yaml"
"$ROOT/monitoring/install.sh"
helm upgrade --install stockpilot "$ROOT/helm/stockpilot" -n stockpilot \
  -f "$ROOT/helm/stockpilot/values-minikube.yaml" --wait --timeout 5m
echo
echo "Add to /etc/hosts:   $(minikube ip)  stockpilot.local"
echo "Then open http://stockpilot.local/   (on macOS/docker driver use: minikube tunnel + 127.0.0.1)"
