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

  # Encryption: derive require_private_networking from private_endpoint_regions presence
  encryption_require_private_networking = length(var.encryption.private_endpoint_regions) > 0

  # Region normalization helpers - accepts both Atlas (US_EAST_2) and Azure (eastus2) formats
  _all_region_keys    = setunion(keys(local.atlas_region_to_azure), keys(local.azure_region_to_atlas))
  _normalize_to_atlas = { for r in local._all_region_keys : r => try(local.azure_region_to_atlas[r], r) }
  _normalize_to_azure = { for r in local._all_region_keys : r => try(local.atlas_region_to_azure[r], r) }

  # PrivateLink: convert lists to maps for for_each with normalized regions
  # Multi-region: use normalized azure region as key (guaranteed unique by validation)
  privatelink_endpoints_map = { for ep in var.privatelink_endpoints : lookup(local._normalize_to_azure, ep.region, ep.region) => ep }
  # Single-region: use index as key (locations are same)
  privatelink_endpoints_single_region_map = { for idx, ep in var.privatelink_endpoints_single_region : tostring(idx) => ep }
  # Combined module-managed endpoints
  privatelink_module_managed = merge(local.privatelink_endpoints_map, local.privatelink_endpoints_single_region_map)

  # user key -> azure location (BYOE uses user-defined keys, module-managed uses key from above)
  privatelink_key_azure_location = merge(
    { for k, v in var.privatelink_byoe_regions : k => lookup(local._normalize_to_azure, v, v) },
    { for k, ep in local.privatelink_module_managed : k => lookup(local._normalize_to_azure, ep.region, ep.region) }
  )
  privatelinks_module_managed_keys = toset(keys(local.privatelink_module_managed))
  privatelink_azure_locations      = toset(values(local.privatelink_key_azure_location))

  # Enable regional mode only for multi-region pattern
  enable_regional_mode = length(local.privatelink_azure_locations) > 1

  # Invalid region inputs (for check blocks)
  _invalid_privatelink_regions = [for ep in var.privatelink_endpoints : ep.region if !contains(local._all_region_keys, ep.region)]
  _invalid_byoe_regions        = [for k, v in var.privatelink_byoe_regions : v if !contains(local._all_region_keys, v)]
  _invalid_encryption_regions  = [for r in var.encryption.private_endpoint_regions : r if !contains(local._all_region_keys, r)]

  # Sorted display string for error messages
  _supported_regions_display = join(", ", sort([for k, v in local.atlas_region_to_azure : "${k} (${v})"]))
}
