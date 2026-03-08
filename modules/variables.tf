variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster (e.g., '1.29')"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and default node group placement"
  type        = list(string)
}

# -------------------------
# Cluster Endpoint Access
# -------------------------

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -------------------------
# Networking
# -------------------------

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs (e.g., '172.20.0.0/16')"
  type        = string
  default     = null
}

variable "ip_family" {
  description = "IP family used to assign Kubernetes pod and service addresses ('ipv4' or 'ipv6')"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "ipv6"], var.ip_family)
    error_message = "ip_family must be either 'ipv4' or 'ipv6'."
  }
}

# -------------------------
# Encryption & Logging
# -------------------------

variable "kms_key_arn" {
  description = "ARN of KMS key for encrypting Kubernetes secrets (optional)"
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  description = "List of control plane log types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
}

# -------------------------
# Managed Node Groups
# -------------------------

variable "managed_node_groups" {
  description = <<-EOT
    Map of managed node group configurations. Each key is the node group name.

    Supported attributes per node group:
      - subnet_ids              (list)   : Override subnet IDs for this node group
      - ami_type                (string) : AMI type, e.g. AL2_x86_64, AL2_ARM_64, BOTTLEROCKET_x86_64
      - capacity_type           (string) : ON_DEMAND or SPOT
      - disk_size               (number) : Root volume size in GiB
      - instance_types          (list)   : List of EC2 instance types
      - desired_size            (number) : Desired number of nodes
      - min_size                (number) : Minimum number of nodes
      - max_size                (number) : Maximum number of nodes
      - max_unavailable         (number) : Max nodes unavailable during update (absolute)
      - max_unavailable_percentage (number) : Max nodes unavailable during update (percentage)
      - kubernetes_version      (string) : Kubernetes version override
      - release_version         (string) : AMI release version override
      - labels                  (map)    : Kubernetes labels
      - taints                  (list)   : List of {key, value, effect} taint objects
      - ec2_ssh_key             (string) : EC2 key pair name for SSH access
      - source_security_group_ids (list) : SGs allowed to SSH into nodes
      - launch_template_id      (string) : Custom launch template ID
      - launch_template_version (string) : Launch template version (default: $Latest)
      - tags                    (map)    : Additional AWS tags
  EOT
  type        = any
  default     = {}
}

# -------------------------
# Addons
# -------------------------

variable "cluster_addons" {
  description = <<-EOT
    Map of EKS add-on configurations. Key is the add-on name.

    Supported attributes:
      - addon_version              (string) : Version of the add-on
      - resolve_conflicts          (string) : OVERWRITE or NONE
      - service_account_role_arn   (string) : IAM role ARN for IRSA
  EOT
  type        = any
  default = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }
}

# -------------------------
# Access Entries (EKS Access Management)
# -------------------------

variable "access_entries" {
  description = <<-EOT
    Map of EKS access entries for granting IAM principals access to the cluster.

    Supported attributes:
      - principal_arn      (string, required) : IAM role or user ARN
      - kubernetes_groups  (list)             : Kubernetes RBAC groups
      - type               (string)           : STANDARD, EC2_LINUX, EC2_WINDOWS, FARGATE_LINUX
      - policy_arn         (string)           : EKS access policy ARN (e.g. AmazonEKSClusterAdminPolicy)
      - access_scope_type  (string)           : cluster or namespace
      - namespaces         (list)             : Namespaces for namespace-scoped policies
  EOT
  type        = any
  default     = {}
}

# -------------------------
# Misc
# -------------------------

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore policy to node group role for SSM Session Manager access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
