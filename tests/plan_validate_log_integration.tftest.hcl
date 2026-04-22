mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

# ─────────────────────────────────────────────────────────────────────────────
# Validation Error Tests
# ─────────────────────────────────────────────────────────────────────────────

run "log_integration_enabled_without_storage_source" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled        = true
      container_name = "atlas-logs"
      integrations   = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

run "log_integration_both_storage_options" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled            = true
      container_name     = "atlas-logs"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/teststorage"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

run "log_integration_enabled_without_container_name" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled = true
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

run "log_integration_enabled_without_integrations" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled        = true
      container_name = "atlas-logs"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

run "log_integration_invalid_storage_account_id_format" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled            = true
      container_name     = "atlas-logs"
      storage_account_id = "invalid-format"
      integrations       = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

run "log_integration_invalid_azure_location_format" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled        = true
      container_name = "atlas-logs"
      create_storage_account = {
        enabled             = true
        name                = "teststorage"
        resource_group_name = "rg"
        azure_location      = "East US 2"
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  expect_failures = [
    var.log_integration
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Valid Configuration Tests
# ─────────────────────────────────────────────────────────────────────────────

run "log_integration_disabled_default" {
  command = plan

  variables {
    project_id = var.project_id
  }

  assert {
    condition     = length(module.log_integration) == 0
    error_message = "Expected no log_integration module when disabled"
  }

  assert {
    condition     = output.log_integration == null
    error_message = "Expected log_integration output to be null when disabled"
  }
}

run "log_integration_module_managed_storage" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled        = true
      container_name = "atlas-logs"
      create_storage_account = {
        enabled             = true
        name                = "atlaslogsstorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module to be created"
  }
}

run "log_integration_user_provided_storage" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled            = true
      container_name     = "atlas-logs"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/existingstorage"
      integrations       = [{ log_types = ["MONGOD"], prefix_path = "mongod/" }]
    }
  }

  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module to be created"
  }
}

run "log_integration_multiple_integrations" {
  command = plan

  variables {
    project_id = var.project_id
    log_integration = {
      enabled        = true
      container_name = "atlas-logs"
      create_storage_account = {
        enabled             = true
        name                = "atlaslogsstorage"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      integrations = [
        { log_types = ["MONGOD"], prefix_path = "mongod/" },
        { log_types = ["MONGOD_AUDIT"], prefix_path = "audit/" },
      ]
    }
  }

  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module to be created"
  }
}
