mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id                 = "000000000000000000000000"
  skip_cloud_provider_access = true
}

run "valid_single_region_module_managed" {
  command = plan
  variables {
    privatelink_endpoints = {
      eastus2 = { subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_module_managed_with_explicit_location" {
  command = plan
  variables {
    privatelink_endpoints = {
      pe1 = { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_multi_region_module_managed" {
  command = plan
  variables {
    privatelink_endpoints = {
      eastus2    = { subnet_id = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
      westeurope = { subnet_id = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
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

run "valid_multiple_endpoints_same_location" {
  command = plan
  variables {
    privatelink_endpoints = {
      pe_app1 = { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/snet" }
      pe_app2 = { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/snet" }
    }
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected two privatelink module instances"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected two Atlas endpoints (one per key in same region)"
  }
}

run "valid_custom_name_and_tags" {
  command = plan
  variables {
    privatelink_endpoints = {
      eastus2 = {
        subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        name      = "my-custom-pe"
        tags      = { env = "prod", team = "data" }
      }
    }
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_byoe" {
  command = plan
  variables {
    privatelink_byoe_locations = { pe_byoe = "eastus2" }
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

run "valid_byoe_location_only" {
  command = plan
  variables {
    privatelink_byoe_locations = { myregion = "eastus2" }
    privatelink_byoe = {
      myregion = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected one Atlas endpoint"
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module for BYOE"
  }
}

run "invalid_byoe_key_not_in_locations" {
  command = plan
  variables {
    privatelink_byoe_locations = { mykey = "eastus2" }
    privatelink_byoe = {
      wrong_key = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "invalid_byoe_locations_format" {
  command = plan
  variables {
    privatelink_byoe_locations = { myregion = "East US 2" }
  }
  expect_failures = [var.privatelink_byoe_locations]
}

run "invalid_privatelink_endpoints_location_format" {
  command = plan
  variables {
    privatelink_endpoints = {
      pe = { azure_location = "East US 2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }
  expect_failures = [var.privatelink_endpoints]
}

run "invalid_privatelink_endpoints_key_format" {
  command = plan
  variables {
    privatelink_endpoints = {
      "East US 2" = { subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }
  expect_failures = [var.privatelink_endpoints]
}

run "invalid_duplicate_keys_locations_endpoints" {
  command = plan
  variables {
    privatelink_byoe_locations = { same_key = "eastus2" }
    privatelink_endpoints = {
      same_key = { azure_location = "eastus2", subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
    }
  }
  expect_failures = [var.privatelink_byoe_locations]
}
