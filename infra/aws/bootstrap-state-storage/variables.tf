variable "region"{
    type = string
    description = "AWS region"
    default = "eu-central-1" 
}
variable "project"{
    type = string
    description = "Terraform state resources"
    default = "State-resources-management"
}
locals{
    name = var.project
}