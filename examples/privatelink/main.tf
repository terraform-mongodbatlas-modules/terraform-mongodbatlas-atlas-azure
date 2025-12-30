module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  privatelink = {
    enabled        = true
    azure_location = var.azure_location
    subnet_id      = var.subnet_id
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink
}
