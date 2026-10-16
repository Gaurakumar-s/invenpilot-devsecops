#!/usr/bin/env bash
# Generate HTTP traffic so Prometheus/Grafana panels (and the HPA) have data.
#   ./scripts/load-test.sh http://<ingress-host> [requests=600]
#   HOST_HEADER=stockpilot.local ./scripts/load-test.sh http://127.0.0.1:8081   # minikube via port-forward
set -euo pipefail
BASE="${1:-http://localhost:8000}"
N="${2:-600}"
HDR=()
[ -n "${HOST_HEADER:-}" ] && HDR=(-H "Host: ${HOST_HEADER}")
echo "Sending $N rounds of requests to $BASE ${HOST_HEADER:+(Host: $HOST_HEADER)} ..."
for i in $(seq 1 "$N"); do
  curl -s -o /dev/null ${HDR[@]+"${HDR[@]}"} "$BASE/api/products" &
  curl -s -o /dev/null ${HDR[@]+"${HDR[@]}"} "$BASE/api/products/stats" &
  curl -s -o /dev/null ${HDR[@]+"${HDR[@]}"} "$BASE/api/movements?limit=5" &
  curl -s -o /dev/null ${HDR[@]+"${HDR[@]}"} "$BASE/api/products/99999" &   # 404s show up in the status-code panel
  if (( i % 25 == 0 )); then wait; echo "  $i / $N"; fi
done
wait
echo "Load test completed"
