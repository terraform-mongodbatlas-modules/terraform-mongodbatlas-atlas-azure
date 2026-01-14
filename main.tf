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

  key_vault_id     = var.encryption.key_vault_id
  key_identifier   = var.encryption.key_identifier
  create_key_vault = var.encryption.create_key_vault

  client_secret              = var.encryption_client_secret
  require_private_networking = var.encryption.require_private_networking

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

module "encryption_private_endpoint" {
  source   = "./modules/encryption_private_endpoint"
  for_each = var.encryption.enabled && var.encryption.require_private_networking ? var.encryption.private_endpoint_regions : toset([])

  project_id  = var.project_id
  region_name = each.key

  depends_on = [module.encryption]
}

# ─────────────────────────────────────────────────────────────────────────────
# PrivateLink
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count = local.enable_regional_mode ? 1 : 0

  project_id = var.project_id
  enabled    = true
}

# Atlas-side PrivateLink endpoint - created at root level to avoid cycles
# This only depends on location keys, not BYOE values
resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each = local.privatelink_key_location

  project_id    = var.project_id
  provider_name = "AZURE"
  region        = each.value

}

# Privatelink module - one per user key (BYOE or module-managed, not location_only)
module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_key_location

  project_id                       = var.project_id
  azure_location                   = each.value
  use_existing_endpoint            = true
  private_link_id                  = mongodbatlas_privatelink_endpoint.this[each.key].private_link_id
  private_link_service_name        = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_name
  private_link_service_resource_id = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_resource_id

  # Module-managed
  create_azure_private_endpoint = contains(keys(var.privatelink_endpoints), each.key)
  subnet_id                     = try(var.privatelink_endpoints[each.key].subnet_id, null)
  azure_private_endpoint_name   = contains(local.privatelinks_module_managed, each.key) ? coalesce(var.privatelink_endpoints[each.key].name, "pe-atlas-${each.key}") : null
  azure_private_endpoint_tags   = try(var.privatelink_endpoints[each.key].tags, {})

  # BYOE
  azure_private_endpoint_id         = try(var.privatelink_byoe[each.key].azure_private_endpoint_id, null)
  azure_private_endpoint_ip_address = try(var.privatelink_byoe[each.key].azure_private_endpoint_ip_address, null)
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

  container_name         = var.backup_export.container_name
  storage_account_id     = var.backup_export.storage_account_id
  create_container       = var.backup_export.create_container
  create_storage_account = var.backup_export.create_storage_account

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}
