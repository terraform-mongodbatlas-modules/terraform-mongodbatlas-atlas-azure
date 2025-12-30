# Step 1: Module creates Atlas-side PrivateLink resources
# The mongodbatlas_privatelink_endpoint is created first, providing service info for Azure PE
module "atlas_azure" {
  source = "../../"

  project_id                 = var.project_id
  skip_cloud_provider_access = true

  privatelink = {
    enabled                           = true
    azure_location                    = var.azure_location
    create_azure_private_endpoint     = false
    azure_private_endpoint_id         = azurerm_private_endpoint.custom.id
    azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
  }
}

# Step 2: User-managed Azure Private Endpoint with static IP
resource "azurerm_private_endpoint" "custom" {
  name                = "pe-atlas-static-ip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = module.atlas_azure.privatelink[var.azure_location].atlas_private_link_service_name
    private_connection_resource_id = module.atlas_azure.privatelink[var.azure_location].atlas_private_link_service_resource_id
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

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink
}

output "static_ip" {
  description = "Static IP address of the private endpoint"
  value       = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}
