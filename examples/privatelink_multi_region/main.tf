module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  # Key is used as azure_location when azure_location is not specified
  privatelink_endpoints = { for loc, subnet_id in var.subnet_ids : loc => { subnet_id = subnet_id } }
}

output "privatelink" {
  description = "PrivateLink connection details per region"
  value       = module.atlas_azure.privatelink
}

output "regional_mode_enabled" {
  description = "Whether regional mode was auto-enabled"
  value       = module.atlas_azure.regional_mode_enabled
}
