# Azure blob storage backend — mirrors infra/aws/backend.hcl (S3 + DynamoDB)
# Pre-requisite: apply bootstrap-state-storage/ once before running terraform init here
resource_group_name  = "suefontys-tf-state-rg"
storage_account_name = "suefontystfstate"
container_name       = "tfstate"
key                  = "aks/terraform.tfstate"
resource_group_name  = "sue-tf-state-rg"
storage_account_name = "suetfstate"
container_name       = "tfstate"
key                  = "infra/azure/terraform.tfstate"
use_azuread_auth     = true
