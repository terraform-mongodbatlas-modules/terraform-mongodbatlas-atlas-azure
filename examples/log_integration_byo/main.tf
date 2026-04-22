resource "azurerm_storage_account" "logs" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.azure_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_management_lock" "logs" {
  name       = "atlas-log-storage-lock"
  scope      = azurerm_storage_account.logs.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of Atlas log storage account"
}

module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = var.create_service_principal
  service_principal_id     = var.service_principal_id

  log_integration = {
    enabled            = true
    container_name     = "atlas-logs"
    storage_account_id = azurerm_storage_account.logs.id
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
      { log_types = ["MONGOD_AUDIT"], prefix_path = "audit" },
    ]
  }
}

output "log_integration" {
  value = module.atlas_azure.log_integration
}

output "module_full" {
  value = module.atlas_azure
}
