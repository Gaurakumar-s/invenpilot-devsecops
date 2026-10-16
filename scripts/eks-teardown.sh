#!/usr/bin/env bash
# Tear down everything created for the demo, in the order that avoids dependency errors:
# app (frees the EBS volume) -> ingress-nginx (frees the ELB) -> leftover ENIs/SGs -> terraform destroy
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R="${AWS_REGION:-ap-southeast-2}"

echo "==> remove the application (ArgoCD + Helm) so the Postgres EBS volume is released"
kubectl delete application invenpilot -n argocd --timeout=180s 2>/dev/null || true
helm uninstall invenpilot -n invenpilot 2>/dev/null || true
kubectl delete pvc --all -n invenpilot --timeout=120s 2>/dev/null || true
for i in $(seq 1 30); do [ "$(kubectl get pv --no-headers 2>/dev/null | wc -l | tr -d ' ')" = "0" ] && break; sleep 5; done

echo "==> remove ingress-nginx so the AWS load balancer is deleted"
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
for i in $(seq 1 40); do
  N=$(aws elb describe-load-balancers --region "$R" --query 'length(LoadBalancerDescriptions)' --output text 2>/dev/null || echo 0)
  [ "$N" = "0" ] && break; sleep 10
done

echo "==> terraform destroy"
cd "$ROOT/terraform" && terraform destroy -input=false -auto-approve
if [ $? -ne 0 ]; then
  echo "==> destroy hit dependency errors; removing leftover network interfaces / k8s security groups and retrying"
  VPC=$(aws ec2 describe-vpcs --region "$R" --query 'Vpcs[?IsDefault==`false`].VpcId' --output text)
  for eni in $(aws ec2 describe-network-interfaces --region "$R" --filters Name=vpc-id,Values="$VPC" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text); do
    ATT=$(aws ec2 describe-network-interfaces --region "$R" --network-interface-ids "$eni" --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text)
    [ "$ATT" != "None" ] && aws ec2 detach-network-interface --region "$R" --attachment-id "$ATT" --force && sleep 8
    aws ec2 delete-network-interface --region "$R" --network-interface-id "$eni" && echo "deleted $eni"
  done
  for sg in $(aws ec2 describe-security-groups --region "$R" --filters Name=vpc-id,Values="$VPC" --query 'SecurityGroups[?starts_with(GroupName, `k8s-`)].GroupId' --output text); do
    aws ec2 delete-security-group --region "$R" --group-id "$sg" && echo "deleted $sg"
  done
  terraform destroy -input=false -auto-approve
fi

echo "==> leftovers check ($R)"
echo "EKS clusters: $(aws eks list-clusters --region "$R" --query 'length(clusters)' --output text)"
echo "VPCs (non-default): $(aws ec2 describe-vpcs --region "$R" --query 'length(Vpcs[?IsDefault==`false`])' --output text)"
echo "Instances: $(aws ec2 describe-instances --region "$R" --query 'length(Reservations[].Instances[?State.Name!=`terminated`][])' --output text)"
echo "NAT gateways: $(aws ec2 describe-nat-gateways --region "$R" --query 'length(NatGateways[?State!=`deleted`])' --output text)"
echo "Load balancers: $(aws elb describe-load-balancers --region "$R" --query 'length(LoadBalancerDescriptions)' --output text)"
echo "EBS volumes: $(aws ec2 describe-volumes --region "$R" --query 'length(Volumes)' --output text)"
