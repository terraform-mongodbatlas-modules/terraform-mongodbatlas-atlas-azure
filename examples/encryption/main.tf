data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "atlas" {
  name                       = var.key_vault_name
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
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

  depends_on = [azurerm_role_assignment.terraform_key_vault_admin]
}

module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled        = true
    key_vault_id   = azurerm_key_vault.atlas.id
    key_identifier = azurerm_key_vault_key.atlas.versionless_id
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}
