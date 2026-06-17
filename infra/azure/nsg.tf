# NSG for AKS node subnet — equivalent to aws_security_group.eks_nodes_sg
resource "azurerm_network_security_group" "sue_nsg_nodes" {
  name                = var.nsg_node_name
  location            = azurerm_resource_group.sue_resource_group.location
  resource_group_name = azurerm_resource_group.sue_resource_group.name
  tags                = merge(var.tags, { Name = var.nsg_node_name })

  # Equivalent to EKS: "Allow control plane to communicate with nodes" (ports 1025-65535)
  security_rule {
    name                       = "allow-control-plane-to-nodes"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1025-65535"]
    source_address_prefix      = "AzureCloud"
    destination_address_prefix = "*"
    description                = "AKS control plane to worker node communication"
  }

  # Equivalent to EKS: "Allow nodes to communicate with each other" (self-referencing SG rule)
  security_rule {
    name                       = "allow-node-to-node"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.node_subnet_address_prefix
    destination_address_prefix = var.node_subnet_address_prefix
    description                = "Intra-node communication within the node subnet"
  }

  # Deny everything else inbound — Azure defaults to Deny, but explicit rule is clearer in audits
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Explicit deny for all other inbound traffic"
  }
}

# NSG for public/ingress subnet — equivalent to aws_security_group.eks_cluster_sg
resource "azurerm_network_security_group" "sue_nsg_public" {
  name                = var.nsg_public_name
  location            = azurerm_resource_group.sue_resource_group.location
  resource_group_name = azurerm_resource_group.sue_resource_group.name
  tags                = merge(var.tags, { Name = var.nsg_public_name })

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.allowed_https_cidr_blocks
    destination_address_prefix = "*"
    description                = "HTTPS traffic for AKS API server and ingress"
  }

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.allowed_http_cidr_blocks
    destination_address_prefix = "*"
    description                = "HTTP traffic for ingress (redirect to HTTPS in production)"
  }
}
