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

run "encryption_enabled_for_search_nodes_default_true" {
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
    condition     = output.encryption.enabled_for_search_nodes == true
    error_message = "Expected enabled_for_search_nodes to default to true"
  }
}

run "encryption_enabled_for_search_nodes_explicit_false" {
  command = plan

  variables {
    project_id               = var.project_id
    encryption_client_secret = "test-secret-value"
    encryption = {
      enabled                  = true
      key_vault_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier           = "https://kv.vault.azure.net/keys/my-key"
      enabled_for_search_nodes = false
    }
  }

  assert {
    condition     = output.encryption.enabled_for_search_nodes == false
    error_message = "Expected enabled_for_search_nodes to be false when explicitly set"
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
      private_endpoint_regions = ["US_EAST_2", "EUROPE_WEST"]
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

  assert {
    condition     = contains(keys(module.encryption_private_endpoint), "eastus2") && contains(keys(module.encryption_private_endpoint), "westeurope")
    error_message = "Expected encryption private endpoint module keys to use Azure location format"
  }
}

run "encryption_private_networking_azure_format" {
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
      private_endpoint_regions = ["eastus2", "westeurope"]
    }
  }

  assert {
    condition     = length(module.encryption_private_endpoint) == 2
    error_message = "Expected 2 private endpoints with Azure format regions"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Region Validation Check Block Tests
# ─────────────────────────────────────────────────────────────────────────────

run "invalid_encryption_region_format" {
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
      private_endpoint_regions = ["invalid_region_xyz"]
    }
  }

  expect_failures = [terraform_data.region_validations]
}

run "invalid_encryption_multiple_bad_regions" {
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
      private_endpoint_regions = ["bad_region_1", "eastus2", "another_bad"]
    }
  }

  expect_failures = [terraform_data.region_validations]
}
