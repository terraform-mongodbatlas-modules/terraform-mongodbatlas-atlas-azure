module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = false
  service_principal_id     = var.service_principal_id
  skip_role_assignments    = true

  encryption = {
    enabled        = true
    key_vault_id   = var.key_vault_id
    key_identifier = var.key_identifier
  }

  backup_export = {
    enabled            = true
    container_name     = var.backup_container_name
    storage_account_id = var.backup_storage_account_id
  }

  log_integration = {
    enabled            = true
    storage_account_id = var.log_storage_account_id
    container_name     = var.log_container_name
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
      { log_types = ["MONGOD_AUDIT"], prefix_path = "audit" },
    ]
  }
}

output "role_id" {
  value = module.atlas_azure.role_id
}

output "resource_ids" {
  value = module.atlas_azure.resource_ids
}

output "encryption" {
  value = module.atlas_azure.encryption
}

output "backup_export" {
  value = module.atlas_azure.backup_export
}

output "log_integration" {
  value = module.atlas_azure.log_integration
}
