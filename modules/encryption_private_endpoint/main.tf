resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AZURE"
  region_name    = var.region_name
}

resource "azapi_update_resource" "approval" {
  type      = "Microsoft.KeyVault/Vaults/PrivateEndpointConnections@2023-07-01"
  name      = mongodbatlas_encryption_at_rest_private_endpoint.this.private_endpoint_connection_name
  parent_id = var.key_vault_id

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        status      = "Approved"
        description = "Approved via Terraform"
      }
    }
  }
}
