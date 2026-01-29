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
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_multi_region_module_managed" {
  command = plan
  variables {
    privatelink_endpoints = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
      { azure_location = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
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
}

run "valid_custom_name_and_tags" {
  command = plan
  variables {
    privatelink_endpoints = [
      {
        azure_location = "eastus2"
        subnet_id      = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        name           = "my-custom-pe"
        tags           = { env = "prod", team = "data" }
      }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_byoe" {
  command = plan
  variables {
    privatelink_byoe_regions = { pe_byoe = "eastus2" }
    privatelink_byoe = {
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
}

run "invalid_byoe_key_not_in_regions" {
  command = plan
  variables {
    privatelink_byoe_regions = { mykey = "eastus2" }
    privatelink_byoe = {
      wrong_key = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "invalid_byoe_regions_format" {
  command = plan
  variables {
    privatelink_byoe_regions = { myregion = "East US 2" }
  }
  expect_failures = [var.privatelink_byoe_regions]
}

run "invalid_privatelink_endpoints_location_format" {
  command = plan
  variables {
    privatelink_endpoints = [
      { azure_location = "East US 2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

run "invalid_duplicate_keys_regions_endpoints" {
  command = plan
  variables {
    privatelink_byoe_regions = { eastus2 = "eastus2" }
    privatelink_endpoints = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_byoe_regions]
}

# Single-region multi-endpoint pattern tests

run "valid_single_region_multi_endpoint" {
  command = plan
  variables {
    privatelink_endpoints_single_region = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" },
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
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
}

run "invalid_single_region_different_locations" {
  command = plan
  variables {
    privatelink_endpoints_single_region = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" },
      { azure_location = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

run "invalid_both_privatelink_variables" {
  command = plan
  variables {
    privatelink_endpoints = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
    privatelink_endpoints_single_region = [
      { azure_location = "westeurope", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

run "invalid_duplicate_azure_locations" {
  command = plan
  variables {
    privatelink_endpoints = [
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" },
      { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}
