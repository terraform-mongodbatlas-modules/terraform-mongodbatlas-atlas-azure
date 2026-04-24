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

    **NOTE:** `private_endpoint_regions` accepts both Atlas format (e.g., `US_EAST_2`) and Azure format (e.g., `eastus2`). Child module instances and `encryption` output map keys use normalized Azure location strings.
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
    Deprecated: Azure AD application client secret for encryption. The module now uses CPA `role_id` automatically. Remove this variable from your configuration. Will be removed at v1.0.

    When set, the encryption submodule uses the legacy Key Vault config (tenant_id, client_id, and secret).
  EOT
}

variable "privatelink_byo_endpoint" {
  type = map(object({
    region = string
  }))
  default     = {}
  description = <<-EOT
    BYOE Phase 1: Atlas PrivateLink endpoint services. Key is a user-defined identifier; `region` accepts Atlas or Azure format.
    After normalizing to Azure location, values must not duplicate a region already used in `privatelink_endpoints`.
  EOT

  validation {
    condition = length(setintersection(
      toset([for k, cfg in var.privatelink_byo_endpoint : lookup(var.atlas_to_azure_region, cfg.region, cfg.region)]),
      toset([for ep in var.privatelink_endpoints : lookup(var.atlas_to_azure_region, ep.region, ep.region)])
    )) == 0
    error_message = "Regions in privatelink_byo_endpoint must not overlap with regions in privatelink_endpoints (after normalizing to Azure location)."
  }
}

variable "privatelink_byo_service" {
  type = map(object({
    azure_private_endpoint_id         = string
    azure_private_endpoint_ip_address = string
  }))
  default     = {}
  description = <<-EOT
    BYOE Phase 2: User-managed Azure Private Endpoints linked to Atlas. Each key must exist in `privatelink_byo_endpoint`.
  EOT
  validation {
    condition     = alltrue([for k in keys(var.privatelink_byo_service) : contains(keys(var.privatelink_byo_endpoint), k)])
    error_message = "Each privatelink_byo_service key must exist in privatelink_byo_endpoint."
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
      expiration_days     = optional(number, 365)
    }))
  })
  default     = {}
  description = <<-EOT
    Backup snapshot export to Azure Blob Storage.

    Provide EITHER:
    - `storage_account_id` (user-provided Storage Account)
    - `create_storage_account.enabled = true` (module-managed Storage Account)

    **Storage account (when module-managed):**
    - `create_storage_account.name` - Storage account name (globally unique in Azure)
    - `create_storage_account.resource_group_name` and `azure_location` - Where the account is created
    - Optional: `replication_type`, `account_tier`, `min_tls_version` (defaults match the type: LRS, Standard, TLS1_2)

    **Security defaults (when module-managed):**
    - `public_network_access_enabled = false` (same as `log_integration` module-managed storage)
    - Container is private; nested blob public access is not allowed; minimum TLS 1.2

    **Lifecycle:**
    - `create_storage_account.expiration_days` - Delete blobs in the export container after N days since last modification (default 365, 0 to disable and skip `azurerm_storage_management_policy`)

    The module creates a blob container for exports unless you use a user-provided `storage_account_id` with `create_container = false` and an existing container.
  EOT

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

