output "id" {
  description = "Private endpoint ID"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.id
}

output "status" {
  description = "Private endpoint status"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.status
}

output "error_message" {
  description = "Error message if failed"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.error_message
}

output "private_endpoint_connection_name" {
  description = "Azure private endpoint connection name"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.private_endpoint_connection_name
}
