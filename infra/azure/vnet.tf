# Resource group — top-level container, equivalent of AWS account+region scope
resource "azurerm_resource_group" "sue_rg" {
  name     = var.resource_group_name
  location = var.azure_location
  tags     = var.tags
}

# VNet — mirrors aws_vpc.sue-vpc
resource "azurerm_virtual_network" "sue_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  tags                = merge(var.tags, { Name = "sue-vnet" })
}

# Private subnet 1 — mirrors aws_subnet.sue-subnet-private-1
resource "azurerm_subnet" "sue_subnet_private_1" {
  name                 = "sue-subnet-private-1"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_private_subnet_1]
}

# Private subnet 2 — mirrors aws_subnet.sue-subnet-private-2
resource "azurerm_subnet" "sue_subnet_private_2" {
  name                 = "sue-subnet-private-2"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_private_subnet_2]
}

# Public subnet 1 — mirrors aws_subnet.sue-subnet-public-1
resource "azurerm_subnet" "sue_subnet_public_1" {
  name                 = "sue-subnet-public-1"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_public_subnet_1]
}

# Public subnet 2 — mirrors aws_subnet.sue-subnet-public-2
resource "azurerm_subnet" "sue_subnet_public_2" {
  name                 = "sue-subnet-public-2"
  resource_group_name  = azurerm_resource_group.sue_rg.name
  virtual_network_name = azurerm_virtual_network.sue_vnet.name
  address_prefixes     = [var.cidr_public_subnet_2]
}

# Public IP for NAT Gateway — mirrors aws_eip.sue-nat-eip
resource "azurerm_public_ip" "sue_nat_eip" {
  name                = "sue-nat-eip"
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { Name = "sue-nat-eip" })
}

# NAT Gateway — mirrors aws_nat_gateway + aws_internet_gateway
resource "azurerm_nat_gateway" "sue_nat" {
  name                = "sue-nat"
  location            = azurerm_resource_group.sue_rg.location
  resource_group_name = azurerm_resource_group.sue_rg.name
  sku_name            = "Standard"
  tags                = merge(var.tags, { Name = "sue-nat" })
}

resource "azurerm_nat_gateway_public_ip_association" "sue_nat_eip" {
  nat_gateway_id       = azurerm_nat_gateway.sue_nat.id
  public_ip_address_id = azurerm_public_ip.sue_nat_eip.id
}

# Route private subnet egress through NAT — mirrors aws route tables
resource "azurerm_subnet_nat_gateway_association" "private_1" {
  subnet_id      = azurerm_subnet.sue_subnet_private_1.id
  nat_gateway_id = azurerm_nat_gateway.sue_nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private_2" {
  subnet_id      = azurerm_subnet.sue_subnet_private_2.id
  nat_gateway_id = azurerm_nat_gateway.sue_nat.id
}