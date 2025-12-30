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

  # PrivateLink
  privatelink_primary = var.privatelink.enabled ? {
    (var.privatelink.azure_location) = {
      create_azure_private_endpoint     = var.privatelink.create_azure_private_endpoint
      subnet_id                         = var.privatelink.subnet_id
      azure_private_endpoint_id         = var.privatelink.azure_private_endpoint_id
      azure_private_endpoint_ip_address = var.privatelink.azure_private_endpoint_ip_address
    }
  } : {}

  privatelink_locations = merge(
    local.privatelink_primary,
    var.privatelink.enabled ? var.privatelink.additional_regions : {}
  )

  enable_regional_mode = length(local.privatelink_locations) > 1
}
