
# variables.tf

variable "org_id" {
  description = "Google Cloud Organization ID"
  type        = string
}



variable "billing_account" {
  type = string
}

variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "bootstrap_project" {
  type = string
}

variable "machine_type" {
  type        = string
  default     = "ec2-small"
  description = "machine type for the GKE nodes"
}

variable "cluster_name" {
  type    = string
  default = "sue-cluster"
}
variable "kserve_gsa_email" {
  type = string
  default = ""
}

variable "kserve_gsa_name" {
  type = string
  default = ""
}