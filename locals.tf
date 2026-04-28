locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_endpoints_single_region) > 0 || length(var.privatelink_byo_endpoint) > 0
  skip_cloud_provider_access = (
    !var.encryption.enabled &&
    !var.backup_export.enabled &&
    !var.log_integration.enabled &&
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

  # Region maps derived from variable (allows user override)
  atlas_region_to_azure = var.atlas_to_azure_region
  azure_region_to_atlas = { for k, v in var.atlas_to_azure_region : v => k }

  # Region normalization helpers - accepts both Atlas (US_EAST_2) and Azure (eastus2) formats
  _all_region_keys    = setunion(keys(local.atlas_region_to_azure), keys(local.azure_region_to_atlas))
  _normalize_to_atlas = { for r in local._all_region_keys : r => try(local.azure_region_to_atlas[r], r) }
  _normalize_to_azure = { for r in local._all_region_keys : r => try(local.atlas_region_to_azure[r], r) }

  # PrivateLink: convert lists to maps for for_each with normalized regions
  # Multi-region: use normalized Azure region as key (unique per Azure location; validated on var.privatelink_endpoints)
  privatelink_endpoints_map = { for ep in var.privatelink_endpoints : lookup(local._normalize_to_azure, ep.region, ep.region) => ep }
  # Single-region: use index as key (locations are same)
  privatelink_endpoints_single_region_map = { for idx, ep in var.privatelink_endpoints_single_region : tostring(idx) => ep }
  # Combined module-managed endpoints
  privatelink_module_managed = merge(local.privatelink_endpoints_map, local.privatelink_endpoints_single_region_map)

  # user key -> azure location (BYOE uses user-defined keys, module-managed uses key from above)
  privatelink_key_azure_location = merge(
    { for k, cfg in var.privatelink_byo_endpoint : k => lookup(local._normalize_to_azure, cfg.region, cfg.region) },
    { for k, ep in local.privatelink_module_managed : k => lookup(local._normalize_to_azure, ep.region, ep.region) }
  )
  privatelinks_module_managed_keys = toset(keys(local.privatelink_module_managed))
  # Distinct Atlas private endpoint service regions (excludes future cross-region consumer-only entries)
  privatelink_atlas_service_regions = toset(values(local.privatelink_key_azure_location))

  # Regional mode: opt-in when multiple Atlas service regions (see var.privatelink_regional_mode)
  enable_regional_mode = var.privatelink_regional_mode == "auto" && length(local.privatelink_azure_locations) > 1

  # Root `container_name` or, when omitted, the first integration’s `container_name` (root validation requires one or the other)
  log_integration_default_container_name = var.log_integration.enabled ? coalesce(
    var.log_integration.container_name,
    try(var.log_integration.integrations[0].container_name, null)
  ) : null

  # Invalid region inputs (for precondition validation)
  _invalid_privatelink_regions   = [for ep in var.privatelink_endpoints : ep.region if !contains(local._all_region_keys, ep.region)]
  _invalid_single_region_regions = [for ep in var.privatelink_endpoints_single_region : ep.region if !contains(local._all_region_keys, ep.region)]
  _invalid_byoe_regions          = [for k, cfg in var.privatelink_byo_endpoint : cfg.region if !contains(local._all_region_keys, cfg.region)]
  _invalid_encryption_regions    = [for r in var.encryption.private_endpoint_regions : r if !contains(local._all_region_keys, r)]

  # Sorted display string for error messages
  _supported_regions_display = join(", ", sort([for k, v in local.atlas_region_to_azure : "${k} (${v})"]))
}
