locals {
  tenant_id = data.azurerm_client_config.current.tenant_id
  service_principal_id = var.create_service_principal && !var.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].object_id
  ) : var.service_principal_id

  encryption_key_vault_id = var.encryption.enabled ? (
    var.encryption.key_vault_id != null ? var.encryption.key_vault_id : module.encryption[0].key_vault_id
  ) : null
}