variable "log_integration" {
  type = object({
    enabled = optional(bool, false)
    integrations = optional(list(object({
      log_types            = list(string)
      prefix_path          = string
      storage_account_name = optional(string)
      container_name       = optional(string)
      resource_group_name  = optional(string)
    })), [])
    storage_account_id = optional(string)
    container_name     = optional(string)
    create_container   = optional(bool, true)
    create_storage_account = optional(object({
      enabled             = bool
      name                = string
      resource_group_name = string
      azure_location      = string
      replication_type    = optional(string, "LRS")
      account_tier        = optional(string, "Standard")
      min_tls_version     = optional(string, "TLS1_2")
      expiration_days     = optional(number, 90)
    }))
    tags = optional(map(string), {})
  })
  default     = {}
  description = <<-EOT
    Log integration for exporting Atlas logs to Azure Blob Storage (`AZURE_LOG_EXPORT`).
    Log exports run at 1-minute intervals.

    **Storage Strategy (same pattern as `backup_export`):**
    - `storage_account_id` — user-provided Storage Account, default for all integrations
    - `create_storage_account.enabled = true` — module-managed Storage Account with secure defaults (TLS 1.2, public access blocked)
    - Per-integration `storage_account_name` + `container_name` override for BYO storage (e.g., audit logs to a separate account)

    **Integrations:**
    Each entry in `integrations` creates one `mongodbatlas_log_integration` resource.
    `prefix_path` is required by the Atlas API; use it to isolate log types within a shared container. Atlas writes objects as `{prefix}/{relative_path}`; the module trims a trailing `/` from `prefix_path` so keys do not end up with a double slash (e.g. `mongod//file`) and plans stay stable whether or not callers include `/`.
    Valid `log_types`: MONGOD, MONGOS, MONGOD_AUDIT, MONGOS_AUDIT (not validated by the module — Atlas API is authoritative).

    **Container name:**
    When `log_integration` is enabled, set `container_name` at the root, or set `container_name` on every integration (per-integration values override the root default for that integration only).

    **Lifecycle Management:**
    `create_storage_account.expiration_days` (default 90, 0 to disable) adds an `azurerm_storage_management_policy` that auto-deletes blobs after the specified number of days.

    **Index Stability:**
    Removing an integration from the middle of the list causes subsequent entries to be destroyed and recreated (index shift).
    This is acceptable: log integrations are stateless config, the brief delivery gap (~1 min) causes no data loss.
  EOT

  validation {
    condition     = !var.log_integration.enabled || length(var.log_integration.integrations) > 0
    error_message = "log_integration.enabled = true requires at least one entry in integrations."
  }

  validation {
    condition     = !var.log_integration.enabled || (var.log_integration.storage_account_id != null || try(var.log_integration.create_storage_account.enabled, false))
    error_message = "log_integration.enabled = true requires storage_account_id OR create_storage_account.enabled = true."
  }

  validation {
    condition     = !(var.log_integration.storage_account_id != null && try(var.log_integration.create_storage_account.enabled, false))
    error_message = "Cannot use both storage_account_id (user-provided) and create_storage_account.enabled = true (module-managed)."
  }

  validation {
    condition = !var.log_integration.enabled || (
      var.log_integration.container_name != null ||
      alltrue([
        for integration in var.log_integration.integrations : try(integration.container_name, null) != null
      ])
    )
    error_message = "log_integration.enabled = true requires log_integration.container_name, or container_name on every entry in integrations."
  }

  validation {
    condition     = var.log_integration.create_container != false || var.log_integration.storage_account_id != null
    error_message = "create_container=false only valid with storage_account_id (user-provided storage)."
  }

  validation {
    condition = var.log_integration.storage_account_id == null || can(regex(
      "^/subscriptions/[0-9a-f-]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]+$",
      var.log_integration.storage_account_id
    ))
    error_message = "storage_account_id must be a valid Azure Storage Account resource ID."
  }

  validation {
    condition = var.log_integration.create_storage_account == null || can(regex(
      "^[a-z][a-z0-9]+$",
      var.log_integration.create_storage_account.azure_location
    ))
    error_message = "create_storage_account.azure_location must use Azure format (lowercase, no separators). Examples: eastus2, westeurope"
  }
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = {}
  nullable    = true
  description = <<-EOT
    Timeouts for resources that the Terraform provider exposes with a `timeouts` block or attribute. Timeout values use [Go duration](https://pkg.go.dev/time#ParseDuration) format (for example, "30m", "1h").

    Set `timeouts = null` to omit all module-managed timeouts and use each provider's defaults. This avoids plan diffs when upgrading from earlier module versions. It is also the usual choice right after `terraform import`: imported resources often have no module-managed timeout blocks in state, so the module’s default `"30m"` values would otherwise appear as new configuration in the next plan. Use `timeouts = null` until you are ready to adopt the module’s timeout defaults (or set partial/custom values).

    - `timeouts = {}` or unset: 30m for create, update, and delete.
    - `timeouts = null`: no module-managed timeouts.
    - `timeouts = { create = "1h" }`: custom create timeout; 30m for other operations unless you set them.
  EOT

  validation {
    condition = (
      var.timeouts == null
      ? true
      : alltrue([for s in [var.timeouts.create, var.timeouts.update, var.timeouts.delete] : length(trimspace(s)) > 0])
    )
    error_message = "When timeouts is not null, create, update, and delete must be non-empty duration strings (Go duration format, for example 30m or 1h30m)."
  }
}
