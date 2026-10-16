#!/usr/bin/env bash
# Local rehearsal of the full Kubernetes stack on minikube.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

minikube status >/dev/null 2>&1 || minikube start --cpus 4 --memory 6g --driver docker
minikube addons enable ingress
minikube addons enable metrics-server
kubectl apply -f "$ROOT/k8s/namespace.yaml"
"$ROOT/monitoring/install.sh"
helm upgrade --install invenpilot "$ROOT/helm/invenpilot" -n invenpilot \
  -f "$ROOT/helm/invenpilot/values-minikube.yaml" --wait --timeout 5m
echo
echo "Add to /etc/hosts:   $(minikube ip)  invenpilot.local"
echo "Then open http://invenpilot.local/   (on macOS/docker driver use: minikube tunnel + 127.0.0.1)"
