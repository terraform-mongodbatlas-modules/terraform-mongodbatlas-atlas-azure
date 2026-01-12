output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-Azure features."
  value       = !var.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].role_id : null
}

output "service_principal_id" {
  description = "Service principal object ID used for Atlas-Azure integration."
  value       = !var.skip_cloud_provider_access ? local.service_principal_id : null
}

output "authorized_date" {
  description = "Date when the cloud provider access was authorized."
  value       = !var.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].authorized_date : null
}

output "feature_usages" {
  description = "List of features using this cloud provider access role."
  value       = !var.skip_cloud_provider_access ? mongodbatlas_cloud_provider_access_authorization.this[0].feature_usages : null
}

output "encryption" {
  description = "Encryption at rest configuration status"
  value = var.encryption.enabled ? {
    valid                       = module.encryption[0].valid
    encryption_at_rest_provider = module.encryption[0].encryption_at_rest_provider
    key_vault_id                = module.encryption[0].key_vault_id
    key_vault_uri               = module.encryption[0].key_vault_uri
    key_identifier              = module.encryption[0].key_identifier
    private_endpoints = var.encryption.require_private_networking ? {
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
  description = "PrivateLink status for module-managed endpoints. For BYOE, use privatelink_service_info and call the submodule directly."
  value = {
    for region, pl in module.privatelink : region => {
      atlas_private_link_id                  = pl.atlas_private_link_id
      atlas_private_link_service_name        = pl.atlas_private_link_service_name
      atlas_private_link_service_resource_id = pl.atlas_private_link_service_resource_id
      azure_private_endpoint_id              = pl.azure_private_endpoint_id
      azure_private_endpoint_ip_address      = pl.azure_private_endpoint_ip_address
      status                                 = pl.status
      error_message                          = pl.error_message
    }
  }
}

output "privatelink_service_info" {
  description = "Atlas PrivateLink service info per region (for BYOE pattern - create your Azure PE using these values)"
  value = {
    for region, ep in mongodbatlas_privatelink_endpoint.this : region => {
      atlas_private_link_id                  = ep.private_link_id
      atlas_private_link_service_name        = ep.private_link_service_name
      atlas_private_link_service_resource_id = ep.private_link_service_resource_id
    }
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
  } : null
}
