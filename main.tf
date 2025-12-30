data "azurerm_client_config" "current" {}

resource "azuread_service_principal" "atlas" {
  count = var.create_service_principal && !var.skip_cloud_provider_access ? 1 : 0

  client_id                    = var.atlas_azure_app_id
  app_role_assignment_required = false
}

data "azuread_service_principal" "existing" {
  count     = !var.create_service_principal && !var.skip_cloud_provider_access ? 1 : 0
  object_id = var.service_principal_id
}

resource "mongodbatlas_cloud_provider_access_setup" "this" {
  count = !var.skip_cloud_provider_access ? 1 : 0

  project_id    = var.project_id
  provider_name = "AZURE"

  azure_config {
    atlas_azure_app_id   = var.atlas_azure_app_id
    service_principal_id = local.service_principal_id
    tenant_id            = local.tenant_id
  }
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  count = !var.skip_cloud_provider_access ? 1 : 0

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

resource "azuread_service_principal_password" "encryption" {
  count                = local.create_encryption_client_secret ? 1 : 0
  service_principal_id = local.service_principal_resource_id
  display_name         = "MongoDB Atlas Module - Encryption at Rest"
  # end_date_relative    = "17520h" # 2 years (maximum allowed and default) TODO: Document or remove in CLOUDP-369548
}

module "encryption" {
  count  = var.encryption.enabled ? 1 : 0
  source = "./modules/encryption"

  project_id           = var.project_id
  service_principal_id = local.service_principal_id

  key_vault_id     = var.encryption.key_vault_id
  key_identifier   = var.encryption.key_identifier
  create_key_vault = var.encryption.create_key_vault

  client_secret              = local.encryption_client_secret
  require_private_networking = var.encryption.require_private_networking

  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

module "encryption_private_endpoint" {
  source   = "./modules/encryption_private_endpoint"
  for_each = var.encryption.enabled && var.encryption.require_private_networking ? var.encryption.private_endpoint_regions : toset([])

  project_id   = var.project_id
  region_name  = each.key
  key_vault_id = local.encryption_key_vault_id

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
  for_each = local.privatelink_location_keys

  project_id    = var.project_id
  provider_name = "AZURE"
  region        = each.key

  depends_on = [mongodbatlas_private_endpoint_regional_mode.this]

  lifecycle {
    precondition {
      condition     = var.privatelink.azure_location != null
      error_message = "privatelink.enabled=true requires azure_location."
    }
    precondition {
      condition     = can(regex("^[a-z][a-z0-9]+$", each.key))
      error_message = "azure_location must use Azure format (lowercase, no separators). Examples: eastus2, westeurope"
    }
  }
}

# Service registration submodule - only for module-managed Azure PEs
# BYOE endpoints should use the submodule directly (see examples/privatelink_byoe)
module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_managed_locations

  project_id                       = var.project_id
  azure_location                   = each.key
  private_link_id                  = mongodbatlas_privatelink_endpoint.this[each.key].private_link_id
  private_link_service_name        = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_name
  private_link_service_resource_id = mongodbatlas_privatelink_endpoint.this[each.key].private_link_service_resource_id
  create_azure_private_endpoint    = true
  subnet_id                        = each.value.subnet_id
}
