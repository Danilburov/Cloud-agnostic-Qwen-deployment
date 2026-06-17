# ============================================================
# General
# ============================================================

variable "location" {
  description = "Azure region where all resources are deployed. germanywestcentral mirrors AWS eu-central-1 (Frankfurt)."
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Deployment environment name. Used in tags and for environment-specific configuration."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Short identifier used as a prefix for all resource names."
  type        = string
  default     = "sue"
}

variable "tags" {
  description = "Common tags applied to every resource. Merged with per-resource Name tags via merge()."
  type        = map(string)
  default = {
    Project   = "qwen-kserve"
    ManagedBy = "terraform"
  }
}

# ============================================================
# Resource Group
# ============================================================

variable "resource_group_name" {
  description = "Name of the Azure Resource Group that contains all project resources."
  type        = string
  default     = "sue-resource-group"
}

# ============================================================
# Networking — VNet
# ============================================================

variable "vnet_name" {
  description = "Name of the Virtual Network. Azure equivalent of an AWS VPC."
  type        = string
  default     = "sue-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the VNet. Must not overlap with service_cidr or pod_cidr."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "node_subnet_name" {
  description = "Name of the subnet used for AKS node pools. Equivalent to AWS private subnets."
  type        = string
  default     = "sue-nodes-subnet"
}

variable "node_subnet_address_prefix" {
  description = "CIDR block for the AKS node subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_name" {
  description = "Name of the public-facing subnet for ingress controllers and Azure Load Balancers. Equivalent to AWS public subnets."
  type        = string
  default     = "sue-public-subnet"
}

variable "public_subnet_address_prefix" {
  description = "CIDR block for the public ingress subnet."
  type        = string
  default     = "10.0.101.0/24"
}

# ============================================================
# Networking — NSG (equivalent to AWS Security Groups)
# ============================================================

variable "nsg_node_name" {
  description = "Name of the NSG attached to the node subnet. Equivalent to the AWS eks_nodes_sg."
  type        = string
  default     = "sue-nsg-nodes"
}

variable "nsg_public_name" {
  description = "Name of the NSG attached to the public/ingress subnet. Equivalent to the AWS eks_cluster_sg."
  type        = string
  default     = "sue-nsg-public"
}

variable "allowed_https_cidr_blocks" {
  description = "CIDR blocks permitted to reach the AKS API server and ingress on port 443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks permitted to reach ingress on port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================================
# AKS — Cluster
# ============================================================

variable "cluster_name" {
  description = "Name of the AKS cluster. Equivalent to the AWS EKS cluster_name."
  type        = string
  default     = "sue-aks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS control plane and default node pool."
  type        = string
  default     = "1.32"
}

variable "dns_prefix" {
  description = "DNS prefix prepended to the AKS API server FQDN. Must be unique within the region."
  type        = string
  default     = "sue-aks"
}

variable "private_cluster_enabled" {
  description = "When true, the AKS API server is only reachable via private endpoint. Equivalent to EKS endpoint_private_access=true + endpoint_public_access=false."
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "AKS control-plane SLA tier. Free has no SLA; Standard gives 99.95%; Premium gives 99.99%."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of: Free, Standard, Premium."
  }
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin access. Equivalent to AWS EKS access entries with AmazonEKSClusterAdminPolicy."
  type        = list(string)
  default     = []
}

variable "local_account_disabled" {
  description = "Disable the local Kubernetes admin account when Azure AD integration is active. Recommended for production."
  type        = bool
  default     = false
}

variable "azure_rbac_enabled" {
  description = "Use Azure RBAC for Kubernetes authorization so Azure AD groups control cluster access instead of Kubernetes RBAC role bindings."
  type        = bool
  default     = true
}

# ============================================================
# AKS — Default Node Pool
# ============================================================

variable "default_node_pool_name" {
  description = "Name of the default AKS system node pool. Must be lowercase alphanumeric, max 12 chars."
  type        = string
  default     = "systempool"
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool nodes. Standard_NV6 provides a GPU for LLM inference."
  type        = string
  default     = "Standard_NV6"
}

variable "default_node_pool_node_count" {
  description = "Initial desired node count. Ignored when enable_auto_scaling is true (min_count is used instead)."
  type        = number
  default     = 1
}

variable "default_node_pool_min_count" {
  description = "Minimum node count for the cluster auto-scaler. Only used when enable_auto_scaling = true."
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "Maximum node count for the cluster auto-scaler. Equivalent to EKS scaling_config max_size."
  type        = number
  default     = 4
}

variable "default_node_pool_os_disk_size_gb" {
  description = "OS disk size in GiB for each node. Equivalent to EKS disk_size."
  type        = number
  default     = 50
}

variable "default_node_pool_os_disk_type" {
  description = "OS disk type. Managed is a standard persistent disk; Ephemeral uses the VM's local cache disk for lower latency."
  type        = string
  default     = "Managed"

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.default_node_pool_os_disk_type)
    error_message = "os_disk_type must be Managed or Ephemeral."
  }
}

