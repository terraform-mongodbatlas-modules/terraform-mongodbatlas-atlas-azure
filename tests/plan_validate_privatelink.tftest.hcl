mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id = "000000000000000000000000"
}

run "valid_single_region_module_managed" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode with a single module-managed region and default privatelink_regional_mode"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false for single service region and default privatelink_regional_mode"
  }
}

run "multi_region_regional_mode_disabled_by_default" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
      { region = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
    ]
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected two privatelink module instances for two distinct regions"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected two Atlas privatelink endpoints for two distinct regions"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode for multi-region when default privatelink_regional_mode is used"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false when default privatelink_regional_mode is used with two regions"
  }
}

run "valid_multi_region_module_managed" {
  command = plan
  variables {
    privatelink_regional_mode = "auto"
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
      { region = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected two privatelink module instances"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 1
    error_message = "Expected regional_mode to be enabled"
  }
  assert {
    condition     = output.regional_mode_enabled
    error_message = "Expected regional_mode_enabled true for privatelink_regional_mode auto and multiple service regions"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected two Atlas privatelink endpoints for two distinct regions"
  }
}

run "valid_atlas_region_format" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "US_EAST_2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode with a single module-managed region and default privatelink_regional_mode"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false for single service region and default privatelink_regional_mode"
  }
}

run "valid_custom_name_and_tags" {
  command = plan
  variables {
    privatelink_endpoints = [
      {
        region    = "eastus2"
        subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        name      = "my-custom-pe"
        tags      = { env = "prod", team = "data" }
      }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode with a single module-managed region and default privatelink_regional_mode"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false for single service region and default privatelink_regional_mode"
  }
}

run "valid_byoe" {
  command = plan
  variables {
    privatelink_byo_endpoint = { pe_byoe = { region = "eastus2" } }
    privatelink_byo_service = {
      pe_byoe = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode for single-region BYOE and default privatelink_regional_mode"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false for single service region and default privatelink_regional_mode"
  }
}

run "invalid_byoe_key_not_in_regions" {
  command = plan
  variables {
    privatelink_byo_endpoint = { mykey = { region = "eastus2" } }
    privatelink_byo_service = {
      wrong_key = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  expect_failures = [var.privatelink_byo_service]
}

run "invalid_byoe_region_overlaps_privatelink_endpoints" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
    privatelink_byo_endpoint = { pe1 = { region = "eastus2" } }
  }
  expect_failures = [var.privatelink_byo_endpoint]
}

run "invalid_duplicate_regions" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

# Single-region multi-endpoint pattern tests

run "valid_single_region_multi_endpoint" {
  command = plan
  variables {
    privatelink_endpoints_single_region = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" },
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected two privatelink module instances"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected two Atlas endpoints (one per index in same region)"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 0
    error_message = "Expected no private_endpoint_regional_mode for single-region multi-endpoint and default privatelink_regional_mode"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional_mode_enabled false for single service region and default privatelink_regional_mode"
  }
}

run "invalid_single_region_different_locations" {
  command = plan
  variables {
    privatelink_endpoints_single_region = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" },
      { region = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

run "invalid_both_privatelink_variables" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
    privatelink_endpoints_single_region = [
      { region = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

# ─────────────────────────────────────────────────────────────────────────────
# Region Validation Check Block Tests
# ─────────────────────────────────────────────────────────────────────────────

run "invalid_privatelink_region_format" {
  command = plan
  variables {
    privatelink_endpoints = [
      { region = "invalid-region-xyz", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [terraform_data.region_validations]
}

run "invalid_byoe_region_format" {
  command = plan
  variables {
    privatelink_byo_endpoint = { pe1 = { region = "not_a_real_region" } }
    privatelink_byo_service = {
      pe1 = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  expect_failures = [terraform_data.region_validations]
}
