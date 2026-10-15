# ---------------------------------------------------------------
# EKS cluster with one managed node group + EBS CSI driver (for PVCs)
# ---------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # Keep the demo cluster lean: no KMS envelope encryption key, no control-plane log group
  create_kms_key              = false
  cluster_encryption_config   = {}
  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []

  # The account's organization policy blocks IAM OIDC providers, so IRSA is disabled and
  # the EBS CSI driver gets its permissions from the node IAM role instead.
  enable_irsa = false

  cluster_addons = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  eks_managed_node_groups = {
    main = {
      name           = "${var.project}-nodes"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      disk_size      = 30
      labels = {
        role = "worker"
      }
      # Lets the EBS CSI driver (running on these nodes) create/attach volumes for PVCs
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}
