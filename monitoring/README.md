# monitoring/ — Prometheus + Grafana

| File | Purpose |
|---|---|
| `kube-prometheus-stack-values.yaml` | Helm values: Prometheus scrapes every `ServiceMonitor`, Grafana with dashboard sidecar |
| `grafana-dashboard.json` | StockPilot dashboard: request rate, latency percentiles, error rate, status codes, pod CPU |
| `install.sh` | One-shot install + dashboard ConfigMap |

The backend exposes `/metrics` through `prometheus-fastapi-instrumentator`. The Helm chart ships a
`ServiceMonitor` (label `release: kube-prometheus-stack`) that tells the Prometheus Operator to scrape
the `backend` Service on port `http` every 15 s.

```bash
./monitoring/install.sh
./scripts/load-test.sh http://<ingress-host>      # generate traffic for the panels
```
