# Demo runbook — AWS day + video recording

> **Status 15 Oct 2026:** the full AWS run (steps 1–4, 8, 9) was executed and verified; the cluster was then
> destroyed (53 resources, AWS checked clean). To record the video, rebuild with steps 1–2 (≈25 min), record,
> then destroy again with step 9. The ArgoCD admin password is printed by
> `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`.

Everything below is copy-paste. Budget: ~2 hours including the recording. Cost ≈ $0.35/hour while
the EKS cluster exists. Region is **ap-southeast-2 (Sydney)**: the account's organization policy allows no other region; **destroy it at the end (step 9)**.

## 0. One-time prerequisites (10 min)

```bash
# AWS CLI is installed; configure an IAM user that has AdministratorAccess
aws configure            # Access key, secret, region: ap-southeast-2, output: json
aws sts get-caller-identity   # must print your account id

# (DONE on 15 Oct) Both GHCR packages are PUBLIC so the cluster pulls them without a secret:
#   https://github.com/users/Gaurakumar-s/packages/container/stockpilot-backend/settings
#   https://github.com/users/Gaurakumar-s/packages/container/stockpilot-frontend/settings
#   -> "Change visibility" -> Public
#   then screenshot https://github.com/Gaurakumar-s/stockpilot-devsecops/pkgs/container/stockpilot-backend
#   (shows the SHA tags) -> docs/screenshots/10-ghcr-packages-sha.png
```

## 1. Terraform — create VPC + EKS (≈ 15 min)

```bash
cd ~/Downloads/DEVOPS_CAPSTONE/terraform
terraform init
terraform validate
terraform plan -out tfplan            # screenshot 12-terraform-plan.png
terraform apply tfplan                # screenshot 12b-terraform-apply.png when it finishes
```

AWS Console screenshots (region **ap-southeast-2**, the only region your AWS organization allows):
* VPC → Your VPCs → `stockpilot-vpc` and Subnets (2 public + 2 private) → `13-aws-vpc.png`
* EKS → Clusters → `stockpilot-eks` → Compute tab (node group) → `14-aws-eks.png`

## 2. Bootstrap the cluster (≈ 10 min)

```bash
cd ~/Downloads/DEVOPS_CAPSTONE
./scripts/eks-bootstrap.sh
# installs: kubeconfig, ingress-nginx (AWS ELB), metrics-server, Prometheus+Grafana, ArgoCD + Application
# prints the ArgoCD admin password and the app URL (ELB hostname)
```

Wait until everything is Running:

```bash
kubectl get pods -n stockpilot            # 2 backend, 2 frontend, 1 postgres  -> 16-kubectl-get-pods.png
kubectl get svc -n stockpilot             # -> 17-kubectl-get-svc.png
kubectl get ingress -n stockpilot         # ADDRESS = ELB hostname
helm list -n stockpilot                   # -> 18-helm-list.png  (release managed by ArgoCD)
kubectl get hpa -n stockpilot             # -> 24-kubectl-get-hpa.png
```

Open `http://<ELB hostname>/` in the browser → `19-app-via-ingress.png`. Seed data:

```bash
./scripts/seed.sh http://<ELB hostname>
```

## 3. ArgoCD (GitOps)

```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
# https://localhost:8443  user admin / password printed by the bootstrap script
```
Show the `stockpilot` application **Synced / Healthy** → `23-argocd-synced.png`.

## 4. Prometheus + Grafana

```bash
./scripts/load-test.sh http://<ELB hostname> 600        # traffic for the panels
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
#   http://localhost:9090/targets?search=stockpilot  -> backend endpoints UP -> 21-prometheus-targets-up.png
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3001:80
#   http://localhost:3001  (admin / stockpilot-admin) -> Dashboards -> "StockPilot — Application Metrics"
#   -> 22-grafana-dashboard.png
kubectl port-forward svc/backend -n stockpilot 8000:8000 ; curl localhost:8000/metrics | head -40   # 20-curl-metrics.png
```

## 5. CI/CD live demo (for the video)

```bash
# make a visible change, e.g. edit the subtitle in frontend/src/App.jsx, then:
git commit -am "feat(frontend): tweak dashboard subtitle for demo" && git push
gh run watch            # or open https://github.com/Gaurakumar-s/stockpilot-devsecops/actions
```
Show: 4 green jobs → GHCR package page with the new SHA tag → the bot commit
`chore(gitops): deploy image …` → ArgoCD syncs → `kubectl get pods -n stockpilot` rolls new pods.

## 6. Record the video (12–18 min, QuickTime: File → New Screen Recording)

Order required by the rubric:
1. Slides (`demo/slides.pptx`) — what you built, architecture (2–3 min)
2. Codebase tour — backend/app, tests, Dockerfiles, workflow, helm, terraform (2 min)
3. CI/CD — push a commit, show the Actions run end-to-end, GHCR tags (3 min)
4. Terraform — `terraform plan` output + AWS console VPC & EKS (2 min)
5. ArgoCD — synced application, explain the GitOps flow (1 min)
6. Kubernetes — `kubectl get pods / svc / ingress`, app in browser via the ELB (2 min)
7. Prometheus Targets page UP (1 min)
8. Grafana dashboard with live panels (1 min)
9. Bonus: `kubectl get hpa`, troubleshooting a broken image (1 min)

## 7. Compress and add the video

```bash
ffmpeg -i ~/Desktop/recording.mov -vf scale=1280:-2 -c:v libx264 -crf 28 -preset slow -c:a aac -b:a 96k demo/presentation.mp4
ls -lh demo/presentation.mp4         # must be < 100 MB for a normal git commit
git add demo/presentation.mp4 && git commit -m "docs(demo): add presentation walkthrough video" && git push
```
If it is still > 100 MB:
```bash
gh release create v1.0.0-demo demo/presentation.mp4 --title "Capstone demo" --notes "Presentation video"
```
and put the release link in `demo/README.md`.

## 8. Commit the screenshots

```bash
git add docs/screenshots && git commit -m "docs: add AWS, ArgoCD and EKS evidence screenshots" && git push
```

## 9. DESTROY (mandatory)

```bash
helm uninstall ingress-nginx -n ingress-nginx     # frees the ELB so the VPC can be deleted
cd terraform && terraform destroy -auto-approve   # screenshot 15-terraform-destroy.png
```
Check the AWS console: EC2 → Load Balancers empty, EKS → no clusters, VPC → no stockpilot-vpc.

## 10. Submit

Form: https://forms.gle/XWAP1vAumDJgAPM1A → repo URL `https://github.com/Gaurakumar-s/stockpilot-devsecops`
