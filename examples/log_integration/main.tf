module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = var.create_service_principal
  service_principal_id     = var.service_principal_id

  log_integration = {
    enabled        = true
    container_name = "atlas-logs"
    create_storage_account = {
      enabled             = true
      name                = var.storage_account_name
      resource_group_name = var.resource_group_name
      azure_location      = var.azure_location
    }
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
    ]
  }
}

output "log_integration" {
  value = module.atlas_azure.log_integration
}

output "module_full" {
  value = module.atlas_azure
}
