data "azurerm_client_config" "current" {}

data "azuread_service_principal" "atlas" {
  object_id = var.service_principal_id
}

locals {
  create_key_vault = var.create_key_vault != null && var.create_key_vault.enabled

  key_vault_id        = local.create_key_vault ? azurerm_key_vault.atlas[0].id : var.key_vault_id
  key_vault_name      = local.create_key_vault ? azurerm_key_vault.atlas[0].name : element(split("/", var.key_vault_id), 8)
  resource_group_name = local.create_key_vault ? var.create_key_vault.resource_group_name : element(split("/", var.key_vault_id), 4)
  key_identifier      = local.create_key_vault ? azurerm_key_vault_key.atlas[0].versionless_id : var.key_identifier

  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Module-Managed Key Vault (when create_key_vault.enabled = true)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "atlas" {
  count = local.create_key_vault ? 1 : 0

  name                       = var.create_key_vault.name
  location                   = var.create_key_vault.azure_location
  resource_group_name        = var.create_key_vault.resource_group_name
  tenant_id                  = local.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.create_key_vault.purge_protection_enabled
  soft_delete_retention_days = var.create_key_vault.soft_delete_retention_days
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "terraform_key_vault_admin" {
  count = local.create_key_vault ? 1 : 0

  scope                = azurerm_key_vault.atlas[0].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_key" "atlas" {
  count = local.create_key_vault ? 1 : 0

  name         = "atlas-encryption-key"
  key_vault_id = azurerm_key_vault.atlas[0].id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

  rotation_policy {
    automatic {
      time_before_expiry = var.create_key_vault.key_rotation_policy.rotate_before_expiry
    }
    expire_after         = var.create_key_vault.key_rotation_policy.expire_after
    notify_before_expiry = var.create_key_vault.key_rotation_policy.notify_before_expiry
  }

  depends_on = [azurerm_role_assignment.terraform_key_vault_admin]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Role Assignments (grants Atlas service principal access to Key Vault)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "key_vault_crypto" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = var.service_principal_id
}

resource "azurerm_role_assignment" "key_vault_reader" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.service_principal_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Atlas Encryption at Rest
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_encryption_at_rest" "this" {
  project_id = var.project_id

  azure_key_vault_config {
    enabled                    = true
    azure_environment          = "AZURE"
    tenant_id                  = local.tenant_id
    subscription_id            = local.subscription_id
    client_id                  = data.azuread_service_principal.atlas.client_id
    secret                     = var.client_secret
    resource_group_name        = local.resource_group_name
    key_vault_name             = local.key_vault_name
    key_identifier             = local.key_identifier
    require_private_networking = var.require_private_networking
  }

  lifecycle {
    postcondition {
      condition     = self.azure_key_vault_config[0].valid
      error_message = "Azure Key Vault config is not valid"
    }
  }

  depends_on = [
    azurerm_role_assignment.key_vault_crypto,
    azurerm_role_assignment.key_vault_reader
  ]
}
