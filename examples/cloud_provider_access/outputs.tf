output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-Azure features"
  value       = module.atlas_azure.role_id
}

output "service_principal_id" {
  description = "Service principal object ID used for Atlas-Azure integration"
  value       = module.atlas_azure.service_principal_id
}

output "authorized_date" {
  description = "Date when the cloud provider access was authorized"
  value       = module.atlas_azure.authorized_date
}
