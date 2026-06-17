# Resource group — top-level container
resource "azurerm_resource_group" "sue_rg" {
  name     = var.resource_group_name
  location = var.azure_location
  tags     = var.tags
}

# VNet 
resource "azurerm_virtual_network" "sue_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  tags                = merge(var.tags, { Name = "sue-vnet" })
}

# Private subnet 1
resource "azurerm_subnet" "sue_subnet_private_1" {
  name                 = "sue-subnet-private-1"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_private_subnet_1]
}

# Private subnet 2
resource "azurerm_subnet" "sue_subnet_private_2" {
  name                 = "sue-subnet-private-2"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_private_subnet_2]
}

# Public subnet 1
resource "azurerm_subnet" "sue_subnet_public_1" {
  name                 = "sue-subnet-public-1"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_public_subnet_1]
}

# Public subnet 2
resource "azurerm_subnet" "sue_subnet_public_2" {
  name                 = "sue-subnet-public-2"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_public_subnet_2]
}
resource "azurerm_resource_group" "sue_resource_group" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network — equivalent to aws_vpc.sue-vpc
resource "azurerm_virtual_network" "sue_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.sue_resource_group.location
  resource_group_name = azurerm_resource_group.sue_resource_group.name
  tags                = merge(var.tags, { Name = var.vnet_name })
}

# Node subnet — equivalent to AWS private subnets sue-subnet-private-1/2
resource "azurerm_subnet" "sue_nodes_subnet" {
  name                 = var.node_subnet_name
  resource_group_name  = azurerm_resource_group.sue_resource_group.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.node_subnet_address_prefix]
}

# Public/ingress subnet — equivalent to AWS public subnets sue-subnet-public-1/2
resource "azurerm_subnet" "sue_public_subnet" {
  name                 = var.public_subnet_name
  resource_group_name  = azurerm_resource_group.sue_resource_group.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.public_subnet_address_prefix]
}

# Attach NSGs to subnets — equivalent to AWS security group VPC associations
resource "azurerm_subnet_network_security_group_association" "nodes" {
  subnet_id                 = azurerm_subnet.sue_nodes_subnet.id
  network_security_group_id = azurerm_network_security_group.sue_nsg_nodes.id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.sue_public_subnet.id
  network_security_group_id = azurerm_network_security_group.sue_nsg_public.id
}
