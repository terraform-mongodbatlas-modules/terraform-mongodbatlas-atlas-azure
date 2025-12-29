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

variable "require_private_networking" {
  type        = bool
  default     = false
  description = "Enable private networking to Key Vault."
}

variable "private_endpoint_regions" {
  type        = set(string)
  default     = []
  description = "Atlas regions for private endpoints (Atlas format: US_EAST_2, EUROPE_WEST). Required when require_private_networking = true."
}
