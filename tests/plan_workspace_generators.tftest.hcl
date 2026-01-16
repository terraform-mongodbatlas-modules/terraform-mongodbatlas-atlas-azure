mock_provider "mongodbatlas" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "random" {}

# Validates generator modules work correctly

run "project_generator_valid" {
  command = plan

  module {
    source = "./project_generator"
  }

  variables {
    org_id       = "000000000000000000000000"
    project_name = "test-project"
  }
}

run "resource_group_generator_valid" {
  command = plan

  module {
    source = "./resource_group_generator"
  }

  variables {
    name     = "rg-test"
    location = "eastus2"
  }
}

run "service_principal_generator_valid" {
  command = plan

  module {
    source = "./service_principal_generator"
  }

  variables {
    atlas_azure_app_id = "9f2deb0d-be22-4524-a403-df531868bac0"
  }
}
