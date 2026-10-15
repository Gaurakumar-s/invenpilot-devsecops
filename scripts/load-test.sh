#!/usr/bin/env bash
# Generate HTTP traffic so Prometheus/Grafana panels (and the HPA) have data.
#   ./scripts/load-test.sh http://<ingress-host> [requests=600]
set -euo pipefail
BASE="${1:-http://localhost:8000}"
N="${2:-600}"
echo "Sending $N requests to $BASE ..."
for i in $(seq 1 "$N"); do
  curl -s -o /dev/null "$BASE/api/products" &
  curl -s -o /dev/null "$BASE/api/products/stats" &
  curl -s -o /dev/null "$BASE/api/movements?limit=5" &
  curl -s -o /dev/null "$BASE/api/products/99999" &   # 404s show up in status-code panel
  if (( i % 25 == 0 )); then wait; echo "  $i / $N"; fi
done
wait
echo "Load test completed"
