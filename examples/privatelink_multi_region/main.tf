module "atlas_azure" {
  source = "../../"

  project_id = var.project_id

  # Enables regional mode when the module sees multiple distinct Atlas regions. Ensure you understand the tradeoffs before enabling.
  privatelink_regional_mode = "auto"

  privatelink_endpoints = var.privatelink_endpoints
}

output "privatelink" {
  description = "PrivateLink connection details per region"
  value       = module.atlas_azure.privatelink
}

output "regional_mode_enabled" {
  description = "Whether regional mode is enabled (privatelink_regional_mode auto and multiple Atlas service regions)"
  value       = module.atlas_azure.regional_mode_enabled
}
