<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Log Integration Byo

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
  name   = "atlas-azure"
  org_id = var.org_id
}
```

- You can use this and replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](./main.tf) file.
<!-- END_GETTING_STARTED -->

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
resource "azurerm_storage_account" "logs" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.azure_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

/*
Uncomment the following resource to block accidental destruction of the log storage. CanNotDelete on the account rejects
deletes on that scope; nested deletes (e.g. the `atlas-logs` container) can return 409 until the
lock is removed, for example:
  Error: deleting .../blobServices/default/containers/atlas-logs: 409 (Conflict) ScopeLocked:
  The scope '.../containers/atlas-logs' cannot perform delete operation because following scope(s)
  are locked: '.../storageAccounts/<name>'. Please remove the lock and try again.
*/

# resource "azurerm_management_lock" "logs" {
#   name       = "atlas-log-storage-lock"
#   scope      = azurerm_storage_account.logs.id
#   lock_level = "CanNotDelete"
#   notes      = "Prevent accidental deletion of Atlas log storage account"
# }

module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
  project_id = var.project_id

  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = var.create_service_principal
  service_principal_id     = var.service_principal_id

  log_integration = {
    enabled            = true
    container_name     = "atlas-logs"
    storage_account_id = azurerm_storage_account.logs.id
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
      { log_types = ["MONGOD_AUDIT"], prefix_path = "audit" },
    ]
  }
}

output "log_integration" {
  value = module.atlas_azure.log_integration
}

output "module_full" {
  value = module.atlas_azure
}
```

**Additional files needed:**
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)



## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue.
