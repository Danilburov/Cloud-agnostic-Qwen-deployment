variable "region"{
    type = string
    description = "AWS region"
    default = "eu-central-1" 
}
variable "project"{
    type = string
    description = "Terraform state resources"
    default = "sue"
}
locals{
    name = var.project
}