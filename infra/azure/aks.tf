# AKS Cluster
resource "azurerm_kubernetes_cluster" "sue_aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.35"

  # System node pool placed in private subnets
  # VM size: Standard_D16s_v3 (16 vCPU, 64 GB) — CPU only, same as r5.4xlarge in AWS.
  default_node_pool {
    name                 = "system"
    node_count           = 1
    min_count            = 1
    max_count            = 4
    auto_scaling_enabled = true
    vm_size              = "Standard_D16s_v3"
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
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Azure AD RBAC
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
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