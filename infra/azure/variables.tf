variable "azure_location"{
	type = string
	default = "germanywestcentral" //That region should be the same as 'eu-central-1' (Frankfurt region)
}
variable "vnet_address_space"{
	type = list(string)
    default = ["10.0.0.0/16"]
}
variable "vnet_name"{
    type = string
    default = "sue-vnet"
}
variable "sue-vnet-subnet-1-name"{
    type = string
    default = "sue-vnet-subnet-1"
}
variable "subnet-1-address_prefixes" {
  type = list(string)
  default = ["10.0.0.0/24"]
}
variable "resource_group_name" {
    type = string
    default = "sue-resource-group"
}