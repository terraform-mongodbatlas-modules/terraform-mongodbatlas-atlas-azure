module "atlas_azure" {
  source = "../../"

  project_id               = var.project_id
  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = var.create_service_principal
  service_principal_id     = var.service_principal_id
  # Default: creates service principal automatically
  # Set create_service_principal = false and provide service_principal_id for existing
}


output "atlas_azure" {
  value = module.atlas_azure
}
