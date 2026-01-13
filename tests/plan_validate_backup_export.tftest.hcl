mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

# ─────────────────────────────────────────────────────────────────────────────
# Validation Error Tests
# ─────────────────────────────────────────────────────────────────────────────

run "backup_export_enabled_without_storage_source" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled        = true
      container_name = "test-container"
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_both_storage_account_id_and_create_storage_account" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled            = true
      container_name     = "test-container"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/teststorage"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_enabled_without_container_name" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_create_container_false_without_storage_account_id" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      container_name   = "test-container"
      create_container = false
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_invalid_storage_account_id_format" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled            = true
      container_name     = "test-container"
      storage_account_id = "invalid-format"
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_invalid_azure_location_format" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled        = true
      container_name = "test-container"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "East US 2"
      }
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_fails_when_skip_cloud_provider_access" {
  command = plan

  variables {
    project_id                 = var.project_id
    skip_cloud_provider_access = true
    privatelink_endpoints = {
      eastus2 = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet" }
    }
    backup_export = {
      enabled        = true
      container_name = "test-container"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.skip_cloud_provider_access
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Valid Configuration Tests
# ─────────────────────────────────────────────────────────────────────────────

run "backup_export_disabled_default" {
  command = plan

  variables {
    project_id = var.project_id
  }

  assert {
    condition     = length(module.backup_export) == 0
    error_message = "Expected no backup_export module when disabled"
  }

  assert {
    condition     = output.export_bucket_id == null
    error_message = "Expected export_bucket_id to be null when disabled"
  }
}

run "backup_export_module_managed_storage" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled        = true
      container_name = "atlas-backups"
      create_storage_account = {
        enabled             = true
        name                = "atlasbackups"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module to be created"
  }
}

run "backup_export_user_provided_storage" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled            = true
      container_name     = "atlas-backups"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/existingstorage"
      create_container   = true
    }
  }

  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module to be created"
  }
}

run "backup_export_user_provided_storage_existing_container" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled            = true
      container_name     = "existing-container"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/existingstorage"
      create_container   = false
    }
  }

  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module to be created"
  }
}
