terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "sue-tf-state-rg"
    storage_account_name = "suefontystfstate"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }
  backend "azurerm" {}

  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
  features {
    resource_group {
      # Allows Terraform to destroy the RG even when it still contains resources
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
