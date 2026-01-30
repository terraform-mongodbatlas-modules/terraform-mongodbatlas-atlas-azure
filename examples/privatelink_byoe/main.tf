# BYOE (Bring Your Own Endpoint) pattern
# 
# Use BYOE when you need custom Azure Private Endpoint configuration (e.g., static IP addresses,
# custom naming, or integration with existing networking infrastructure).
#
# Single `terraform apply` approach:
# 1: Create Atlas-side PrivateLink using `privatelink_byoe_regions` to get service connection info
# 2: Create your own Azure Private Endpoint using the output `privatelink_service_info`
# 3: Register your endpoint with Atlas using `privatelink_byoe` to complete the connection
#
# Note: azurerm_private_endpoint.custom depends on Step 1 output (module.atlas_azure.privatelink_service_info)

locals {
  pe1 = "pe1"
}

module "atlas_azure" {
  source = "../../"

  project_id = var.project_id

  # BYOE: provide your own Azure Private Endpoint details
  privatelink_byoe = {
    (local.pe1) = {
      azure_private_endpoint_id         = azurerm_private_endpoint.custom.id
      azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
    }
  }
  privatelink_byoe_regions = { (local.pe1) = var.azure_location }
}

# User-managed Azure Private Endpoint with custom configuration
resource "azurerm_private_endpoint" "custom" {
  name                = "pe-atlas-static-ip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = module.atlas_azure.privatelink_service_info[local.pe1].atlas_endpoint_service_name
    private_connection_resource_id = module.atlas_azure.privatelink_service_info[local.pe1].atlas_private_link_service_resource_id
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
  value       = module.atlas_azure.privatelink[local.pe1]
}

output "static_ip" {
  description = "Static IP address of the private endpoint"
  value       = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}
