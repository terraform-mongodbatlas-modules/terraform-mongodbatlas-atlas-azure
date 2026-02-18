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
  description = "Create Azure AD service principal. Set as `false` and provide `service_principal_id` for existing."

  validation {
    condition     = var.create_service_principal || var.service_principal_id != null
    error_message = "When create_service_principal=false, service_principal_id is required."
  }
}

variable "service_principal_id" {
  type        = string
  default     = null
  description = "Existing service principal object ID. Required if `create_service_principal = false`."

  validation {
    condition     = var.service_principal_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", lower(var.service_principal_id)))
    error_message = "service_principal_id must be a valid GUID (e.g., 00000000-0000-0000-0000-000000000000)."
  }
}

variable "azure_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all Azure resources (Key Vault, Storage Account, Private Endpoints)."
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
    enabled_for_search_nodes = optional(bool, true)
    private_endpoint_regions = optional(set(string), [])
  })
  default     = {}
  description = <<-EOT
    Encryption at rest configuration with Azure Key Vault. 
    Provide EITHER:

    - `key_vault_id` + `key_identifier` (for user-provided Key Vault)
    - `create_key_vault.enabled` = true (for module-managed Key Vault)

    **Search Node Encryption:**
    `enabled_for_search_nodes` (default: `true`) controls whether BYOK encryption applies to dedicated search nodes. The module defaults to `true` (provider default is `false`) for a secure-by-default experience. Flipping from `false` to `true` on a deployment with dedicated search nodes triggers reprovisioning and index rebuild.

    **NOTE:** `private_endpoint_regions` accepts both Atlas format (e.g., `US_EAST_2`) and Azure format (e.g., `eastus2`).
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
}

variable "encryption_client_secret" {
  type        = string
  default     = null
  sensitive   = true
  description = <<-EOT
    Azure AD application client secret for encryption. This value is required when using module-managed encryption (`encryption.enabled = true`).

    **IMPORTANT:** Azure limits the client secret lifetime to two years. When the secret expires, Atlas loses CMK access, causing cluster unavailability. Rotate secrets before expiration.

    **v1 Roadmap:** This variable will become optional once the mongodbatlas provider adds secretless `role_id`-based authentication for Azure encryption (expected in v1). The module will then support both methods with secretless as the recommended approach.
  EOT

  validation {
    condition     = !var.encryption.enabled || var.encryption_client_secret != null
    error_message = "encryption_client_secret is required when encryption.enabled = true."
  }
}

variable "privatelink_byoe_regions" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Atlas-side PrivateLink endpoints for BYOE (Bring Your Own Endpoint).
    
    Key: A unique identifier you choose to reference this endpoint (e.g., "pe1", "primary", "my-endpoint").
    Value: Region in Atlas format (e.g., "US_EAST_2") or Azure format (e.g., "eastus2").
    
    Example:
    ```hcl
    privatelink_byoe_regions = {
      "primary"   = "eastus2"
      "secondary" = "EUROPE_WEST"
    }
    ```
  EOT
}

variable "privatelink_byoe" {
  type = map(object({
    azure_private_endpoint_id         = string
    azure_private_endpoint_ip_address = string
  }))
  default     = {}
  description = "BYOE endpoint details. Key must exist in `privatelink_byoe_regions`."
  validation {
    condition     = alltrue([for k in keys(var.privatelink_byoe) : contains(keys(var.privatelink_byoe_regions), k)])
    error_message = "All keys in privatelink_byoe must exist in privatelink_byoe_regions."
  }
}

variable "privatelink_endpoints" {
  type = list(object({
    region    = string
    subnet_id = string
    name      = optional(string)
    tags      = optional(map(string), {})
  }))
  default     = []
  description = "Multi-region PrivateLink endpoints. `region` accepts Atlas format (US_EAST_2) or Azure format (eastus2). All regions must be UNIQUE."
  validation {
    condition     = length(var.privatelink_endpoints) == length(distinct([for ep in var.privatelink_endpoints : ep.region]))
    error_message = "All regions in privatelink_endpoints must be unique. Use privatelink_endpoints_single_region for multiple endpoints in the same region."
  }
}

variable "privatelink_endpoints_single_region" {
  type = list(object({
    region    = string
    subnet_id = string
    name      = optional(string)
    tags      = optional(map(string), {})
  }))
  default     = []
  description = <<-EOT
    Single-region multi-endpoint pattern. Region accepts Atlas format (US_EAST_2) or Azure format (eastus2).
    All endpoints MUST be in the same region.
    
    Example:
    ```hcl
    privatelink_endpoints_single_region = [
      { region = "eastus2", subnet_id = "/subscriptions/.../subnets/app1" },
      { region = "eastus2", subnet_id = "/subscriptions/.../subnets/app2" },
    ]
    ```
  EOT
  validation {
    condition     = length(var.privatelink_endpoints_single_region) <= 1 || length(distinct([for ep in var.privatelink_endpoints_single_region : ep.region])) == 1
    error_message = "All regions in privatelink_endpoints_single_region must match (same region)."
  }
  validation {
    condition     = length(var.privatelink_endpoints_single_region) == 0 || length(var.privatelink_endpoints) == 0
    error_message = "Cannot use both privatelink_endpoints and privatelink_endpoints_single_region."
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
  description = "Backup snapshot export to Azure Blob Storage. Provide EITHER `storage_account_id` (user-provided) OR `create_storage_account.enabled = true` (module-managed)."

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
