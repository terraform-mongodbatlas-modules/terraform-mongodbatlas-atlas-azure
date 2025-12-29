data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled = true
    create_key_vault = {
      enabled             = true
      name                = var.key_vault_name
      azure_location      = data.azurerm_resource_group.main.location
      resource_group_name = data.azurerm_resource_group.main.name
    }
    require_private_networking = true
    private_endpoint_regions   = var.private_endpoint_regions
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}

output "private_endpoint_status" {
  value = module.atlas_azure.encryption.private_endpoints
}
