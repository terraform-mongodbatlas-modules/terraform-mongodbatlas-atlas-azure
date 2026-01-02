# Module-managed storage account (recommended for simplicity)
module "atlas_azure" {
  source     = "../../"
  project_id = var.project_id

  backup_export = {
    enabled        = true
    container_name = "atlas-backup-exports"
    create_storage_account = {
      enabled             = true
      name                = var.storage_account_name
      resource_group_name = var.resource_group_name
      azure_location      = var.azure_location
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Alternative: User-provided storage account (uncomment to use)
# ─────────────────────────────────────────────────────────────────────────────
# resource "azurerm_storage_account" "backup" {
#   name                     = var.storage_account_name
#   resource_group_name      = var.resource_group_name
#   location                 = var.azure_location
#   account_tier             = "Standard"
#   account_replication_type = "GRS"  # Geo-redundant for backup data
#   min_tls_version          = "TLS1_2"
# }
#
# module "atlas_azure" {
#   source     = "../../"
#   project_id = var.project_id
#
#   backup_export = {
#     enabled            = true
#     container_name     = "atlas-backup-exports"
#     storage_account_id = azurerm_storage_account.backup.id
#     create_container   = true  # Module creates container, or false if pre-existing
#   }
# }

output "backup_export" {
  value = module.atlas_azure.backup_export
}

output "export_bucket_id" {
  value = module.atlas_azure.export_bucket_id
}
