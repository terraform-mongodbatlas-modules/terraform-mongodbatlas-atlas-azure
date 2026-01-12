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

  validation {
    condition     = var.service_principal_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", lower(var.service_principal_id)))
    error_message = "service_principal_id must be a valid GUID (e.g., 00000000-0000-0000-0000-000000000000)."
  }
}

variable "skip_cloud_provider_access" {
  type        = bool
  default     = false
  description = "Skip cloud_provider_access setup. Set true ONLY for privatelink-only usage where azuread provider is not available."

  validation {
    condition     = !var.skip_cloud_provider_access || !var.encryption.enabled
    error_message = "Encryption requires Azure AD integration. Cannot use encryption.enabled=true with skip_cloud_provider_access=true."
  }

  validation {
    condition     = !var.skip_cloud_provider_access || !var.backup_export.enabled
    error_message = "Backup export requires Azure AD integration. Cannot use backup_export.enabled=true with skip_cloud_provider_access=true."
  }
}

variable "encryption" {
  type = object({
    enabled        = optional(bool, false)
    key_vault_id   = optional(string)
    key_identifier = optional(string)
    create_key_vault = optional(object({
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
    }))
    require_private_networking = optional(bool, false)
    private_endpoint_regions   = optional(set(string), [])
  })
  default     = {}
  description = <<-EOT
    Encryption at rest configuration with Azure Key Vault.
    
    Provide EITHER:
    - key_vault_id + key_identifier (user-provided Key Vault)
    - create_key_vault.enabled = true (module-managed Key Vault)

    NOTE: private_endpoint_regions uses Atlas region format (e.g., US_EAST_2, EUROPE_WEST),
    not Azure format (e.g., eastus2, westeurope).
  EOT

  validation {
    condition     = !(var.encryption.key_vault_id != null && try(var.encryption.create_key_vault.enabled, false))
    error_message = "Cannot use both key_vault_id (user-provided) and create_key_vault.enabled=true (module-managed)."
  }

  validation {
    condition     = !var.encryption.enabled || (var.encryption.key_vault_id != null || try(var.encryption.create_key_vault.enabled, false))
    error_message = "encryption.enabled=true requires key_vault_id OR create_key_vault.enabled=true."
  }

  validation {
    condition     = var.encryption.key_vault_id == null || var.encryption.key_identifier != null
    error_message = "When using key_vault_id (user-provided), key_identifier is required."
  }

  validation {
    condition     = var.encryption.key_vault_id == null || var.encryption.create_key_vault == null
    error_message = "When using key_vault_id (user-provided), do not set create_key_vault."
  }

  validation {
    condition = var.encryption.key_identifier == null || can(regex(
      "^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/keys/[a-zA-Z0-9-]+$",
      var.encryption.key_identifier
    ))
    error_message = "key_identifier must be versionless: https://{vault}.vault.azure.net/keys/{key-name}"
  }

  validation {
    condition = var.encryption.create_key_vault == null || can(regex(
      "^[a-z][a-z0-9]+$",
      var.encryption.create_key_vault.azure_location
    ))
    error_message = "create_key_vault.azure_location must use Azure format (lowercase, no separators). Examples: eastus2, westeurope"
  }

  validation {
    condition     = !var.encryption.require_private_networking || var.encryption.enabled
    error_message = "require_private_networking=true requires encryption.enabled=true."
  }

  validation {
    condition     = !var.encryption.require_private_networking || length(var.encryption.private_endpoint_regions) > 0
    error_message = "When require_private_networking=true, private_endpoint_regions must specify at least one Atlas region."
  }
}

variable "encryption_client_secret" {
  type        = string
  default     = null
  sensitive   = true
  description = <<-EOT
    Azure AD application client secret for encryption. Required when encryption.enabled = true.
    
    IMPORTANT: Azure limits Client Secret lifetime to 2 years. Atlas loses CMK access
    when the secret expires, causing cluster unavailability. Rotate secrets before expiration.
    
    Future provider enhancements may support roleId-based authentication, eliminating the need for client_secret.
  EOT

  validation {
    condition     = !var.encryption.enabled || var.encryption_client_secret != null
    error_message = "encryption_client_secret is required when encryption.enabled = true."
  }
}

