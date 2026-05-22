variable "location" {
  type        = string
  description = "Azure region for state storage resources"
  default     = "westeurope"
}

variable "project" {
  type        = string
  description = "Project prefix used for resource naming"
  default     = "sue"
}

locals {
  name = var.project
}