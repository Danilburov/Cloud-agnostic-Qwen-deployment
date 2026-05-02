terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~>3.0"
    }
  }
}
provider "azurerm" {
//Here we can add the region if neccesseray, as it was done for AWS version.tf file
//However, unsure what we need here still
  features {}
}