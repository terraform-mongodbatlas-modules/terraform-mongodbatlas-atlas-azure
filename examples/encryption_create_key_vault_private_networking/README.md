<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Key Vault (Module-Managed with Private Networking)

## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run the `terraform` commands
2. Sign up for a [MongoDB Atlas Account](https://www.mongodb.com/products/integrations/hashicorp-terraform)
3. Configure [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication)
4. An existing [MongoDB Atlas Project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project).
5. Azure CLI authenticated (`az login`) or service principal credentials configured

## Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, ARM_XXX)
# configure your `vars.tfvars` with required variables

terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Create client secret for encryption (only if not provided)
# TODO: Replace with roleId when CLOUDP-369548 is implemented
resource "azuread_service_principal_password" "encryption" {
  count                = var.existing_encryption_client_secret.enabled ? 0 : 1
  service_principal_id = "/servicePrincipals/${var.service_principal_id}"
  display_name         = "MongoDB Atlas - Encryption Test"
  # Azure limits Client Secret lifetime to 2 years max. Rotate before expiration.
}

locals {
  encryption_client_secret = coalesce(var.existing_encryption_client_secret.value, try(azuread_service_principal_password.encryption[0].value, null))
}

module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
  project_id               = var.project_id
  service_principal_id     = var.service_principal_id
  create_service_principal = false
  atlas_azure_app_id       = var.atlas_azure_app_id
  encryption_client_secret = local.encryption_client_secret

  encryption = {
    enabled = true
    create_key_vault = {
      enabled                    = true
      name                       = var.key_vault_name
      azure_location             = data.azurerm_resource_group.main.location
      resource_group_name        = data.azurerm_resource_group.main.name
      purge_protection_enabled   = var.purge_protection_enabled
      soft_delete_retention_days = var.soft_delete_retention_days
    }
    require_private_networking = var.require_private_networking
    private_endpoint_regions   = var.private_endpoint_regions
  }
}

resource "azapi_update_resource" "approval" {
  for_each = var.require_private_networking ? module.atlas_azure.encryption.private_endpoints : {}

  type      = "Microsoft.KeyVault/Vaults/PrivateEndpointConnections@2023-07-01"
  name      = each.value.private_endpoint_connection_name
  parent_id = module.atlas_azure.encryption.key_vault_id

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        status      = "Approved"
        description = "Approved via Terraform"
      }
    }
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}

output "key_vault_id" {
  description = "Module-created Key Vault ID"
  value       = module.atlas_azure.encryption.key_vault_id
}

output "key_identifier" {
  description = "Module-created key identifier"
  value       = module.atlas_azure.encryption.key_identifier
}

output "private_endpoints" {
  description = "Private endpoint status (empty if require_private_networking = false)"
  value       = module.atlas_azure.encryption.private_endpoints
}
```

**Additional files needed:**
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)




## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue
