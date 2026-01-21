output "id" {
  description = "Atlas encryption private endpoint ID"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.id
}

output "status" {
  description = "Atlas encryption private endpoint status"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.status
}

output "error_message" {
  description = "Error message if private endpoint creation failed"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.error_message
}

output "private_endpoint_connection_name" {
  description = "Azure private endpoint connection name"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.private_endpoint_connection_name
}
