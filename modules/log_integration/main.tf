locals {
  create_storage_account = var.create_storage_account != null && var.create_storage_account.enabled
  storage_account_id     = local.create_storage_account ? azurerm_storage_account.atlas[0].id : var.storage_account_id
  storage_account_name   = local.create_storage_account ? azurerm_storage_account.atlas[0].name : element(split("/", var.storage_account_id), 8)
  create_container       = local.create_storage_account || var.create_container
  expiration_days        = local.create_storage_account ? var.create_storage_account.expiration_days : 0
  root_resource_group    = var.storage_account_id != null ? element(split("/", var.storage_account_id), 4) : null

  byo_integration_accounts = {
    for i in var.integrations : i.storage_account_name => coalesce(i.resource_group_name, local.root_resource_group)
    if i.storage_account_name != null
  }
}

data "azurerm_storage_account" "existing" {
  count               = local.create_storage_account ? 0 : 1
  name                = local.storage_account_name
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
  public_network_access_enabled   = true # Atlas cannot reach the storage account if public network access is disabled
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
    name    = "atlas-log-expiration"
    enabled = true

    filters {
      # Scope to this container; trailing slash avoids matching a longer container name with the same prefix
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

resource "azurerm_role_assignment" "log_integration" {
  count = !var.skip_role_assignments ? 1 : 0

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

resource "azurerm_role_assignment" "integration_byo" {
  for_each = !var.skip_role_assignments ? local.byo_integration_accounts : {}

  principal_id         = var.service_principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = data.azurerm_storage_account.integration_byo[each.key].id

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [1] : []
    content {
      create = var.timeouts.create
      delete = var.timeouts.delete
    }
  }
}

data "azurerm_storage_account" "integration_byo" {
  for_each = !var.skip_role_assignments ? local.byo_integration_accounts : {}

  name                = each.key
  resource_group_name = each.value
}

resource "mongodbatlas_log_integration" "this" {
  count = length(var.integrations)

  project_id = var.project_id
  type       = "AZURE_LOG_EXPORT"
  role_id    = var.role_id

  storage_account_name   = coalesce(var.integrations[count.index].storage_account_name, local.storage_account_name)
  storage_container_name = coalesce(var.integrations[count.index].container_name, var.container_name)
  # Atlas always writes objects as {prefix}/{relative_path}; a trailing `/` on prefix is redundant for
  # the final key layout, but if we pass it through unchanged Atlas can emit paths like
  # `mongod//{some-test-file}`. Trimming the suffix keeps plans stable and avoids double slashes.
  prefix_path = trimsuffix(var.integrations[count.index].prefix_path, "/")
  log_types   = var.integrations[count.index].log_types

  depends_on = [
    azurerm_role_assignment.log_integration,
    azurerm_role_assignment.integration_byo,
  ]
}
