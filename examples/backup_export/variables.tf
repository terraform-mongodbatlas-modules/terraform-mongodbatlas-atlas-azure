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
  description = "Azure location for storage account"
}

variable "storage_account_name" {
  type        = string
  description = "Azure Storage Account name (must be globally unique, 3-24 lowercase alphanumeric)"
}
