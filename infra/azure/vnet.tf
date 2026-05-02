//resource group for project
resource "azurerm_resource_group" "sue-resource-group" {
  name = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_virtual_network" "sue-vnet" {
    name = var.vnet_name
    address_space = var.vnet_address_space
    location = var.azure_location
    resource_group_name = var.resource_group_name
}
resource "azurerm_subnet" "sue-vnet-subnet-1" {
    name = var.sue-vnet-subnet-1-name
    resource_group_name = var.resource_group_name
    virtual_network_name = var.vnet_name
    address_prefixes = var.subnet-1-address_prefixes
}