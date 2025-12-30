locals {
  resource_group_name = var.create_azure_private_endpoint ? element(split("/", var.subnet_id), 4) : null
}

resource "azurerm_private_endpoint" "atlas" {
  count = var.create_azure_private_endpoint ? 1 : 0

  name                = "pe-atlas-${var.azure_location}"
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.private_link_service_name
    private_connection_resource_id = var.private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "MongoDB Atlas PrivateLink"
  }

  lifecycle {
    precondition {
      condition     = var.subnet_id != null
      error_message = "create_azure_private_endpoint=true requires subnet_id."
    }
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id      = var.project_id
  private_link_id = var.private_link_id
  provider_name   = "AZURE"

  endpoint_service_id = var.create_azure_private_endpoint ? (
    azurerm_private_endpoint.atlas[0].id
  ) : var.azure_private_endpoint_id

  private_endpoint_ip_address = var.create_azure_private_endpoint ? (
    azurerm_private_endpoint.atlas[0].private_service_connection[0].private_ip_address
  ) : var.azure_private_endpoint_ip_address

  lifecycle {
    precondition {
      condition = var.create_azure_private_endpoint || (
        var.azure_private_endpoint_id != null &&
        var.azure_private_endpoint_ip_address != null
      )
      error_message = "BYOE mode (create_azure_private_endpoint=false) requires both azure_private_endpoint_id and azure_private_endpoint_ip_address."
    }
    precondition {
      condition     = !(var.subnet_id != null && var.azure_private_endpoint_id != null)
      error_message = "Cannot use both subnet_id (module-managed) and azure_private_endpoint_id (BYOE)."
    }
    precondition {
      condition     = var.create_azure_private_endpoint || var.subnet_id == null
      error_message = "subnet_id is only used when create_azure_private_endpoint=true."
    }
  }
}
