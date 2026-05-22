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