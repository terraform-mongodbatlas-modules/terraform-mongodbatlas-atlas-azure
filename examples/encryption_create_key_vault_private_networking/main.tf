data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}


module "atlas_azure" {
  source                   = "../../"
  project_id               = var.project_id
  service_principal_id     = var.service_principal_id
  create_service_principal = var.create_service_principal
  atlas_azure_app_id       = var.atlas_azure_app_id

  encryption = {
    enabled = true
    create_key_vault = {
      enabled                    = true
      name                       = var.key_vault_name
      azure_location             = data.azurerm_resource_group.main.location
      resource_group_name        = data.azurerm_resource_group.main.name
      purge_protection_enabled   = var.purge_protection_enabled
      soft_delete_retention_days = var.soft_delete_retention_days
    }
    require_private_networking = var.require_private_networking
    private_endpoint_regions   = var.private_endpoint_regions
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}

output "key_vault_id" {
  description = "Module-created Key Vault ID"
  value       = module.atlas_azure.encryption.key_vault_id
}

output "key_identifier" {
  description = "Module-created key identifier"
  value       = module.atlas_azure.encryption.key_identifier
}

output "private_endpoints" {
  description = "Private endpoint status (empty if require_private_networking = false)"
  value       = module.atlas_azure.encryption.private_endpoints
}
