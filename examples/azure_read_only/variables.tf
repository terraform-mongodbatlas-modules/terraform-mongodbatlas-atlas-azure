variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "atlas_azure_app_id" {
  type        = string
  default     = "9f2deb0d-be22-4524-a403-df531868bac0"
  description = "MongoDB Atlas Azure application ID. This is the application ID registered in Azure AD for MongoDB Atlas."
}

variable "service_principal_id" {
  type        = string
  description = "Existing service principal object ID (Atlas cloud provider access)"
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the existing Key Vault used for encryption at rest"
}

variable "key_identifier" {
  type        = string
  description = "Versionless key identifier URL: https://{vault}.vault.azure.net/keys/{name}"
}

variable "backup_storage_account_id" {
  type        = string
  description = "Resource ID of the existing storage account for backup export"
}

variable "backup_container_name" {
  type        = string
  description = "Blob container name for backup export in the backup storage account"
}

variable "log_storage_account_id" {
  type        = string
  description = "Resource ID of the existing storage account for log export (separate from backup is recommended)"
}

variable "log_container_name" {
  type        = string
  description = "Blob container name for log export in the log storage account"
}
