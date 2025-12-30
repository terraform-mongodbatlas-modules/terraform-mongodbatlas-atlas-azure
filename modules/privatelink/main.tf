locals {
  resource_group_name = var.create_azure_private_endpoint ? element(split("/", var.subnet_id), 4) : null
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  project_id    = var.project_id
  provider_name = "AZURE"
  region        = var.azure_location
}

resource "azurerm_private_endpoint" "atlas" {
  count = var.create_azure_private_endpoint ? 1 : 0

  name                = "pe-atlas-${var.azure_location}"
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = mongodbatlas_privatelink_endpoint.this.private_link_service_name
    private_connection_resource_id = mongodbatlas_privatelink_endpoint.this.private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "MongoDB Atlas PrivateLink"
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id      = var.project_id
  private_link_id = mongodbatlas_privatelink_endpoint.this.private_link_id
  provider_name   = "AZURE"

  endpoint_service_id = var.create_azure_private_endpoint ? (
    azurerm_private_endpoint.atlas[0].id
  ) : var.azure_private_endpoint_id

  private_endpoint_ip_address = var.create_azure_private_endpoint ? (
    azurerm_private_endpoint.atlas[0].private_service_connection[0].private_ip_address
  ) : var.azure_private_endpoint_ip_address
}
