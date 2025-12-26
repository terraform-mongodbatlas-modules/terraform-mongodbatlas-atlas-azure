variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_azure_app_id" {
  type        = string
  default     = "9f2deb0d-be22-4524-a403-df531868bac0"
  description = "MongoDB Atlas Azure application ID. This is the application ID registered in Azure AD for MongoDB Atlas."
}

variable "create_service_principal" {
  type        = bool
  default     = true
  description = "Create Azure AD service principal. Set false and provide service_principal_id for existing."

  validation {
    condition     = var.create_service_principal || var.service_principal_id != null
    error_message = "When create_service_principal=false, service_principal_id is required."
  }
}

variable "service_principal_id" {
  type        = string
  default     = null
  description = "Existing service principal object ID. Required if create_service_principal = false."
}

variable "skip_cloud_provider_access" {
  type        = bool
  default     = false
  description = "Skip cloud_provider_access setup. Set true ONLY for privatelink-only usage where azuread provider is not available."
}
