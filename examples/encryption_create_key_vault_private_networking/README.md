<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Key Vault (Module-Managed with Private Networking)

<!-- BEGIN_GETTING_STARTED -->
## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) is the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
5. Authenticate your Azure CLI (`az login`) or configure your service principal credentials.

## Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, ARM_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

## (Optional) Create a New Atlas Project Resource

```hcl
variable "org_id" {
  type    = string
  default = "{ORG_ID}" # REPLACE with your organization id, for example `65def6ce0f722a1507105aa5`.
}

resource "mongodbatlas_project" "this" {
  name   = "cluster-module"
  org_id = var.org_id
}
```

- You can use this and replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](./main.tf) file.
<!-- END_GETTING_STARTED -->

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

- If you have any feedback or trouble please open a GitHub issue.
