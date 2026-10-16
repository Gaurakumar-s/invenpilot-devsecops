# Video script — what to show and what to say

Target length: 12–15 minutes. Speak slowly. Read the **Say** lines; run the **Show** commands in Terminal.
Before you start: ask Claude to "start the cluster" (≈25 min), wait for the app URL and ArgoCD password.

## Setup (before recording)

1. Open these in browser tabs: GitHub repo, GitHub Actions page, GHCR package page, AWS Console (region Sydney) → VPC and EKS pages, the app URL.
2. Open Terminal in the project folder: `cd ~/Downloads/DEVOPS_CAPSTONE`.
3. Open `demo/slides.pptx` in PowerPoint, full screen.
4. QuickTime → File → New Screen Recording → select the whole screen → Record.

---

## Part 1 — Slides (3 min)

**Show:** slides 1 to 10, about 15 seconds each.

**Say:**
> "Hi, I am Gaurav Kumar. This is my DevSecOps capstone project, StockPilot.
> StockPilot is an inventory management app. A warehouse can add products, record stock in and stock out, and see low-stock alerts on a dashboard.
> The app is React on the frontend, FastAPI on the backend, and PostgreSQL as the database.
> The real goal of the project is the DevOps path: every commit is tested, built into Docker images, scanned by Trivy, pushed to GitHub Container Registry, and then deployed to Kubernetes on AWS by ArgoCD. Terraform creates the AWS infrastructure. Prometheus and Grafana monitor the app.
> Let me show each part live."

(On the architecture slide, point along the arrows from Developer → GitHub Actions → GHCR → ArgoCD → EKS.)

---

## Part 2 — Codebase (2 min)

**Show:** VS Code or Finder with the folder tree.

**Say:**
> "The repo has one folder per layer.
> `backend/app` is the FastAPI code: models, schemas and routers. `backend/alembic/versions` has two database migrations. `backend/tests` has 20 pytest tests that run on an in-memory SQLite database.
> `frontend/src` is the React dashboard.
> Both Dockerfiles run as non-root. The frontend Dockerfile is multi-stage: Node builds the app, then Nginx serves it.
> `.github/workflows/ci-cd.yml` is the pipeline. `terraform/` creates the AWS VPC and EKS. `helm/stockpilot` is the Kubernetes chart. `argocd/` is the GitOps application. `monitoring/` has the Prometheus and Grafana setup."

**Show (Terminal):**
```bash
cd backend && source .venv/bin/activate && pytest -q && cd ..
```
**Say:** "All 20 tests pass locally."

---

## Part 3 — CI/CD pipeline (3 min)

**Show (Terminal):** make a tiny change and push.
```bash
sed -i '' 's/Track stock levels, reorder alerts and movements in real time./Track stock levels, reorder alerts and movements in real time. Demo build./' frontend/src/App.jsx
git commit -am "feat(frontend): demo subtitle change for the walkthrough" && git push
```
Switch to the **GitHub Actions** tab and refresh.

**Say:**
> "I just pushed a commit. The pipeline starts automatically on every push to main.
> Job one runs ruff and pytest. If a test fails, the pipeline stops here and no image is built.
> Job two builds the React frontend.
> Job three builds both Docker images, scans them with Trivy, and fails if any HIGH or CRITICAL vulnerability is found. Only clean images are pushed to GitHub Container Registry. The image tag is the git commit SHA, never 'latest', so I can always trace a running container back to the exact commit.
> Job four writes the new tag into the Helm values file and commits it. That is the GitOps hand-off: the pipeline never touches the cluster."

While it runs (about 3 minutes), open the **GHCR package** tab:
**Say:** "Here are the images with SHA tags." Open the **Trivy step** log in the running job:
**Say:** "Trivy scanned the Debian and Alpine OS packages and the Python and npm libraries. Zero HIGH or CRITICAL findings. During development the first scan found a Starlette DoS CVE and old Alpine packages, and I fixed them by upgrading, so the gate has real value."

