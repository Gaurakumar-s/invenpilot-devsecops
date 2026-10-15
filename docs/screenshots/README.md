# Evidence screenshots — mapped to the grading rubric

Files ending in `-eks` were captured on the real AWS EKS cluster (ap-southeast-2); files ending in
`-minikube` come from the local rehearsal. CLI-rendered captures (`-cli`) are AWS CLI output for the
same resources shown in the console.

| Module | File | What it shows |
|---|---|---|
| M1 Application | `01-app-browser.png`, `01b-app-mobile.png` | Dashboard with live data (desktop + mobile layout) |
| M2 Testing | `02-pytest-v.png` | `pytest -v`: 20 passed, in-memory SQLite |
| M3 Git | `03-commit-history.png` | Conventional commit history |
| M4 Docker | `04-compose-up.png`, `05-localhost-3000.png` | `docker compose up --build`, three services healthy, app at :3000 |
| M5 CI/CD | `09-actions-green.png`, `09b-actions-list.png` | Green pipeline: test → build → Trivy → GHCR push → GitOps bump |
| M5 GHCR | `10-ghcr-packages-sha.png` | Package page with SHA tags |
| M6 Trivy | `11-trivy-local.png`, `11b-trivy-ci.png` | Clean scans locally and in the pipeline (HIGH/CRITICAL gate) |
| M7 Terraform | `12-terraform-plan.png`, `12b-terraform-apply.png`, `15-terraform-destroy.png` | plan (53 resources), apply with outputs, destroy |
| M7 AWS | `13-aws-vpc-cli.png`, `14-aws-eks-cli.png`, `13-aws-vpc.png`, `14-aws-eks.png` | VPC + 4 subnets + NAT, EKS cluster + node group + EC2 nodes (CLI and console) |
| M8 Kubernetes | `16-kubectl-get-pods-eks.png`, `17-kubectl-get-svc-ingress-eks.png`, `18-helm-list-eks.png`, `19-app-via-ingress-eks.png` (+ `-minikube` variants) | 2+2 replicas Running, ClusterIP services, Ingress routes `/` and `/api`, Helm release deployed, app via the AWS load balancer |
| M8 HPA | `24-kubectl-get-hpa-eks.png` (+ minikube) | HPA on backend CPU with metrics-server |
| ArgoCD | `23-argocd-synced-eks.png`, `23-argocd-synced.png`, `23b-argocd-app-cli.png`, `23c-argocd-ui.png` | Application Synced / Healthy, automated sync + prune + selfHeal; `23c` is the web UI captured during the demo |
| M9 Observability | `20-curl-metrics-eks.png`, `21-prometheus-targets-up-eks.png`, `22-grafana-dashboard-eks.png` (+ minikube) | `/metrics` output, Prometheus target UP (2/2), Grafana panels with live traffic |
