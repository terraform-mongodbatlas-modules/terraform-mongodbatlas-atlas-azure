mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

run "rejects_create_key_vault" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    skip_role_assignments    = true
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
    encryption = {
      enabled = true
      create_key_vault = {
        enabled             = true
        name                = "testkv"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.skip_role_assignments
  ]
}

run "rejects_backup_export_create_storage" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    skip_role_assignments    = true
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
    backup_export = {
      enabled        = true
      container_name = "export"
      create_storage_account = {
        enabled             = true
        name                = "stacct"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.skip_role_assignments
  ]
}

run "rejects_log_integration_create_storage" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    skip_role_assignments    = true
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
    log_integration = {
      enabled        = true
      container_name = "logs"
      integrations = [
        { log_types = ["MONGOD"], prefix_path = "p" }
      ]
      create_storage_account = {
        enabled             = true
        name                = "stlog"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.skip_role_assignments
  ]
}

run "rejects_create_service_principal" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id            = var.project_id
    skip_role_assignments = true
  }

  expect_failures = [
    var.skip_role_assignments
  ]
}

run "byo_encryption_with_skip_plans" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    skip_role_assignments    = true
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key"
    }
  }

  assert {
    condition     = length(module.encryption) == 1 && output.encryption_at_rest_provider == "AZURE"
    error_message = "Expected encryption and AZURE EAR with BYO + skip"
  }
}

run "byo_read_only_encryption_backup_log_plans" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    skip_role_assignments    = true
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key"
    }
    backup_export = {
      enabled            = true
      container_name     = "atlas-backup-exports"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sabackup"
    }
    log_integration = {
      enabled            = true
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/salog"
      container_name     = "atlas-logs"
      integrations = [
        { log_types = ["MONGOD"], prefix_path = "operational" },
        { log_types = ["MONGOD_AUDIT"], prefix_path = "audit" },
      ]
    }
  }

  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module with BYO + skip (read-only path)"
  }

  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module with BYO + skip (read-only path)"
  }

  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module with BYO + skip (read-only path)"
  }
}
