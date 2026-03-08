# ============================================================
# AWS EKS Module - Main Configuration
# ============================================================

locals {
  cluster_name = var.cluster_name
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      ManagedBy                                     = "Terraform"
    }
  )
}

# ============================================================
# IAM Role - EKS Cluster
# ============================================================

resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ============================================================
# IAM Role - Managed Node Group
# ============================================================

resource "aws_iam_role" "node_group" {
  name = "${local.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  count      = var.enable_ssm ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# ============================================================
# Security Groups
# ============================================================

resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.cluster_name}-cluster-sg" })
}

resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow nodes to communicate with the cluster API"
}

resource "aws_security_group" "node_group" {
  name        = "${local.cluster_name}-node-sg"
  description = "EKS managed node group security group"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name                                          = "${local.cluster_name}-node-sg"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
  )
}

resource "aws_security_group_rule" "node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node_group.id
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "node_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow cluster to communicate with nodes"
}

# ============================================================
# CloudWatch Log Group
# ============================================================

resource "aws_cloudwatch_log_group" "cluster" {
  count             = length(var.cluster_enabled_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

# ============================================================
# EKS Cluster
# ============================================================

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : []
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = var.service_ipv4_cidr != null ? [1] : []
    content {
      service_ipv4_cidr = var.service_ipv4_cidr
      ip_family         = var.ip_family
    }
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ============================================================
# EKS Managed Node Groups
# ============================================================

resource "aws_eks_node_group" "this" {
  for_each = var.managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = lookup(each.value, "subnet_ids", var.subnet_ids)

  ami_type        = lookup(each.value, "ami_type", "AL2_x86_64")
  capacity_type   = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size       = lookup(each.value, "disk_size", 20)
  instance_types  = lookup(each.value, "instance_types", ["t3.medium"])
  release_version = lookup(each.value, "release_version", null)
  version         = lookup(each.value, "kubernetes_version", null)

  scaling_config {
    desired_size = lookup(each.value, "desired_size", 2)
    min_size     = lookup(each.value, "min_size", 1)
    max_size     = lookup(each.value, "max_size", 4)
  }

  dynamic "update_config" {
    for_each = lookup(each.value, "max_unavailable", null) != null || lookup(each.value, "max_unavailable_percentage", null) != null ? [1] : []
    content {
      max_unavailable            = lookup(each.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(each.value, "max_unavailable_percentage", null)
    }
  }

  dynamic "launch_template" {
    for_each = lookup(each.value, "launch_template_id", null) != null ? [1] : []
    content {
      id      = each.value.launch_template_id
      version = lookup(each.value, "launch_template_version", "$Latest")
    }
  }

  dynamic "remote_access" {
    for_each = lookup(each.value, "ec2_ssh_key", null) != null ? [1] : []
    content {
      ec2_ssh_key               = each.value.ec2_ssh_key
      source_security_group_ids = lookup(each.value, "source_security_group_ids", [])
    }
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value", null)
      effect = taint.value.effect
    }
  }

  labels = lookup(each.value, "labels", {})

  tags = merge(
    local.tags,
    lookup(each.value, "tags", {}),
    { Name = "${local.cluster_name}-${each.key}" }
  )

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ============================================================
# EKS Add-ons
# ============================================================

resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = lookup(each.value, "addon_version", null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  tags = local.tags

  depends_on = [aws_eks_node_group.this]
}

# ============================================================
# aws-auth ConfigMap (optional)
# ============================================================

resource "aws_eks_access_entry" "additional_roles" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = lookup(each.value, "kubernetes_groups", [])
  type              = lookup(each.value, "type", "STANDARD")

  tags = local.tags

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "additional_roles" {
  for_each = {
    for k, v in var.access_entries : k => v
    if lookup(v, "policy_arn", null) != null
  }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = lookup(each.value, "access_scope_type", "cluster")
    namespaces = lookup(each.value, "namespaces", [])
  }

  depends_on = [aws_eks_access_entry.additional_roles]
}
