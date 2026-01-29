module "atlas_azure" {
  source = "../../"

  project_id            = var.project_id
  privatelink_endpoints = var.privatelink_endpoints
}

output "privatelink" {
  description = "PrivateLink connection details per region"
  value       = module.atlas_azure.privatelink
}

output "regional_mode_enabled" {
  description = "Whether regional mode was auto-enabled"
  value       = module.atlas_azure.regional_mode_enabled
}
