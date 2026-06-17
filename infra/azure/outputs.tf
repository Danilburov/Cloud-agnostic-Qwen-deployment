# ============================================================
# Resource Group
# ============================================================

output "resource_group_name" {
  description = "Name of the Azure Resource Group containing all project resources."
  value       = azurerm_resource_group.sue_resource_group.name
}

output "resource_group_location" {
  description = "Azure region of the Resource Group."
  value       = azurerm_resource_group.sue_resource_group.location
}

# ============================================================
# Networking
# ============================================================

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.sue_vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.sue_vnet.name
}

output "node_subnet_id" {
  description = "Resource ID of the AKS node subnet (private, equivalent to AWS private subnets)."
  value       = azurerm_subnet.sue_nodes_subnet.id
}

output "public_subnet_id" {
  description = "Resource ID of the public/ingress subnet (equivalent to AWS public subnets)."
  value       = azurerm_subnet.sue_public_subnet.id
}

# ============================================================
# AKS Cluster
# ============================================================

output "cluster_name" {
  description = "Name of the AKS cluster. Equivalent to AWS EKS cluster_name output."
  value       = azurerm_kubernetes_cluster.sue_aks.name
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the AKS API server. Equivalent to AWS EKS cluster_endpoint output."
  value       = azurerm_kubernetes_cluster.sue_aks.kube_config[0].host
  sensitive   = true
}

output "cluster_certificate_authority" {
  description = "Base64-encoded CA certificate for the AKS cluster. Equivalent to AWS EKS cluster_certificate_authority output."
  value       = azurerm_kubernetes_cluster.sue_aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config_raw" {
  description = "Full kubeconfig for this cluster. Usage: terraform output -raw kube_config_raw > ~/.kube/config"
  value       = azurerm_kubernetes_cluster.sue_aks.kube_config_raw
  sensitive   = true
}

output "cluster_node_resource_group" {
  description = "Auto-generated resource group that holds AKS node infrastructure (VMs, NICs, OS disks). Do not manually modify resources in this group."
  value       = azurerm_kubernetes_cluster.sue_aks.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation. Equivalent to the AWS OIDC provider URL created in iam.tf."
  value       = var.oidc_issuer_enabled ? azurerm_kubernetes_cluster.sue_aks.oidc_issuer_url : null
}

# ============================================================
# Identity
# ============================================================

output "identity_principal_id" {
  description = "Principal ID of the AKS User Assigned Managed Identity. Use this for additional role assignments."
  value       = azurerm_user_assigned_identity.sue_aks_identity.principal_id
}

output "identity_client_id" {
  description = "Client ID of the AKS Managed Identity. Use this when configuring Workload Identity federation on service accounts."
  value       = azurerm_user_assigned_identity.sue_aks_identity.client_id
}
