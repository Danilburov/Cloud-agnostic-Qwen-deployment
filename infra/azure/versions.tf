terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "sue-tf-state-rg"
    storage_account_name = "suetfstate"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}