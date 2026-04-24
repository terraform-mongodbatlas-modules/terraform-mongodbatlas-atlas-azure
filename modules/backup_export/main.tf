locals {
  create_storage_account = var.create_storage_account != null && var.create_storage_account.enabled
  storage_account_id     = local.create_storage_account ? azurerm_storage_account.atlas[0].id : var.storage_account_id
  storage_account_name   = local.create_storage_account ? azurerm_storage_account.atlas[0].name : element(split("/", var.storage_account_id), 8)
  create_container       = local.create_storage_account || var.create_container
  expiration_days        = local.create_storage_account ? var.create_storage_account.expiration_days : 0
}

data "azurerm_storage_account" "existing" {
  count = local.create_storage_account ? 0 : 1
  name  = local.storage_account_name
  # Resource group extracted from storage account ID (index 4)
  resource_group_name = element(split("/", var.storage_account_id), 4)
}

resource "azurerm_storage_account" "atlas" {
  count = local.create_storage_account ? 1 : 0

  name                            = var.create_storage_account.name
  resource_group_name             = var.create_storage_account.resource_group_name
  location                        = var.create_storage_account.azure_location
  account_tier                    = var.create_storage_account.account_tier
  account_replication_type        = var.create_storage_account.replication_type
  min_tls_version                 = var.create_storage_account.min_tls_version
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  tags                            = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      delete = var.timeouts.delete
      update = var.timeouts.update
    }
  }
}

resource "azurerm_storage_container" "atlas" {
  count = local.create_container ? 1 : 0

  name                  = var.container_name
  storage_account_id    = local.storage_account_id
  container_access_type = "private"

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      delete = var.timeouts.delete
      update = var.timeouts.update
    }
  }
}

resource "azurerm_storage_management_policy" "atlas" {
  count = local.create_storage_account && local.expiration_days > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.atlas[0].id

  rule {
    name    = "atlas-backup-export-expiration"
    enabled = true

    filters {
      prefix_match = ["${var.container_name}/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = local.expiration_days
      }
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      delete = var.timeouts.delete
      update = var.timeouts.update
    }
  }
}

resource "azurerm_role_assignment" "backup_export" {
  principal_id         = var.service_principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = local.storage_account_id

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      delete = var.timeouts.delete
    }
  }
}

resource "mongodbatlas_cloud_backup_snapshot_export_bucket" "this" {
  project_id     = var.project_id
  bucket_name    = var.container_name
  cloud_provider = "AZURE"
  # trimsuffix: Azure primary_blob_endpoint includes trailing slash, Atlas doesn't expect it
  service_url = trimsuffix(
    local.create_storage_account ? azurerm_storage_account.atlas[0].primary_blob_endpoint : data.azurerm_storage_account.existing[0].primary_blob_endpoint,
    "/"
  )
  role_id = var.role_id

  depends_on = [azurerm_role_assignment.backup_export]
}
