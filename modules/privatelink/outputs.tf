output "atlas_private_link_id" {
  description = "Atlas PrivateLink connection ID"
  value       = local.private_link_id
}

output "atlas_private_link_service_name" {
  description = "Name of the Azure Private Link Service that Atlas manages"
  value       = local.private_link_service_name
}

output "atlas_private_link_service_resource_id" {
  description = "Azure resource ID of the Atlas-managed Private Link Service"
  value       = local.private_link_service_resource_id
}

output "azure_private_endpoint_id" {
  description = "Azure private endpoint resource ID"
  value       = var.create_azure_private_endpoint ? azurerm_private_endpoint.atlas[0].id : var.azure_private_endpoint_id
}

output "azure_private_endpoint_ip_address" {
  description = "Private IP address of the Azure private endpoint"
  value = var.create_azure_private_endpoint ? (
    azurerm_private_endpoint.atlas[0].private_service_connection[0].private_ip_address
  ) : var.azure_private_endpoint_ip_address
}

output "status" {
  description = "Status of the PrivateLink connection"
  value       = mongodbatlas_privatelink_endpoint_service.this.azure_status
}

output "error_message" {
  description = "Error message if connection failed"
  value       = mongodbatlas_privatelink_endpoint_service.this.error_message
}
