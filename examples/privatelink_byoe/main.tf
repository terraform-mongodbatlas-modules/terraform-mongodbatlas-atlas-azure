# BYOE (Bring Your Own Endpoint) pattern
# 
# For BYOE, we use a two-step approach:
# 1. Root module creates Atlas-side PrivateLink endpoint (outputs service info)
# 2. Submodule registers the user-managed Azure PE with Atlas
#
# This avoids the circular dependency that would occur if BYOE values were 
# passed back through the root module's privatelink variable.

# Step 1: Create Atlas-side PrivateLink endpoint via root module
module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  # Only enable privatelink to create Atlas-side resources
  # Don't pass BYOE values here - they would create a cycle
  privatelink = {
    enabled        = true
    azure_location = var.azure_location
    # For BYOE: don't create Azure PE, don't pass BYOE values
    create_azure_private_endpoint = false
  }
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
    subresource_name   = "mongodb"
    member_name        = "mongodb"
  }
}

# Step 3: Register the Azure PE with Atlas using the submodule
module "privatelink_service" {
  source = "../../modules/privatelink"

  project_id                       = var.project_id
  azure_location                   = var.azure_location
  private_link_id                  = module.atlas_azure.privatelink_service_info[var.azure_location].atlas_private_link_id
  private_link_service_name        = module.atlas_azure.privatelink_service_info[var.azure_location].atlas_private_link_service_name
  private_link_service_resource_id = module.atlas_azure.privatelink_service_info[var.azure_location].atlas_private_link_service_resource_id

  create_azure_private_endpoint     = false
  azure_private_endpoint_id         = azurerm_private_endpoint.custom.id
  azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}

output "privatelink" {
  description = "PrivateLink connection details"
  value = {
    atlas_private_link_id                  = module.privatelink_service.atlas_private_link_id
    atlas_private_link_service_name        = module.privatelink_service.atlas_private_link_service_name
    atlas_private_link_service_resource_id = module.privatelink_service.atlas_private_link_service_resource_id
    azure_private_endpoint_id              = module.privatelink_service.azure_private_endpoint_id
    azure_private_endpoint_ip_address      = module.privatelink_service.azure_private_endpoint_ip_address
    status                                 = module.privatelink_service.status
    error_message                          = module.privatelink_service.error_message
  }
}

output "static_ip" {
  description = "Static IP address of the private endpoint"
  value       = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}
