<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Blob Storage Export

## Pre Requirements

If you are familiar with Terraform and already have a project configured in MongoDB Atlas go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run the `terraform` commands.
2. Sign up for a [MongoDB Atlas Account](https://www.mongodb.com/products/integrations/hashicorp-terraform)
3. Configure [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication)
4. An existing [MongoDB Atlas Project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project)
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




## Feedback or Help

- If you have any feedback or trouble please open a Github Issue
