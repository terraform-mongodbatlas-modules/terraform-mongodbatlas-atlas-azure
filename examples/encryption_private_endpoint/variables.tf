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

variable "private_endpoint_regions" {
  type        = set(string)
  default     = ["US_EAST_2"]
  description = "Atlas regions for private endpoints (Atlas format: US_EAST_2, EUROPE_WEST)"
}
