#!/usr/bin/env bash
# Install Prometheus + Grafana (kube-prometheus-stack) and load the InvenPilot dashboard.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f "$DIR/kube-prometheus-stack-values.yaml" \
  --wait --timeout 10m

# Grafana sidecar picks up any ConfigMap labelled grafana_dashboard=1
kubectl create configmap invenpilot-dashboard -n monitoring \
  --from-file=invenpilot.json="$DIR/grafana-dashboard.json" \
  --dry-run=client -o yaml \
  | kubectl label --local -f - grafana_dashboard=1 -o yaml \
  | kubectl apply -f -

echo
echo "Prometheus: kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090  -> http://localhost:9090/targets"
echo "Grafana:    kubectl port-forward svc/kube-prometheus-stack-grafana   -n monitoring 3001:80    -> http://localhost:3001 (admin / invenpilot-admin)"
