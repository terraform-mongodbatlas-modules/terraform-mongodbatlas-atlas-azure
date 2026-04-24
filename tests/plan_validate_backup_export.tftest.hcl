mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

run "backup_export_enabled_without_storage_source" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled        = true
      container_name = "atlas-backups"
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

run "backup_export_both_storage_options" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled            = true
      container_name     = "atlas-backups"
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
        name                = "atlasbackups"
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
      container_name     = "atlas-backups"
      storage_account_id = "not-a-resource-id"
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
      container_name   = "atlas-backups"
      create_container = false
      create_storage_account = {
        enabled             = true
        name                = "atlasbackups"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
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
      container_name = "atlas-backups"
      create_storage_account = {
        enabled             = true
        name                = "atlasbackups"
        resource_group_name = "rg"
        azure_location      = "East US 2"
      }
    }
  }

  expect_failures = [
    var.backup_export
  ]
}

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
    condition     = output.backup_export == null
    error_message = "Expected backup_export output to be null when disabled"
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
        name                = "atlasbackups9"
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
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/existingstg"
    }
  }

  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module to be created"
  }
}

run "backup_export_expiration_days_zero" {
  command = plan

  variables {
    project_id = var.project_id
    backup_export = {
      enabled        = true
      container_name = "atlas-backups"
      create_storage_account = {
        enabled             = true
        name                = "atlasbkp01"
        resource_group_name = "rg"
        azure_location      = "eastus2"
        expiration_days     = 0
      }
    }
  }

  assert {
    condition     = module.backup_export[0].expiration_days == 0
    error_message = "expected expiration_days output 0"
  }
}