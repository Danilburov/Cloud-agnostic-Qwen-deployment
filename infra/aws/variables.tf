variable "aws_region"{
	type = string
	default = "eu-central-1"
}
variable "vpc_cidr"{
	type = string
	default = "10.0.0.0/16"
}
variable "vpc_cidr_block"{
    type = string
    default = "10.0.0.0/16"
}
variable "cidr_private_subnet_1"{
    type = string
    default = "10.0.1.0/24"
}
variable "cidr_private_subnet_2" {
  type = string
  default = "10.0.2.0/24"
}
variable "cidr_public_subnet_1" {
  type = string
  default = "10.0.101.0/24"
}
variable "cidr_public_subnet_2" {
  type = string
  default = "10.0.102.0/24"
}
variable "az_a" {
  type = string
  default = "eu-central-1a"
}
variable "az_b" {
  type = string
  default = "eu-central-1b"
}
variable "cluster_name"{
	type = string
	default = "qwen-cluster"
}
variable "tags" {
  type = map(string)
  default = {
    Project  = "qwen-kserve"
    ManagedBy = "terraform"
  }
}

