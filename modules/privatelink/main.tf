locals {
  # Azure subnet ID format:
  # /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}
  # Index 4 of split("/", subnet_id) corresponds to {resourceGroupName}
  # Using try() to gracefully handle malformed subnet IDs - validation in precondition will catch the issue later
  subnet_id_parts     = var.subnet_id != null ? split("/", var.subnet_id) : []
  resource_group_name = var.create_azure_private_endpoint ? try(local.subnet_id_parts[4], null) : null

  # Resolve endpoint values from either created resource or provided inputs
  private_link_id                  = var.use_existing_endpoint ? var.private_link_id : mongodbatlas_privatelink_endpoint.this[0].private_link_id
  private_link_service_name        = var.use_existing_endpoint ? var.private_link_service_name : mongodbatlas_privatelink_endpoint.this[0].private_link_service_name
  private_link_service_resource_id = var.use_existing_endpoint ? var.private_link_service_resource_id : mongodbatlas_privatelink_endpoint.this[0].private_link_service_resource_id
}

# Only created in standalone mode (use_existing_endpoint = false)
resource "mongodbatlas_privatelink_endpoint" "this" {
  count = var.use_existing_endpoint ? 0 : 1

  project_id    = var.project_id
  provider_name = "AZURE"
  region        = var.azure_location
}

resource "azurerm_private_endpoint" "atlas" {
  count = var.create_azure_private_endpoint ? 1 : 0

  name                = coalesce(var.azure_private_endpoint_name, "pe-atlas-${var.azure_location}")
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.azure_private_endpoint_tags

  private_service_connection {
    name                           = local.private_link_service_name
    private_connection_resource_id = local.private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "MongoDB Atlas PrivateLink"
  }

  lifecycle {
    precondition {
      condition     = var.subnet_id != null
      error_message = "create_azure_private_endpoint=true requires subnet_id."
    }
    precondition {
      condition     = var.subnet_id == null || length(local.subnet_id_parts) >= 9
      error_message = "subnet_id must be a valid Azure subnet resource ID: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
    }
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id      = var.project_id
  private_link_id = local.private_link_id
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
        var.azure_private_endpoint_id != null && var.azure_private_endpoint_id != "" &&
        var.azure_private_endpoint_ip_address != null && var.azure_private_endpoint_ip_address != ""
      )
      error_message = "BYOE mode (create_azure_private_endpoint=false) requires both azure_private_endpoint_id and azure_private_endpoint_ip_address with non-empty values."
    }
    precondition {
      condition     = !(var.subnet_id != null && var.azure_private_endpoint_id != null)
      error_message = "Cannot use both subnet_id (module-managed) and azure_private_endpoint_id (BYOE)."
    }
    precondition {
      condition     = var.create_azure_private_endpoint || var.subnet_id == null
      error_message = "subnet_id is only used when create_azure_private_endpoint=true."
    }
    precondition {
      condition = !var.use_existing_endpoint || (
        var.private_link_id != null &&
        var.private_link_service_name != null &&
        var.private_link_service_resource_id != null
      )
      error_message = "use_existing_endpoint=true requires private_link_id, private_link_service_name, and private_link_service_resource_id."
    }
  }
}
