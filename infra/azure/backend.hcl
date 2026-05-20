# Azure blob storage backend — mirrors infra/aws/backend.hcl (S3 + DynamoDB)
# Pre-requisite: apply bootstrap-state-storage/ once before running terraform init here
resource_group_name  = "sue-tf-state-rg"
storage_account_name = "suetfstate"
container_name       = "tfstate"
key                  = "aks/terraform.tfstate"