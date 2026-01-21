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

variable "azure_location" {
  type        = string
  default     = "eastus2"
  description = "Azure region in lowercase format (e.g., `eastus2`)"
}

variable "storage_account_name" {
  type        = string
  description = "Azure Storage Account name (must be globally unique, 3-24 lowercase alphanumeric)"
}

variable "atlas_azure_app_id" {
  type        = string
  description = "MongoDB Atlas Azure application ID. This is the application ID registered in Azure AD for MongoDB Atlas."
  default     = "9f2deb0d-be22-4524-a403-df531868bac0"
}

variable "create_service_principal" {
  type        = bool
  default     = true
  description = "Create Azure AD service principal. Set false and provide service_principal_id for existing."
}

variable "service_principal_id" {
  type        = string
  default     = null
  description = "Existing service principal object ID. Required if create_service_principal = false."
}
