terraform {
    backend "s3" {
    bucket = "sue-tf-state"
    key = "eks/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "sue-tf-locks"
    encrypt = true
  }
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "-> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "-> 4.0"
    }
  }
}
provider "aws" {
    region = var.aws_region
}