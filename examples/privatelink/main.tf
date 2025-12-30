module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  privatelink_module_managed_subnet_ids = {
    (var.azure_location) = var.subnet_id
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink
}
