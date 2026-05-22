resource "azurerm_resource_group" "tf_state_rg" {
  name     = "${local.name}-tf-state-rg"
  location = var.location
  tags = {
    Project = local.name
    Purpose = "terraform-state"
  }
}

// Storage account
resource "azurerm_storage_account" "tf_state" {
  name                     = "${local.name}tfstate" // globally unique, lowercase, max 24 chars
  resource_group_name      = azurerm_resource_group.tf_state_rg.name
  location                 = azurerm_resource_group.tf_state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true // mirrors aws_s3_bucket_versioning
  }

  tags = {
    Project = local.name
    Purpose = "terraform-state"
  }
}

// Azure Blob container
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tf_state.name
  container_access_type = "private"
}

output "resource_group_name"  { value = azurerm_resource_group.tf_state_rg.name }
output "storage_account_name" { value = azurerm_storage_account.tf_state.name }
output "container_name"       { value = azurerm_storage_container.tfstate.name }