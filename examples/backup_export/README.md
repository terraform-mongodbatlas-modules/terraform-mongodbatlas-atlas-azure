<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Blob Storage Export

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

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
# Module-managed storage account (recommended for simplicity)
module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
  project_id = var.project_id

  atlas_azure_app_id       = var.atlas_azure_app_id
  create_service_principal = var.create_service_principal
  service_principal_id     = var.service_principal_id

  backup_export = {
    enabled        = true
    container_name = "atlas-backup-exports"
    create_storage_account = {
      enabled             = true
      name                = var.storage_account_name
      resource_group_name = var.resource_group_name
      azure_location      = var.azure_location
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Alternative: User-provided storage account (uncomment to use)
# ─────────────────────────────────────────────────────────────────────────────
# resource "azurerm_storage_account" "backup" {
#   name                     = var.storage_account_name
#   resource_group_name      = var.resource_group_name
#   location                 = var.azure_location
#   account_tier             = "Standard"
#   account_replication_type = "GRS"  # Geo-redundant for backup data
#   min_tls_version          = "TLS1_2"
# }
#
# module "atlas_azure" {
#   source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
#   project_id = var.project_id

#   atlas_azure_app_id       = var.atlas_azure_app_id
#   create_service_principal = var.create_service_principal
#   service_principal_id     = var.service_principal_id
#
#   backup_export = {
#     enabled            = true
#     container_name     = "atlas-backup-exports"
#     storage_account_id = azurerm_storage_account.backup.id
#     create_container   = true  # Module creates container, or false if pre-existing
#   }
# }

output "backup_export" {
  value = module.atlas_azure.backup_export
}

output "export_bucket_id" {
  value = module.atlas_azure.export_bucket_id
}

output "module_full" {
  value = module.atlas_azure
}
```

**Additional files needed:**
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)




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

## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue.
