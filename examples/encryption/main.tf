data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "atlas" {
  count     = var.encryption_client_secret == null ? 1 : 0
  object_id = var.service_principal_id
}

# Create client secret for encryption (only if not provided)
# TODO: Replace with roleId when CLOUDP-369548 is implemented
resource "azuread_service_principal_password" "encryption" {
  count                = var.encryption_client_secret == null ? 1 : 0
  service_principal_id = data.azuread_service_principal.atlas[0].id
  display_name         = "MongoDB Atlas - Encryption at Rest"
  # Azure limits Client Secret lifetime to 2 years max. Rotate before expiration.
}

locals {
  encryption_client_secret = coalesce(var.encryption_client_secret, try(azuread_service_principal_password.encryption[0].value, null))
}

resource "azurerm_key_vault" "atlas" {
  name                       = var.key_vault_name
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "terraform_key_vault_admin" {
  scope                = azurerm_key_vault.atlas.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_key" "atlas" {
  name         = "atlas-encryption-key"
  key_vault_id = azurerm_key_vault.atlas.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P30D"
  }

  depends_on = [azurerm_role_assignment.terraform_key_vault_admin]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

module "atlas_azure" {
  source                   = "../../"
  project_id               = var.project_id
  service_principal_id     = var.service_principal_id
  create_service_principal = false
  encryption_client_secret = local.encryption_client_secret

  encryption = {
    enabled        = true
    key_vault_id   = azurerm_key_vault.atlas.id
    key_identifier = azurerm_key_vault_key.atlas.versionless_id
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}
