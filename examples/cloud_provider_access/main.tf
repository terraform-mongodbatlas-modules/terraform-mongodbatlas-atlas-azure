module "atlas_azure" {
  source = "../../"

  project_id = var.project_id

  # Default: creates service principal automatically
  # Set create_service_principal = false and provide service_principal_id for existing
}

# Optional: create additional role assignments for the service principal
# resource "azurerm_role_assignment" "atlas_reader" {
#   scope                = data.azurerm_subscription.current.id
#   role_definition_name = "Reader"
#   principal_id         = module.atlas_azure.service_principal_id
# }
