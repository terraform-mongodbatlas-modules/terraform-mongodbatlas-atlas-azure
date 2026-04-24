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
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
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
    condition     = output.cloud_provider_access == null
    error_message = "Expected cloud_provider_access to be null when skipped"
  }
}

run "dynamic_enable_cloud_provider_access_encryption" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
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

run "dynamic_enable_cloud_provider_access_log_integration" {
  command = plan

  module {
    source = "./"
  }

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
        { log_types = ["MONGOD"], prefix_path = "mongod/" }
      ]
    }
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 1
    error_message = "Expected cloud_provider_access when log_integration is enabled"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Region Normalization Validations (preconditions on terraform_data)
# ─────────────────────────────────────────────────────────────────────────────

run "region_unknown_privatelink_rejected" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "invalid-region", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  expect_failures = [terraform_data.region_validations]
}

run "region_unknown_single_region_rejected" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    privatelink_endpoints_single_region = [
      { region = "invalid-region", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  expect_failures = [terraform_data.region_validations]
}

run "region_unknown_byoe_rejected" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id               = var.project_id
    privatelink_byo_endpoint = { primary = { region = "invalid-region" } }
    privatelink_byo_service = {
      primary = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe"
        azure_private_endpoint_ip_address = "10.0.0.1"
      }
    }
  }

  expect_failures = [terraform_data.region_validations]
}

run "region_unknown_encryption_rejected" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = true
      key_vault_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
      key_identifier           = "https://kv.vault.azure.net/keys/my-key"
      private_endpoint_regions = ["invalid-region"]
    }
  }

  expect_failures = [terraform_data.region_validations]
}

run "region_atlas_format_accepted" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "US_EAST_2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one privatelink endpoint with Atlas format region"
  }
}

run "region_azure_format_accepted" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one privatelink endpoint with Azure format region"
  }
}

run "region_custom_mapping_override" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    atlas_to_azure_region = {
      US_EAST_2 = "eastus2"
    }
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one privatelink endpoint with custom mapping"
  }

  assert {
    condition     = mongodbatlas_privatelink_endpoint.this["eastus2"].region == "eastus2"
    error_message = "Expected privatelink endpoint region to be the normalized Azure location from custom mapping"
  }
}

run "region_custom_mapping_rejects_unmapped" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    atlas_to_azure_region = {
      US_EAST_2 = "eastus2"
    }
    privatelink_endpoints = [
      { region = "westus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  expect_failures = [terraform_data.region_validations]
}

run "timeouts_null_with_privatelink" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    timeouts   = null
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one privatelink endpoint when timeouts is null"
  }

  assert {
    condition     = try(mongodbatlas_privatelink_endpoint.this["eastus2"].timeouts, null) == null
    error_message = "Expected module-managed timeouts to be omitted when timeouts is null"
  }
}

run "timeouts_empty_object_plans" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    timeouts   = {}
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one privatelink endpoint when timeouts is the empty object"
  }
}

run "timeouts_rejects_blank_duration" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id = var.project_id
    timeouts = {
      create = "   "
    }
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }

  expect_failures = [
    var.timeouts
  ]
}
