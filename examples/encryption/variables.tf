variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault name (must be globally unique)"
}

variable "service_principal_id" {
  type        = string
  description = "Existing service principal object ID. Create via: az ad sp create --id <atlas_azure_app_id> (default: 9f2deb0d-be22-4524-a403-df531868bac0, which is MongoDB Atlas's registered Azure AD application ID)"
}

variable "encryption_client_secret" {
  type        = string
  default     = null
  sensitive   = true
  description = "Client secret for encryption. If null, example creates one automatically."
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
