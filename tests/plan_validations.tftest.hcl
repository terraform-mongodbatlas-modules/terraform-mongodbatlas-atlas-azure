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

run "skip_cloud_provider_access" {
  command = plan

  module {
    source = "./"
  }

  variables {
    project_id                 = var.project_id
    skip_cloud_provider_access = true
  }

  assert {
    condition     = length(azuread_service_principal.atlas) == 0
    error_message = "Expected no service principal when skipping cloud_provider_access"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_setup.this) == 0
    error_message = "Expected no cloud_provider_access_setup when skipping"
  }

  assert {
    condition     = length(mongodbatlas_cloud_provider_access_authorization.this) == 0
    error_message = "Expected no cloud_provider_access_authorization when skipping"
  }
}
