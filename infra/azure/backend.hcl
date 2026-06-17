resource_group_name  = "sue-tf-state-rg"
storage_account_name = "suetfstate"
container_name       = "tfstate"
key                  = "infra/azure/terraform.tfstate"
use_azuread_auth     = true