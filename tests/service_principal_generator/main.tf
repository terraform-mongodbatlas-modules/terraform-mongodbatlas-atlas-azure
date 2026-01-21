terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.9"
}

variable "atlas_azure_app_id" {
  type        = string
  default     = "9f2deb0d-be22-4524-a403-df531868bac0"
  description = "MongoDB Atlas Azure application ID"
}

data "azuread_service_principal" "atlas" {
  client_id = var.atlas_azure_app_id
}

output "service_principal_id" {
  description = "Service principal object ID"
  value       = data.azuread_service_principal.atlas.object_id
}

output "atlas_azure_app_id" {
  description = "Atlas Azure app ID used"
  value       = var.atlas_azure_app_id
}
