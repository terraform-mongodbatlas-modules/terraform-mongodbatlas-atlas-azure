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
