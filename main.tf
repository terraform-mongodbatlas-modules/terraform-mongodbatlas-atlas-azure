data "azurerm_client_config" "current" {}

resource "azuread_service_principal" "atlas" {
  count = var.create_service_principal && !var.skip_cloud_provider_access ? 1 : 0

  client_id                    = var.atlas_azure_app_id
  app_role_assignment_required = false
}

resource "mongodbatlas_cloud_provider_access_setup" "this" {
  count = !var.skip_cloud_provider_access ? 1 : 0

  project_id    = var.project_id
  provider_name = "AZURE"

  azure_config {
    atlas_azure_app_id   = var.atlas_azure_app_id
    service_principal_id = local.service_principal_id
    tenant_id            = local.tenant_id
  }
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  count = !var.skip_cloud_provider_access ? 1 : 0

  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.this[0].role_id

  azure {
    atlas_azure_app_id   = var.atlas_azure_app_id
    service_principal_id = local.service_principal_id
    tenant_id            = local.tenant_id
  }
}
