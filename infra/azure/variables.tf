variable "azure_location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "sue-resource-group"
}

variable "vnet_name" {
  type    = string
  default = "sue-vnet"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

# Mirrors aws cidr_private_subnet_1 / cidr_private_subnet_2
variable "cidr_private_subnet_1" {
  type    = string
  default = "10.0.1.0/24"
}

variable "cidr_private_subnet_2" {
  type    = string
  default = "10.0.2.0/24"
}

# Mirrors aws cidr_public_subnet_1 / cidr_public_subnet_2
variable "cidr_public_subnet_1" {
  type    = string
  default = "10.0.101.0/24"
}

variable "cidr_public_subnet_2" {
  type    = string
  default = "10.0.102.0/24"
}

variable "cluster_name" {
  type    = string
  default = "qwen-cluster"
}

# - Mirrors aws cluster_admins.
# - Uses AAD object_id instead of AWS userarn.
# - TODO: populate once group account / AAD setup is confirmed.
variable "cluster_admins" {
  type = list(object({
    object_id = string
    username  = string
  }))
  default = []
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "qwen-kserve"
    ManagedBy = "terraform"
  }
}