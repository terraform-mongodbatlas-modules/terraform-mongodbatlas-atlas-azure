mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

run "missing_service_principal_id_when_create_false" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    create_service_principal = false
    # service_principal_id not set - should fail validation
  }

  expect_failures = [
    var.create_service_principal
  ]
}

run "valid_config_create_service_principal_default" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    # create_service_principal defaults to true
  }

  assert {
    condition     = length(azuread_service_principal.atlas) == 1
    error_message = "Expected service principal to be created when create_service_principal=true"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 1
    error_message = "Expected cloud_provider_access_setup to be created"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_authorization.this) == 1
    error_message = "Expected cloud_provider_access_authorization to be created"
  }
}

run "valid_config_with_existing_service_principal" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(azuread_service_principal.atlas) == 0
    error_message = "Expected no service principal to be created when using existing"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 1
    error_message = "Expected cloud_provider_access_setup to be created"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_authorization.this) == 1
    error_message = "Expected cloud_provider_access_authorization to be created"
  }
}

run "dynamic_skip_cloud_provider_access_privatelink_only" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    # Only privatelink configured - cloud_provider_access should be automatically skipped
    privatelink_endpoints = {
      eastus2 = { subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }

  assert {
    condition     = length(azuread_service_principal.atlas) == 0
    error_message = "Expected no service principal when only privatelink is configured"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 0
    error_message = "Expected no cloud_provider_access_setup when only privatelink is configured"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_authorization.this) == 0
    error_message = "Expected no cloud_provider_access_authorization when only privatelink is configured"
  }

  assert {
    condition     = output.role_id == null
    error_message = "Expected role_id to be null when cloud_provider_access is skipped"
  }

  assert {
    condition     = output.service_principal_id == null
    error_message = "Expected service_principal_id to be null when cloud_provider_access is skipped"
  }

  assert {
    condition     = output.service_principal_resource_id == null
    error_message = "Expected service_principal_resource_id to be null when cloud_provider_access is skipped"
  }

  assert {
    condition     = output.authorized_date == null
    error_message = "Expected authorized_date to be null when cloud_provider_access is skipped"
  }

  assert {
    condition     = output.feature_usages == null
    error_message = "Expected feature_usages to be null when cloud_provider_access is skipped"
  }
}

run "dynamic_enable_cloud_provider_access_encryption" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    encryption_client_secret = "test-secret"
    encryption = {
      enabled        = true
      key_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier = "https://kv.vault.azure.net/keys/my-key"
    }
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 1
    error_message = "Expected cloud_provider_access when encryption is enabled"
  }
}

run "dynamic_enable_cloud_provider_access_backup_export" {
  command = plan

  module {
    source = "./"
  }

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
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 1
    error_message = "Expected cloud_provider_access when backup_export is enabled"
  }
}
