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
