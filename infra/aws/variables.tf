variable "aws_region"{
	type = string
	default = "eu-central-1"
}
variable "vpc_cidr"{
	type = string
	default = "10.0.0.0/16"
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

