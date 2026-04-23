variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = ""
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault name (must be globally unique)"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Enable purge protection. Set to false for dev/test to allow immediate cleanup."
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "Soft delete retention days (7-90). Use 7 for dev/test."
}

variable "private_endpoint_regions" {
  type        = set(string)
  default     = []
  description = "Regions for private endpoints. Accepts Atlas (US_EAST_2) or Azure (eastus2) format. Set to enable private networking."
}

variable "atlas_azure_app_id" {
  type        = string
  description = "MongoDB Atlas Azure application ID. This is the application ID registered in Azure AD for MongoDB Atlas."
  default     = "9f2deb0d-be22-4524-a403-df531868bac0"
}

variable "service_principal_id" {
  type        = string
  description = "Existing service principal object ID for Atlas-Azure integration"
}
