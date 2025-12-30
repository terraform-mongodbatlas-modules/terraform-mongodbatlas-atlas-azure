# BYOE (Bring Your Own Endpoint) pattern
# 
# For BYOE, we use a two-step approach:
# 1. Submodule uses the user-managed Azure PE with Atlas, that depends on the Atlas-side PrivateLink endpoint.

module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  # Only enable privatelink to create Atlas-side resources
  # Don't pass BYOE values here - they would create a cycle
  privatelink_region_user_managed = {
    (var.azure_location) = {
      azure_private_endpoint_id = azurerm_private_endpoint.custom.id
      azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
    }
  }
  privatelink_regions = [ var.azure_location ]
}

# Step 2: User-managed Azure Private Endpoint with custom configuration
resource "azurerm_private_endpoint" "custom" {
  name                = "pe-atlas-static-ip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = module.atlas_azure.privatelink_service_info[var.azure_location].atlas_private_link_service_name
    private_connection_resource_id = module.atlas_azure.privatelink_service_info[var.azure_location].atlas_private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "MongoDB Atlas PrivateLink"
  }

  ip_configuration {
    name               = "atlas-static"
    private_ip_address = var.static_ip_address
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value = module.atlas_azure.privatelink[var.azure_location]
}

output "static_ip" {
  description = "Static IP address of the private endpoint"
  value       = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}
