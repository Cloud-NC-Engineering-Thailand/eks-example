# ============================================================
# EKS Module - Usage Example
# ============================================================
# This example shows a production-ready cluster setup with:
#   - Two managed node groups (general + spot)
#   - Private + public endpoint access
#   - SSM access enabled
#   - KMS encryption for secrets
#   - Core add-ons: coredns, kube-proxy, vpc-cni
#   - Access entry for a CI/CD role
# ============================================================
# ---- VPC (simplified; use your own or terraform-aws-modules/vpc) ----


# ---- KMS key for secret encryption (optional) ----

data "aws_iam_policy_document" "eks_kms_policy" {
  # Allow the account root full control (required so the key is manageable)
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }

  # Allow CloudWatch Logs to encrypt/decrypt log data with this key
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.us-east-1.amazonaws.com"]
    }
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  # Allow EKS to use the key for secrets encryption
  statement {
    sid    = "AllowEKSSecrets"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks" {
  description             = "EKS cluster secrets encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.eks_kms_policy.json
}

# ---- EKS Cluster ----

module "eks" {
  source = "./modules" # path to this module

  cluster_name       = "demoee-eks-cluster"
  kubernetes_version = "1.35"

  vpc_id     = "vpc-0be8712956540335d"
  subnet_ids = ["subnet-03a40bf96965ab302", "subnet-016c7f39547793c79"]

  # Endpoint access
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"] # restrict to your office IPs in production

  # Encryption
  kms_key_arn = aws_kms_key.eks.arn

  # SSM access on nodes
  enable_ssm = true

  # Control plane logging
  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_retention_days = 30

  # ---- Managed Node Groups ----
  managed_node_groups = {

    # General-purpose node group (On-Demand)
    general2 = {
      ami_type       = "BOTTLEROCKET_x86_64"
      capacity_type  = "ON_DEMAND"
      instance_types = ["c7i-flex.large"]
      disk_size      = 50

      desired_size = 3
      min_size     = 1
      max_size     = 6

      max_unavailable_percentage = 25

      labels = {
        role = "general"
        env  = "production"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"           = "true"
        "k8s.io/cluster-autoscaler/emoee-eks-cluster" = "owned"
      }
    }
  }
  # ---- EKS Add-ons ----
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
    Project     = "demoee"
  }
}
