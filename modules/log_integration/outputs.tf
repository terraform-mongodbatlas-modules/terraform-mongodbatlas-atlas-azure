output "storage_account_id" {
  description = "Storage account resource ID (user-provided or module-created)"
  value       = local.storage_account_id
}

output "container_name" {
  description = "Storage container name for log exports"
  value       = var.container_name
}

output "service_url" {
  description = "Storage account primary blob endpoint URL"
  value = trimsuffix(
    local.create_storage_account ? azurerm_storage_account.atlas[0].primary_blob_endpoint : data.azurerm_storage_account.existing[0].primary_blob_endpoint,
    "/"
  )
}

output "integration_ids" {
  description = "Atlas log integration IDs"
  value       = mongodbatlas_log_integration.this[*].integration_id
}

output "expiration_days" {
  description = "Log expiration days (null if not module-managed)"
  value       = local.create_storage_account ? var.create_storage_account.expiration_days : null
}
