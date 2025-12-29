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
  value = local.encryption_enabled ? {
    valid                       = module.encryption[0].valid
    encryption_at_rest_provider = module.encryption[0].encryption_at_rest_provider
    key_vault_id                = module.encryption[0].key_vault_id
    key_vault_uri               = module.encryption[0].key_vault_uri
    key_identifier              = module.encryption[0].key_identifier
    private_endpoints = var.encryption.require_private_networking ? {
      for region, pe in module.encryption_private_endpoint : region => {
        id            = pe.id
        status        = pe.status
        error_message = pe.error_message
      }
    } : {}
  } : null
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = local.encryption_enabled ? "AZURE" : "NONE"
}
