# AKS Cluster — equivalent to aws_eks_cluster.sue_eks + aws_eks_node_group.sue_eks_nodes
resource "azurerm_kubernetes_cluster" "sue_aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.sue_resource_group.location
  resource_group_name = azurerm_resource_group.sue_resource_group.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  private_cluster_enabled   = var.private_cluster_enabled
  sku_tier                  = var.sku_tier
  local_account_disabled    = var.local_account_disabled
  azure_policy_enabled      = var.enable_azure_policy
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  # Equivalent to aws_eks_node_group.sue_eks_nodes placed in private subnets
  default_node_pool {
    name       = var.default_node_pool_name
    vm_size    = var.default_node_pool_vm_size
    gpu_driver = "None"

    # When autoscaling is enabled, node_count must be null so AKS manages it via min/max
    node_count           = var.enable_auto_scaling ? null : var.default_node_pool_node_count
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count            = var.enable_auto_scaling ? var.default_node_pool_max_count : null

    os_disk_size_gb = var.default_node_pool_os_disk_size_gb
    os_disk_type    = var.default_node_pool_os_disk_type
    max_pods        = var.default_node_pool_max_pods

    # Place nodes in the private node subnet — same as EKS placing nodes in private subnets
    vnet_subnet_id = azurerm_subnet.sue_nodes_subnet.id

    node_labels = var.node_labels

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # UserAssigned identity — pre-provisioned in identity.tf so the Network Contributor
  # role is in place before AKS tries to create load balancers.
  # Equivalent to aws_iam_role.eks_cluster_role used by the EKS cluster.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sue_aks_identity.id]
  }

  # Equivalent to EKS VPC config + network plugin selection
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    pod_cidr          = var.network_plugin == "kubenet" ? var.pod_cidr : null
    outbound_type     = var.outbound_type
    load_balancer_sku = var.load_balancer_sku
  }

  # Azure AD-based cluster admin groups — equivalent to aws_eks_access_entry.admin_users
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = length(var.admin_group_object_ids) > 0 ? [1] : []
    content {
      admin_group_object_ids = var.admin_group_object_ids
      azure_rbac_enabled     = var.azure_rbac_enabled
    }
  }

  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags

  # Identity must have its role assignment before AKS provisions node pool NICs
  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
  ]
}
