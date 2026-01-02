module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  privatelink_module_managed_subnet_ids = var.subnet_ids
}

output "privatelink" {
  description = "PrivateLink connection details per region"
  value       = module.atlas_azure.privatelink
}

output "regional_mode_enabled" {
  description = "Whether regional mode was auto-enabled"
  value       = module.atlas_azure.regional_mode_enabled
}
