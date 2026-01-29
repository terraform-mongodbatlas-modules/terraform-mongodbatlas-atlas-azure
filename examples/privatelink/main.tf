module "atlas_azure" {
  source = "../../"

  project_id = var.project_id

  privatelink_endpoints = [
    { azure_location = var.azure_location, subnet_id = var.subnet_id }
  ]
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink
}
