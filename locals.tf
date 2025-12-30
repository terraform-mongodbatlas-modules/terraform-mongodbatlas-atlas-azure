locals {
  tenant_id = data.azurerm_client_config.current.tenant_id
  service_principal_id = var.create_service_principal && !var.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].object_id
  ) : var.service_principal_id

  # Full resource ID for azuread_service_principal_password (requires /servicePrincipals/{id} format)
  service_principal_resource_id = var.create_service_principal && !var.skip_cloud_provider_access ? (
    azuread_service_principal.atlas[0].id
  ) : try(data.azuread_service_principal.existing[0].id, null)

  create_encryption_client_secret = var.encryption.enabled && var.encryption_client_secret == null

  encryption_client_secret = var.encryption_client_secret != null ? (
    var.encryption_client_secret
  ) : try(azuread_service_principal_password.encryption[0].value, null)

  encryption_key_vault_id = var.encryption.enabled ? (
    var.encryption.key_vault_id != null ? var.encryption.key_vault_id : module.encryption[0].key_vault_id
  ) : null

  # PrivateLink - location keys only (no BYOE values to avoid cycles)
  # privatelink_location_keys = var.privatelink_enabled ? toset(concat(
  #   [var.privatelink.azure_location],
  #   keys(var.privatelink.additional_regions)
  # )) : toset([])

  privatelink_regions = toset(
    distinct(concat(var.privatelink_regions, keys(var.privatelink_region_module_managed))),
  )
  enable_regional_mode = length(local.privatelink_regions) > 1

  # # Module-managed endpoints only (create_azure_private_endpoint = true)
  # # BYOE endpoints should use the submodule directly to avoid cycles
  # privatelink_managed_primary = var.privatelink.enabled && var.privatelink.create_azure_private_endpoint ? {
  #   (var.privatelink.azure_location) = {
  #     subnet_id = var.privatelink.subnet_id
  #   }
  # } : {}

  # privatelink_managed_additional = var.privatelink.enabled ? {
  #   for region, config in var.privatelink.additional_regions :
  #   region => { subnet_id = config.subnet_id }
  #   if config.create_azure_private_endpoint
  # } : {}

  # privatelink_managed_locations = merge(
  #   local.privatelink_managed_primary,
  #   local.privatelink_managed_additional
  # )
}
