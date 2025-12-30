mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  project_id                 = "000000000000000000000000"
  skip_cloud_provider_access = true
}

run "valid_single_region" {
  command = plan

  variables {
    privatelink = {
      enabled        = true
      azure_location = "eastus2"
      subnet_id      = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
    }
  }

  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "valid_multi_region" {
  command = plan

  variables {
    privatelink = {
      enabled        = true
      azure_location = "eastus2"
      subnet_id      = "/subscriptions/sub/resourceGroups/rg-east/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
      additional_regions = {
        westeurope = {
          subnet_id = "/subscriptions/sub/resourceGroups/rg-west/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        }
      }
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
    privatelink = {
      enabled                           = true
      azure_location                    = "eastus2"
      create_azure_private_endpoint     = false
      azure_private_endpoint_id         = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
      azure_private_endpoint_ip_address = "10.0.1.100"
    }
  }

  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected one privatelink module instance"
  }
}

run "invalid_missing_azure_location" {
  command = plan

  variables {
    privatelink = {
      enabled   = true
      subnet_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
    }
  }

  expect_failures = [var.privatelink]
}

run "invalid_missing_subnet_id" {
  command = plan

  variables {
    privatelink = {
      enabled        = true
      azure_location = "eastus2"
    }
  }

  expect_failures = [var.privatelink]
}

run "invalid_byoe_missing_ip" {
  command = plan

  variables {
    privatelink = {
      enabled                       = true
      azure_location                = "eastus2"
      create_azure_private_endpoint = false
      azure_private_endpoint_id     = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe-atlas"
    }
  }

  expect_failures = [var.privatelink]
}

run "invalid_azure_location_format" {
  command = plan

  variables {
    privatelink = {
      enabled        = true
      azure_location = "East US 2"
      subnet_id      = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
    }
  }

  expect_failures = [var.privatelink]
}
