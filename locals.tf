locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_byoe_locations) > 0
  skip_cloud_provider_access = (
    !var.encryption.enabled &&
    !var.backup_export.enabled &&
    local.privatelink_configured
  )

  tenant_id = data.azurerm_client_config.current.tenant_id
  service_principal_id = var.create_service_principal && !local.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].object_id
  ) : var.service_principal_id

  # Full resource ID for azuread_service_principal_password (requires /servicePrincipals/{id} format)
  service_principal_resource_id = var.create_service_principal && !local.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].id
  ) : try(data.azuread_service_principal.existing[0].id, null)

  encryption_key_vault_id = var.encryption.enabled ? (
    var.encryption.key_vault_id != null ? var.encryption.key_vault_id : module.encryption[0].key_vault_id
  ) : null

  # user key -> location
  privatelink_key_location = merge(
    var.privatelink_byoe_locations,
    { for k, v in var.privatelink_endpoints : k => coalesce(v.azure_location, k) }
  )
  privatelinks_module_managed = toset(keys(var.privatelink_endpoints))
  privatelink_locations       = toset(values(local.privatelink_key_location))

  enable_regional_mode = length(local.privatelink_locations) > 1

  # Backup export
  backup_export_storage_account_id = var.backup_export.enabled ? (
    var.backup_export.storage_account_id != null ? var.backup_export.storage_account_id : module.backup_export[0].storage_account_id
  ) : null
}
