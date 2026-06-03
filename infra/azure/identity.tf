# User Assigned Managed Identity for the AKS control plane.
# Using UserAssigned (vs SystemAssigned) lets us attach the Network Contributor role
# BEFORE the cluster is created, avoiding a chicken-and-egg dependency.
# Equivalent to aws_iam_role.eks_cluster_role in iam.tf.
resource "azurerm_user_assigned_identity" "sue_aks_identity" {
  name                = var.identity_name
  location            = azurerm_resource_group.sue_resource_group.location
  resource_group_name = azurerm_resource_group.sue_resource_group.name
  tags                = merge(var.tags, { Name = var.identity_name })
}

# AKS needs Network Contributor on the resource group to create load balancers,
# manage NICs, and attach public IPs for the node pools.
# Equivalent to aws_iam_role_policy_attachment.eks_vpc_resource_controller.
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.sue_resource_group.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.sue_aks_identity.principal_id
}
