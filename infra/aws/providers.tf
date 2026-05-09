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
        version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
    region = var.aws_region
}
//needed to add kubernetes in the providers.tf because, github actions role now tries to connect to the 
//Kubernetes API which requires auth
provider "kubernetes" {
  host = aws_eks_cluster.sue_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.sue_eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", aws_eks_cluster.sue_eks.name,
      "--region", var.aws_region
    ]
  }
}