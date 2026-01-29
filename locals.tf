locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_endpoints_single_region) > 0 || length(var.privatelink_byoe_regions) > 0
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

  # PrivateLink: convert lists to maps for for_each
  # Multi-region: use azure_location as key (guaranteed unique by validation)
  privatelink_endpoints_map = { for ep in var.privatelink_endpoints : ep.azure_location => ep }
  # Single-region: use index as key (locations are same)
  privatelink_endpoints_single_region_map = { for idx, ep in var.privatelink_endpoints_single_region : tostring(idx) => ep }
  # Combined module-managed endpoints
  privatelink_module_managed = merge(local.privatelink_endpoints_map, local.privatelink_endpoints_single_region_map)

  # user key -> location (BYOE uses user-defined keys, module-managed uses key from above)
  privatelink_key_location = merge(
    var.privatelink_byoe_regions,
    { for k, ep in local.privatelink_module_managed : k => ep.azure_location }
  )
  privatelinks_module_managed_keys = toset(keys(local.privatelink_module_managed))
  privatelink_locations            = toset(values(local.privatelink_key_location))

  # Enable regional mode only for multi-region pattern
  enable_regional_mode = length(local.privatelink_locations) > 1
}
