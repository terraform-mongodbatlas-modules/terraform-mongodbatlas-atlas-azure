locals {
  tenant_id = data.azurerm_client_config.current.tenant_id
  service_principal_id = var.create_service_principal && !var.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].object_id
  ) : var.service_principal_id

  # Full resource ID for azuread_service_principal_password (requires /servicePrincipals/{id} format)
  service_principal_resource_id = var.create_service_principal && !var.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].id
  ) : try(data.azuread_service_principal.existing[0].id, null)

  encryption_key_vault_id = var.encryption.enabled ? (
    var.encryption.key_vault_id != null ? var.encryption.key_vault_id : module.encryption[0].key_vault_id
  ) : null

  # Merge all privatelink configs: BYOE locations-only, BYOE with endpoint, and module-managed
  privatelink_keys = concat(keys(var.privatelink_byoe_locations), keys(var.privatelink_endpoints))
  privatelink_key_location = merge(
    var.privatelink_byoe_locations,
    { for k, v in var.privatelink_endpoints : k => coalesce(v.azure_location, k) }
  )
  privatelinks_module_managed = toset(keys(var.privatelink_endpoints))
  privatelink_locations       = toset(values(local.privatelink_key_location))

  # All unique locations from BYOE + module-managed endpoints
  enable_regional_mode = length(local.privatelink_locations) > 1

  # Backup export
  backup_export_storage_account_id = var.backup_export.enabled ? (
    var.backup_export.storage_account_id != null ? var.backup_export.storage_account_id : module.backup_export[0].storage_account_id
  ) : null
}