variable "default_node_pool_max_pods" {
  description = "Maximum number of pods schedulable on a single node."
  type        = number
  default     = 30
}

variable "enable_auto_scaling" {
  description = "Enable the cluster auto-scaler on the default node pool. Equivalent to EKS scaling_config."
  type        = bool
  default     = true
}

variable "node_labels" {
  description = "Kubernetes labels applied to every node in the default pool."
  type        = map(string)
  default = {
    workload = "llm"
  }
}

# ============================================================
# AKS — Network Profile
# ============================================================

variable "network_plugin" {
  description = "CNI plugin. kubenet: pods get IPs from pod_cidr (simpler). azure: pods get VNet IPs (more IPs needed in subnet)."
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure", "none"], var.network_plugin)
    error_message = "network_plugin must be kubenet, azure, or none."
  }
}

variable "network_policy" {
  description = "Network policy engine for pod-to-pod traffic control. calico works with both kubenet and azure plugin."
  type        = string
  default     = "calico"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes ClusterIP services. Must not overlap with vnet_address_space or pod_cidr."
  type        = string
  default     = "10.96.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address within service_cidr assigned to the kube-dns service."
  type        = string
  default     = "10.96.0.10"
}

variable "pod_cidr" {
  description = "CIDR for pod IPs when network_plugin = kubenet. Unused when network_plugin = azure."
  type        = string
  default     = "10.244.0.0/16"
}

variable "outbound_type" {
  description = "Outbound routing for nodes. loadBalancer is the default. Use userDefinedRouting if you attach a NAT Gateway or NVA."
  type        = string
  default     = "loadBalancer"
}

variable "load_balancer_sku" {
  description = "Azure Load Balancer SKU. Standard is required for production (zone redundancy, higher connection limits)."
  type        = string
  default     = "standard"
}

# ============================================================
# AKS — Identity (equivalent to AWS IAM roles in iam.tf)
# ============================================================

variable "identity_name" {
  description = "Name of the User Assigned Managed Identity that the AKS control plane uses to manage Azure resources. Equivalent to the AWS eks_cluster_role."
  type        = string
  default     = "sue-aks-identity"
}

# ============================================================
# AKS — Security & Features
# ============================================================

variable "oidc_issuer_enabled" {
  description = "Expose an OIDC issuer URL on the cluster. Required for Workload Identity. Equivalent to the AWS OIDC provider created in iam.tf."
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable the Workload Identity webhook so pods can exchange a Kubernetes service-account token for an Azure AD token without storing credentials."
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable the Azure Policy add-on for in-cluster Gatekeeper policy enforcement."
  type        = bool
  default     = false
}

# ============================================================
# Monitoring
# ============================================================

variable "enable_oms_agent" {
  description = "Enable the OMS agent add-on to ship container metrics and logs to Azure Monitor."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of an existing Log Analytics workspace. Required when enable_oms_agent = true."
  type        = string
  default     = ""
}
