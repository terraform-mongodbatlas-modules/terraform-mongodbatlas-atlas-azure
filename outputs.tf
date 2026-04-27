output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-Azure features."
  value       = !local.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].role_id : null
}

output "cloud_provider_access" {
  description = "Cloud provider access configuration for Atlas-Azure integration."
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
  description = "Atlas PrivateLink service info per user key (for BYOE - create your Azure PE using these values)"
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
  description = "Azure resource IDs for data source lookups."
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
  description = "Whether private endpoint regional mode is enabled (auto-enabled for multi-region)"
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
