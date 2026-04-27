output "export_bucket_id" {
  description = "Atlas export bucket ID for backup schedule auto_export_enabled"
  value       = mongodbatlas_cloud_backup_snapshot_export_bucket.this.export_bucket_id
}

output "storage_account_id" {
  description = "Storage account resource ID (user-provided or module-created)"
  value       = local.storage_account_id
}

output "container_name" {
  description = "Storage container name for backup exports"
  value       = var.container_name
}

output "service_url" {
  description = "Storage account primary blob endpoint URL"
  value       = mongodbatlas_cloud_backup_snapshot_export_bucket.this.service_url
}

output "expiration_days" {
  description = "Backup export blob retention days (null if not module-managed storage)"
  value       = local.create_storage_account ? var.create_storage_account.expiration_days : null
}
