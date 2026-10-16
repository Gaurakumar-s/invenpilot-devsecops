variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  description = "Project name used for resource naming and tags"
  type        = string
  default     = "invenpilot"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones (two required for EKS)"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs (one per AZ) — host the ingress load balancer"
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs (one per AZ) — host the EKS worker nodes"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "invenpilot-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS (keep inside AWS standard support to avoid extended-support fees)"
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group (must be free-tier eligible on the AWS free plan)"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 2 # account vCPU quota is 5; 2 x t3.medium = 4 vCPUs
}

variable "node_desired_size" {
  type    = number
  default = 2
}
