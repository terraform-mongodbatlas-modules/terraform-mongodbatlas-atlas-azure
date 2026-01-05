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
    privatelink_locations = ["eastus2"]
    privatelink_module_managed_subnet_ids = {
      eastus2 = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
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
    privatelink_locations = ["eastus2", "westeurope"]
    privatelink_module_managed_subnet_ids = {
      eastus2    = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
      westeurope = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
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

run "valid_byoe" {
  command = plan

  variables {
    privatelink_locations = ["eastus2"]
    privatelink_byoe_locations = {
      eastus2 = {
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

run "invalid_byoe_location_format" {
  command = plan

  variables {
    privatelink_locations = []
    privatelink_byoe_locations = {
      "East US 2" = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }

  expect_failures = [var.privatelink_byoe_locations]
}

run "invalid_byoe_location_not_in_privatelink_locations" {
  command = plan

  variables {
    privatelink_locations = ["eastus2"]
    privatelink_byoe_locations = {
      westeurope = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }

  expect_failures = [var.privatelink_byoe_locations]
}
run "invalid_byoe_location_missing_from_privatelink_locations" {
  command = plan

  variables {
    privatelink_byoe_locations = {
      westeurope = {
        azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
        azure_private_endpoint_ip_address = "10.0.1.100"
      }
    }
  }

  expect_failures = [var.privatelink_byoe_locations]
}

run "invalid_privatelink_locations_format" {
  command = plan

  variables {
    privatelink_locations = ["East US 2"]
  }

  expect_failures = [var.privatelink_locations]
}

run "invalid_module_managed_subnet_ids_location_format" {
  command = plan

  variables {
    privatelink_module_managed_subnet_ids = {
      "East US 2" = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
    }
  }

  expect_failures = [var.privatelink_module_managed_subnet_ids]
}
