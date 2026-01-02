variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "service_principal_id" {
  type        = string
  description = "Azure AD service principal object ID for role assignments"
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "Azure Key Vault resource ID. Required if create_key_vault is not set."
}

variable "key_identifier" {
  type        = string
  default     = null
  description = "Versionless Key Vault key URL. Required if key_vault_id is provided."
}

variable "create_key_vault" {
  type = object({
    enabled                    = bool
    name                       = string
    resource_group_name        = string
    azure_location             = string
    purge_protection_enabled   = optional(bool, true)
    soft_delete_retention_days = optional(number, 90)
    key_rotation_policy = optional(object({
      expire_after         = optional(string, "P365D")
      rotate_before_expiry = optional(string, "P30D")
      notify_before_expiry = optional(string, "P30D")
    }), {})
  })
  default     = null
  description = "Create module-managed Key Vault. Mutually exclusive with key_vault_id. key_rotation_policy uses ISO 8601 duration format (P365D = 365 days). Azure auto-rotates keys and Atlas uses versionless key URL."
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Azure AD application client secret for Atlas encryption."
}

variable "require_private_networking" {
  type        = bool
  default     = false
  description = "Enable private networking to Key Vault"
}