Come back when all four jobs are green.

---

## Part 4 — Terraform and AWS (2 min)

**Show (Terminal):**
```bash
cd terraform && terraform plan | tail -5 && cd ..
```
**Say:**
> "Terraform manages the infrastructure. The plan shows no changes because everything is already created.
> It builds a VPC with two public subnets for the load balancer and two private subnets for the worker nodes, a NAT gateway, and an EKS cluster with a managed node group of two nodes. The EBS CSI driver add-on lets Postgres get a persistent volume."

Switch to the **AWS Console** tabs: VPC page, then EKS cluster page, then Compute tab showing the node group.
**Say:** "Here is the VPC and here is the EKS cluster in the Sydney region with two nodes. I will destroy all of this after the demo with `terraform destroy`."

---

## Part 5 — ArgoCD (1.5 min)

**Show (Terminal):**
```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
```
Open https://localhost:8443 → login `admin` + password → click the `stockpilot` application.

**Say:**
> "ArgoCD watches the `helm/stockpilot` folder on the main branch. It is set to automatic sync with prune and self-heal.
> The application is Synced and Healthy. When the pipeline committed the new image tag a moment ago, ArgoCD saw the change and rolled out new pods. Git is the single source of truth for what runs in the cluster."

(Point at the commit SHA shown in ArgoCD and the pods in the tree view.)

---

## Part 6 — Kubernetes (2 min)

**Show (Terminal):**
```bash
kubectl get pods -n stockpilot
kubectl get svc -n stockpilot
kubectl get ingress -n stockpilot
kubectl get hpa -n stockpilot
helm list -n stockpilot
```
**Say:**
> "Two backend pods, two frontend pods and one Postgres pod, all Running.
> The services are ClusterIP; nothing is exposed directly.
> The Ingress sends `/api` to the backend and everything else to the frontend, through an AWS load balancer created by ingress-nginx.
> The HPA scales the backend between 2 and 6 pods on CPU.
> Helm lists the release, deployed from the same chart ArgoCD uses."

Switch to the **app URL** tab. Add a product, then record a stock-out on it.
**Say:** "This is the app running on EKS through the load balancer. I create a product and record a stock movement; the dashboard and the movement feed update live."

---

## Part 7 — Prometheus (1 min)

**Show (Terminal):**
```bash
./scripts/load-test.sh http://<APP-URL> 300
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
```
Open http://localhost:9090/targets?search=stockpilot

**Say:**
> "The backend exposes `/metrics` in Prometheus format. A ServiceMonitor tells the Prometheus Operator to scrape it every 15 seconds. Both backend pods show as UP."

---

## Part 8 — Grafana (1 min)

**Show (Terminal):**
```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3001:80
```
Open http://localhost:3001 → Dashboards → "StockPilot — Application Metrics".

**Say:**
> "This dashboard shows requests per second, latency percentiles, error rate, responses by status code, and backend CPU, which is the HPA input. The load test I just ran is visible here."

---

## Part 9 — Close (30 sec)

**Say:**
> "To summarise: a commit goes through tests, a security scan and a registry, then ArgoCD deploys it to an EKS cluster that Terraform created, and Prometheus and Grafana show it running.
> Key learnings: quality gates before promotion, immutable image tags for traceability, GitOps instead of manual kubectl, and always destroying cloud resources when done.
> Thank you."

Stop the recording. Then tell Claude "destroy".

---

## After recording

```bash
ffmpeg -i ~/Desktop/recording.mov -vf scale=1280:-2 -c:v libx264 -crf 28 -preset slow -c:a aac -b:a 96k demo/presentation.mp4
ls -lh demo/presentation.mp4     # must be under 100 MB
git add demo/presentation.mp4 docs/screenshots && git commit -m "docs(demo): add presentation video and console screenshots" && git push
```
Submit the form: https://forms.gle/XWAP1vAumDJgAPM1A
