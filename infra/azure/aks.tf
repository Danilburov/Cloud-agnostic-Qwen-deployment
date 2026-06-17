# AKS Cluster
resource "azurerm_kubernetes_cluster" "sue_aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.35"

  # System node pool placed in private subnets
  default_node_pool {
    name                 = "system"
    node_count           = 1
    min_count            = 1
    max_count            = 4
    auto_scaling_enabled = true
    vm_size = "Standard_E16s_v5"
    os_disk_size_gb      = 50
    vnet_subnet_id       = azurerm_subnet.sue_subnet_private_1.id
    tags                 = var.tags

  }

  # SystemAssigned identity — works without IAM/Service Principal permissions.
  # TODO: if group account with broader perms becomes available, switch to:
  #   identity {
  #     type         = "UserAssigned"
  #     identity_ids = [azurerm_user_assigned_identity.sue_aks_identity.id]
  #   }
  # and reinstate identity.tf with Network Contributor + AcrPull role assignments.
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI so pods get VNet-native IPs — required for KServe/Istio
network_profile {
  network_plugin     = "azure"
  load_balancer_sku  = "standard"
  outbound_type      = "loadBalancer"
  service_cidr       = "10.1.0.0/16"
  dns_service_ip     = "10.1.0.10"
}


  tags = var.tags
}

# NSG for AKS nodes
resource "azurerm_network_security_group" "sue_aks_nodes_nsg" {
  name                = "${var.cluster_name}-nodes-nsg"
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name

  # Allow node-to-node — mirrors the "self" ingress rule
  security_rule {
    name                       = "allow-node-to-node"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow control plane → nodes on high ports
  security_rule {
    name                       = "allow-control-plane-to-nodes"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1025-65535"
    source_address_prefix      = "AzureCloud"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes-nsg" })
}

resource "azurerm_subnet_network_security_group_association" "private_1" {
  subnet_id                 = azurerm_subnet.sue_subnet_private_1.id
  network_security_group_id = azurerm_network_security_group.sue_aks_nodes_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_2" {
  subnet_id                 = azurerm_subnet.sue_subnet_private_2.id
  network_security_group_id = azurerm_network_security_group.sue_aks_nodes_nsg.id
}

# Grant cluster-admin to each member in cluster_admins
resource "azurerm_role_assignment" "cluster_admins" {
  for_each = { for user in var.cluster_admins : user.username => user }

  scope                = azurerm_kubernetes_cluster.sue_aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value.object_id
}

# Outputs
output "cluster_endpoint" {
  description = "AKS cluster API server endpoint"
  value       = azurerm_kubernetes_cluster.sue_aks.kube_config[0].host
  sensitive   = true
}

output "cluster_certificate_authority" {
  description = "AKS cluster CA data"
  value       = azurerm_kubernetes_cluster.sue_aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.sue_aks.name
}
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
