# Evidence screenshots — mapped to the grading rubric

| Module | File | What it shows |
|---|---|---|
| M1 Application | `01-app-browser.png`, `01b-app-mobile.png` | Dashboard with live data (desktop + mobile layout) |
| M2 Testing | `02-pytest-v.png` | `pytest -v`: 20 passed, in-memory SQLite |
| M3 Git | `03-commit-history.png` | Conventional commit history |
| M4 Docker | `04-compose-up.png`, `05-localhost-3000.png` | `docker compose up --build`, three services healthy, app at :3000 |
| M5 CI/CD | `09-actions-green.png`, `09b-actions-list.png` | Green pipeline: test → build → Trivy → GHCR push → GitOps bump |
| M5 GHCR | `10-ghcr-packages-sha.png` | Package page with SHA tags *(captured after packages are made public)* |
| M6 Trivy | `11-trivy-local.png`, `11b-trivy-ci.png` | Clean scans locally and in the pipeline (HIGH/CRITICAL gate) |
| M7 Terraform | `12-terraform-plan.png`, `12b-terraform-apply.png`, `13-aws-vpc.png`, `14-aws-eks.png`, `15-terraform-destroy.png` | *(captured on AWS day — see docs/DEMO-RUNBOOK.md)* |
| M8 Kubernetes | `16-kubectl-get-pods-minikube.png`, `17-kubectl-get-svc-ingress-minikube.png`, `18-helm-list-minikube.png`, `19-app-via-ingress-minikube.png` | 2+2 replicas Running, ClusterIP services, Ingress routes, app via Ingress (minikube rehearsal; EKS versions added on AWS day) |
| M8 HPA | `24-kubectl-get-hpa-minikube.png` | HPA on backend CPU |
| ArgoCD | `23-argocd-synced.png`, `23b-argocd-app-cli.png`, `23c-argocd-ui.png` | `argocd app get` + kubectl: Synced / Healthy, automated sync + prune + selfHeal (minikube); `23c` = ArgoCD web UI captured on AWS day |
| M9 Observability | `20-curl-metrics.png`, `21-prometheus-targets-up.png`, `22-grafana-dashboard.png` | `/metrics` output, Prometheus target UP (2/2), Grafana panels with live traffic |
