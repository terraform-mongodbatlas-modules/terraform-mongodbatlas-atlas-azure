data "azurerm_client_config" "current" {}

resource "azuread_service_principal" "atlas" {
  count = var.create_service_principal && !local.skip_cloud_provider_access ? 1 : 0

  client_id                    = var.atlas_azure_app_id
  app_role_assignment_required = false
}

data "azuread_service_principal" "existing" {
  count     = !var.create_service_principal && !local.skip_cloud_provider_access ? 1 : 0
  object_id = var.service_principal_id
}

resource "mongodbatlas_cloud_provider_access_setup" "this" {
  count = !local.skip_cloud_provider_access ? 1 : 0

  project_id    = var.project_id
  provider_name = "AZURE"

  azure_config {
    atlas_azure_app_id   = var.atlas_azure_app_id
    service_principal_id = local.service_principal_id
    tenant_id            = local.tenant_id
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
    }
  }
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  count = !local.skip_cloud_provider_access ? 1 : 0

  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.this[0].role_id

  azure {
    atlas_azure_app_id   = var.atlas_azure_app_id
    service_principal_id = local.service_principal_id
    tenant_id            = local.tenant_id
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Encryption at Rest with Azure Key Vault
# ─────────────────────────────────────────────────────────────────────────────

module "encryption" {
  count  = var.encryption.enabled ? 1 : 0
  source = "./modules/encryption"

  project_id           = var.project_id
  service_principal_id = local.service_principal_id
  timeouts             = var.timeouts

  key_vault_id     = var.encryption.key_vault_id
  key_identifier   = var.encryption.key_identifier
  create_key_vault = var.encryption.create_key_vault
  tags             = var.azure_tags

  role_id                    = mongodbatlas_cloud_provider_access_authorization.this[0].role_id
  client_secret              = var.encryption_client_secret
  require_private_networking = local.encryption_require_private_networking
  enabled_for_search_nodes   = var.encryption.enabled_for_search_nodes
  skip_role_assignments      = var.skip_role_assignments

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

check "encryption_client_secret_deprecated" {
  assert {
    condition     = var.encryption_client_secret == null
    error_message = "encryption_client_secret is deprecated and will be removed at v1.0. Remove it from your configuration; the module uses CPA role_id automatically."
  }
}

module "encryption_private_endpoint" {
  source = "./modules/encryption_private_endpoint"
  for_each = var.encryption.enabled && local.encryption_require_private_networking ? toset([
    for r in var.encryption.private_endpoint_regions :
    lookup(local._normalize_to_azure, r, r)
  ]) : toset([])

  project_id  = var.project_id
  region_name = lookup(local._normalize_to_atlas, each.key, each.key)
  timeouts    = var.timeouts

  depends_on = [module.encryption]
}

# ─────────────────────────────────────────────────────────────────────────────
# PrivateLink
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count = local.enable_regional_mode ? 1 : 0

  project_id = var.project_id
  enabled    = true

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      update = var.timeouts.update
      delete = var.timeouts.delete
    }
  }
}

# Atlas-side PrivateLink endpoint - created at root level to avoid cycles
resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each = local.privatelink_key_azure_location

  project_id    = var.project_id
  provider_name = "AZURE"
  region        = each.value

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      update = var.timeouts.update
      delete = var.timeouts.delete
    }
  }
}

# Privatelink module - one per user key (BYOE or module-managed)
module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_key_azure_location

  project_id                       = var.project_id
  azure_location                   = each.value
  use_existing_endpoint            = true
  private_link_id                  = mongodbatlas_privatelink_endpoint.this[each.key].private_link_id
  private_link_service_name        = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_name
  private_link_service_resource_id = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_resource_id

  # Module-managed
  create_azure_private_endpoint = contains(local.privatelinks_module_managed_keys, each.key)
  subnet_id                     = try(local.privatelink_module_managed[each.key].subnet_id, null)
  azure_private_endpoint_name   = contains(local.privatelinks_module_managed_keys, each.key) ? coalesce(local.privatelink_module_managed[each.key].name, "pe-atlas-${each.key}") : null
  azure_private_endpoint_tags   = merge(var.azure_tags, try(local.privatelink_module_managed[each.key].tags, {}))

  # BYOE
  azure_private_endpoint_id         = try(var.privatelink_byo_service[each.key].azure_private_endpoint_id, null)
  azure_private_endpoint_ip_address = try(var.privatelink_byo_service[each.key].azure_private_endpoint_ip_address, null)

  timeouts = var.timeouts
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup Export to Azure Blob Storage
# ─────────────────────────────────────────────────────────────────────────────

module "backup_export" {
  count  = var.backup_export.enabled ? 1 : 0
  source = "./modules/backup_export"

  project_id           = var.project_id
  role_id              = mongodbatlas_cloud_provider_access_authorization.this[0].role_id
  service_principal_id = local.service_principal_id
  tags                 = var.azure_tags

  container_name         = var.backup_export.container_name
  storage_account_id     = var.backup_export.storage_account_id
  create_container       = var.backup_export.create_container
  create_storage_account = var.backup_export.create_storage_account
  timeouts               = var.timeouts
  skip_role_assignments  = var.skip_role_assignments

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

# ─────────────────────────────────────────────────────────────────────────────
# Log Integration (AZURE_LOG_EXPORT)
# ─────────────────────────────────────────────────────────────────────────────

module "log_integration" {
  count  = var.log_integration.enabled ? 1 : 0
  source = "./modules/log_integration"

  project_id            = var.project_id
  role_id               = mongodbatlas_cloud_provider_access_authorization.this[0].role_id
  service_principal_id  = local.service_principal_id
  skip_role_assignments = var.skip_role_assignments
  tags                  = merge(var.azure_tags, var.log_integration.tags)

  container_name         = local.log_integration_default_container_name
  storage_account_id     = var.log_integration.storage_account_id
  create_container       = var.log_integration.create_container
  create_storage_account = var.log_integration.create_storage_account
  integrations           = var.log_integration.integrations
  timeouts               = var.timeouts

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

# ─────────────────────────────────────────────────────────────────────────────
# Region Validations (format-aware, post-normalization)
# ─────────────────────────────────────────────────────────────────────────────

resource "terraform_data" "region_validations" {
  lifecycle {
    precondition {
      condition     = length(local._invalid_privatelink_regions) == 0
      error_message = "Invalid region(s) in privatelink_endpoints: [${join(", ", local._invalid_privatelink_regions)}]. Supported values (Atlas or Azure format): ${local._supported_regions_display}"
    }
    precondition {
      condition     = length(local._invalid_single_region_regions) == 0
      error_message = "Invalid region(s) in privatelink_endpoints_single_region: [${join(", ", local._invalid_single_region_regions)}]. Supported values (Atlas or Azure format): ${local._supported_regions_display}"
    }
    precondition {
      condition     = length(local._invalid_byoe_regions) == 0
      error_message = "Invalid region(s) in privatelink_byo_endpoint: [${join(", ", local._invalid_byoe_regions)}]. Supported values (Atlas or Azure format): ${local._supported_regions_display}"
    }
    precondition {
      condition     = length(local._invalid_encryption_regions) == 0
      error_message = "Invalid region(s) in encryption.private_endpoint_regions: [${join(", ", local._invalid_encryption_regions)}]. Supported values (Atlas or Azure format): ${local._supported_regions_display}"
    }
  }
}