variable "privatelink_byoe_locations" {
  type        = map(string)
  default     = {}
  description = "Atlas-side PrivateLink endpoints for BYOE. Key is user identifier, value is Azure location."
  validation {
    condition     = alltrue([for loc in values(var.privatelink_byoe_locations) : can(regex("^[a-z][a-z0-9]+$", loc))])
    error_message = "All values must use Azure location format (lowercase, no separators). Examples: eastus2, westeurope"
  }
  validation {
    condition     = length(setintersection(keys(var.privatelink_byoe_locations), keys(var.privatelink_endpoints))) == 0
    error_message = "Keys in privatelink_byoe_locations must not overlap with keys in privatelink_endpoints."
  }
}

variable "privatelink_byoe" {
  type = map(object({
    azure_private_endpoint_id         = string
    azure_private_endpoint_ip_address = string
  }))
  default     = {}
  description = "BYOE endpoint details. Key must exist in privatelink_byoe_locations."
  validation {
    condition     = alltrue([for k in keys(var.privatelink_byoe) : contains(keys(var.privatelink_byoe_locations), k)])
    error_message = "All keys in privatelink_byoe must exist in privatelink_byoe_locations."
  }
}

variable "privatelink_endpoints" {
  type = map(object({
    azure_location = optional(string)
    subnet_id      = string
    name           = optional(string)
    tags           = optional(map(string), {})
  }))
  default     = {}
  description = "Module-managed PrivateLink endpoints. Key is user identifier (or Azure location if azure_location omitted)."
  validation {
    condition = alltrue([
      for k, v in var.privatelink_endpoints : can(regex("^[a-z][a-z0-9]+$", coalesce(v.azure_location, k)))
    ])
    error_message = "azure_location (or key as fallback) must use Azure format (lowercase, no separators). Examples: eastus2, westeurope"
  }
}

variable "backup_export" {
  type = object({
    enabled        = optional(bool, false)
    container_name = optional(string)
    # User-provided storage account
    storage_account_id = optional(string)
    create_container   = optional(bool, true)
    # Module-managed storage account
    create_storage_account = optional(object({
      enabled             = bool
      name                = string
      resource_group_name = string
      azure_location      = string
      replication_type    = optional(string, "LRS")
      account_tier        = optional(string, "Standard")
      min_tls_version     = optional(string, "TLS1_2")
    }))
  })
  default     = {}
  description = "Backup snapshot export to Azure Blob Storage. Provide EITHER storage_account_id (user-provided) OR create_storage_account.enabled = true (module-managed)."

  validation {
    condition     = !(var.backup_export.storage_account_id != null && try(var.backup_export.create_storage_account.enabled, false))
    error_message = "Cannot use both storage_account_id (user-provided) and create_storage_account.enabled=true (module-managed)."
  }

  validation {
    condition     = !var.backup_export.enabled || (var.backup_export.storage_account_id != null || try(var.backup_export.create_storage_account.enabled, false))
    error_message = "backup_export.enabled=true requires storage_account_id OR create_storage_account.enabled=true."
  }

  validation {
    condition     = !var.backup_export.enabled || var.backup_export.container_name != null
    error_message = "backup_export.enabled=true requires container_name."
  }

  validation {
    condition     = var.backup_export.create_container != false || var.backup_export.storage_account_id != null
    error_message = "create_container=false only valid with storage_account_id (user-provided storage)."
  }

  validation {
    condition = var.backup_export.storage_account_id == null || can(regex(
      "^/subscriptions/[0-9a-f-]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]+$",
      var.backup_export.storage_account_id
    ))
    error_message = "storage_account_id must be a valid Azure Storage Account resource ID."
  }

  validation {
    condition = var.backup_export.create_storage_account == null || can(regex(
      "^[a-z][a-z0-9]+$",
      var.backup_export.create_storage_account.azure_location
    ))
    error_message = "create_storage_account.azure_location must use Azure format (lowercase, no separators). Examples: eastus2, westeurope"
  }
}
