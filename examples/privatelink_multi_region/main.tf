module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  privatelink = {
    enabled            = true
    azure_location     = var.primary_azure_location
    subnet_id          = var.primary_subnet_id
    additional_regions = var.additional_regions
  }
}

output "privatelink" {
  description = "PrivateLink connection details per region"
  value       = module.atlas_azure.privatelink
}

output "regional_mode_enabled" {
  description = "Whether regional mode was auto-enabled"
  value       = module.atlas_azure.regional_mode_enabled
}
