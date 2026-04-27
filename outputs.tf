output "role_id" {
  description = "Atlas Cloud Provider Access role_id for the Azure integration. Reuse this value for other Atlas features that need the same Azure trust relationship."
  value       = !local.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].role_id : null
}

output "cloud_provider_access" {
  description = "Cloud Provider Access summary: role_id, service principal IDs, and authorization metadata for the Atlas Azure integration."
  value = !local.skip_cloud_provider_access ? {
    role_id                       = mongodbatlas_cloud_provider_access_authorization.this[0].role_id
    service_principal_id          = local.service_principal_id
    service_principal_resource_id = local.service_principal_resource_id
    authorized_date               = mongodbatlas_cloud_provider_access_authorization.this[0].authorized_date
  } : null
}

output "encryption" {
  description = "Encryption at rest configuration status"
  value = var.encryption.enabled ? {
    valid                       = module.encryption[0].valid
    encryption_at_rest_provider = module.encryption[0].encryption_at_rest_provider
    key_vault_id                = module.encryption[0].key_vault_id
    key_vault_uri               = module.encryption[0].key_vault_uri
    key_identifier              = module.encryption[0].key_identifier
    enabled_for_search_nodes    = module.encryption[0].enabled_for_search_nodes
    private_endpoints = local.encryption_require_private_networking ? {
      for region, pe in module.encryption_private_endpoint : region => {
        id                               = pe.id
        status                           = pe.status
        error_message                    = pe.error_message
        private_endpoint_connection_name = pe.private_endpoint_connection_name
      }
    } : {}
  } : null
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = var.encryption.enabled ? "AZURE" : "NONE"
}

output "privatelink" {
  description = "PrivateLink status per user key (both module-managed and BYOE)."
  value = {
    for key, pl in module.privatelink : key => {
      region                                 = local.privatelink_key_azure_location[key]
      atlas_private_link_id                  = pl.atlas_private_link_id
      atlas_endpoint_service_name            = pl.atlas_endpoint_service_name
      atlas_private_link_service_resource_id = pl.atlas_private_link_service_resource_id
      azure_private_endpoint_id              = pl.azure_private_endpoint_id
      azure_private_endpoint_ip_address      = pl.azure_private_endpoint_ip_address
      status                                 = pl.status
      error_message                          = pl.error_message
    }
  }
}

output "privatelink_service_info" {
  description = "Per-key Atlas PrivateLink service identifiers. Use with bring-your-own-endpoint to create `azurerm_private_endpoint` resources and then pass their IDs and IPs to `privatelink_byo_service`."
  value = {
    for key, atlas_endpoint in mongodbatlas_privatelink_endpoint.this : key => {
      region                                 = local.privatelink_key_azure_location[key]
      atlas_private_link_id                  = atlas_endpoint.private_link_id
      atlas_endpoint_service_name            = atlas_endpoint.private_link_service_name
      atlas_private_link_service_resource_id = atlas_endpoint.private_link_service_resource_id
    }
  }
}

output "resource_ids" {
  description = "Convenience map of role_id, service principal, Key Vault, keys, and storage account resource IDs for references in your root module or other stacks."
  value = {
    role_id                = !local.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].role_id : null
    service_principal_id   = local.service_principal_id
    key_vault_id           = try(module.encryption[0].key_vault_id, null)
    key_identifier         = try(module.encryption[0].key_identifier, null)
    storage_account_id     = try(module.backup_export[0].storage_account_id, null)
    log_storage_account_id = try(module.log_integration[0].storage_account_id, null)
  }
}

output "regional_mode_enabled" {
  description = "True when private endpoint regional mode is enabled in Atlas. The module enables it automatically when you use multiple distinct regions in PrivateLink inputs. See https://www.mongodb.com/docs/atlas/security-private-endpoint/#regionalized-private-endpoints"
  value       = local.enable_regional_mode
}

output "export_bucket_id" {
  description = "Export bucket ID for backup schedule auto_export_enabled"
  value       = var.backup_export.enabled ? module.backup_export[0].export_bucket_id : null
}

output "backup_export" {
  description = "Backup export configuration status"
  value = var.backup_export.enabled ? {
    export_bucket_id   = module.backup_export[0].export_bucket_id
    storage_account_id = module.backup_export[0].storage_account_id
    container_name     = module.backup_export[0].container_name
    service_url        = module.backup_export[0].service_url
    expiration_days    = module.backup_export[0].expiration_days
  } : null
}

output "log_integration" {
  description = "Log integration configuration status"
  value = var.log_integration.enabled ? {
    storage_account_id = module.log_integration[0].storage_account_id
    container_name     = module.log_integration[0].container_name
    service_url        = module.log_integration[0].service_url
    integration_ids    = module.log_integration[0].integration_ids
    expiration_days    = module.log_integration[0].expiration_days
  } : null
}
