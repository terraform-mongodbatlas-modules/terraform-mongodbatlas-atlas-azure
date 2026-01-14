mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

# ─────────────────────────────────────────────────────────────────────────────
# Validation Error Tests
# ─────────────────────────────────────────────────────────────────────────────

run "encryption_enabled_without_key_source" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_both_key_vault_id_and_create_key_vault" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled      = true
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      create_key_vault = {
        enabled             = true
        name                = "test-kv"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_key_vault_id_without_key_identifier" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled      = true
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_invalid_key_identifier_format" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "invalid-format"
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_key_identifier_with_version" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key/abc123version"
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_invalid_azure_location_format" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
      create_key_vault = {
        enabled             = true
        name                = "test-kv"
        resource_group_name = "rg"
        azure_location      = "East US 2"
      }
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_private_networking_without_enabled" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled                    = false
      require_private_networking = true
      private_endpoint_regions   = ["US_EAST_2"]
    }
  }

  expect_failures = [
    var.encryption
  ]
}

run "encryption_private_networking_without_regions" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
      create_key_vault = {
        enabled             = true
        name                = "test-kv"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      require_private_networking = true
    }
  }

  expect_failures = [
    var.encryption
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Valid Configuration Tests
# ─────────────────────────────────────────────────────────────────────────────

run "encryption_disabled_default" {
  command = plan

  variables {
    project_id = var.project_id
  }

  assert {
    condition     = length(module.encryption) == 0
    error_message = "Expected no encryption module when disabled"
  }

  assert {
    condition     = output.encryption_at_rest_provider == "NONE"
    error_message = "Expected encryption_at_rest_provider to be NONE when disabled"
  }
}

run "encryption_enabled_without_client_secret" {
  command = plan

  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key"
    }
  }

  expect_failures = [
    var.encryption_client_secret
  ]
}

run "encryption_user_provided_key_vault" {
  command = plan

  variables {
    project_id               = var.project_id
    encryption_client_secret = "test-secret-value"
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key"
    }
  }

  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module to be created"
  }

  assert {
    condition     = output.encryption_at_rest_provider == "AZURE"
    error_message = "Expected encryption_at_rest_provider to be AZURE"
  }
}

run "encryption_module_managed_key_vault" {
  command = plan

  variables {
    project_id               = var.project_id
    encryption_client_secret = "test-secret-value"
    encryption = {
      enabled = true
      create_key_vault = {
        enabled             = true
        name                = "test-kv"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
    }
  }

  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module to be created"
  }

  assert {
    condition     = output.encryption_at_rest_provider == "AZURE"
    error_message = "Expected encryption_at_rest_provider to be AZURE"
  }
}

run "encryption_with_private_networking" {
  command = plan

  variables {
    project_id               = var.project_id
    encryption_client_secret = "test-secret-value"
    encryption = {
      enabled = true
      create_key_vault = {
        enabled             = true
        name                = "test-kv"
        resource_group_name = "rg"
        azure_location      = "eastus2"
      }
      require_private_networking = true
      private_endpoint_regions   = ["US_EAST_2", "EUROPE_WEST"]
    }
  }

  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module to be created"
  }

  assert {
    condition     = length(module.encryption_private_endpoint) == 2
    error_message = "Expected 2 private endpoints to be created"
  }
}
