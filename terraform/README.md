# terraform/ — AWS VPC + EKS

Provisions the production-style infrastructure for StockPilot:

| Resource | Details |
|---|---|
| VPC | `10.20.0.0/16`, 2 AZs (`ap-south-1a`, `ap-south-1b`) |
| Public subnets ×2 | ingress-nginx LoadBalancer (tagged `kubernetes.io/role/elb`) |
| Private subnets ×2 | EKS worker nodes, egress via a single NAT gateway |
| EKS | Kubernetes `1.34`, public API endpoint, creator gets admin |
| Managed node group | `t3.medium` × 2 (min 2 / max 3), Amazon Linux 2023 |
| Add-ons | coredns, kube-proxy, vpc-cni, **aws-ebs-csi-driver** (IRSA) so PVCs bind |

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # optional overrides
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan                           # ~15 minutes
aws eks update-kubeconfig --region ap-south-1 --name stockpilot-eks
kubectl get nodes
```

## Destroy (always, after the demo)

```bash
terraform destroy -auto-approve
```

> Cost ≈ $0.10/h (EKS control plane) + ~$0.08/h (2 × t3.medium) + ~$0.05/h (NAT) ≈ **$0.25/hour**.
> Delete the ingress-nginx LoadBalancer Service (`helm uninstall ingress-nginx -n ingress-nginx`)
> **before** `terraform destroy`, otherwise the ELB keeps the VPC from being deleted.

Credentials are read from the AWS CLI profile / environment only. Nothing secret is committed.
