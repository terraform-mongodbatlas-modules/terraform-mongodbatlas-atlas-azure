output "valid" {
  description = "Whether the encryption configuration is valid"
  value       = mongodbatlas_encryption_at_rest.this.azure_key_vault_config[0].valid
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = "AZURE"

  # This output's value is the constant "AZURE" and references no resource. If
  # a consumer passes only this output's value, then Terraform does not order
  # the cluster resource after the encryption-at-rest configuration. The
  # depends_on attribute adds that ordering, so Terraform applies the cluster
  # resource after the encryption-at-rest configuration.
  depends_on = [mongodbatlas_encryption_at_rest.this]
}

output "project_id" {
  description = "Project ID for private endpoint dependencies"
  value       = var.project_id
}

output "key_vault_id" {
  description = "Key Vault resource ID (user-provided or module-created)"
  value       = local.key_vault_id
}

output "key_vault_uri" {
  description = "Key Vault URI (only set if module-created)"
  value       = local.create_key_vault ? azurerm_key_vault.atlas[0].vault_uri : null
}

output "key_identifier" {
  description = "Key Vault key identifier (full URL including version)"
  value       = local.key_identifier
}

output "enabled_for_search_nodes" {
  description = "Whether encryption at rest is enabled for dedicated search nodes"
  value       = mongodbatlas_encryption_at_rest.this.enabled_for_search_nodes
}
