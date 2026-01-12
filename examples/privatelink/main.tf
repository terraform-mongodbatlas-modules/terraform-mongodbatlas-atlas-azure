module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  # Key is used as azure_location when azure_location is not specified
  privatelink_endpoints = {
    (var.azure_location) = { subnet_id = var.subnet_id }
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink
}
