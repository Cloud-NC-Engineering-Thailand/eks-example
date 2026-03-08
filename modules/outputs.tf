# ============================================================
# AWS EKS Module - Outputs
# ============================================================

# -------------------------
# Cluster
# -------------------------

output "cluster_id" {
  description = "Name/ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the cluster CA"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster (use for IRSA)"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.this.status
}

# -------------------------
# Security Groups
# -------------------------

output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "ID of the EKS node group security group"
  value       = aws_security_group.node_group.id
}

# -------------------------
# IAM
# -------------------------

output "cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.node_group.name
}

# -------------------------
# Managed Node Groups
# -------------------------

output "managed_node_groups" {
  description = "Map of all managed node group attributes"
  value       = aws_eks_node_group.this
}

output "managed_node_group_arns" {
  description = "Map of managed node group names to their ARNs"
  value       = { for k, v in aws_eks_node_group.this : k => v.arn }
}

output "managed_node_group_statuses" {
  description = "Map of managed node group names to their current status"
  value       = { for k, v in aws_eks_node_group.this : k => v.status }
}

# -------------------------
# Add-ons
# -------------------------

output "cluster_addons" {
  description = "Map of installed EKS add-ons and their attributes"
  value       = aws_eks_addon.this
}

# -------------------------
# kubectl / kubeconfig helpers
# -------------------------

output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for this cluster"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.this.name}"
}
