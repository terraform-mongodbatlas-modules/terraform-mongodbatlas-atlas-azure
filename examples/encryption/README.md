<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Key Vault Integration (User-Provided)

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

data "azurerm_client_config" "current" {}

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

resource "azurerm_key_vault" "atlas" {
  name                       = var.key_vault_name
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "terraform_key_vault_admin" {
  scope                = azurerm_key_vault.atlas.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_key" "atlas" {
  name         = "atlas-encryption-key"
  key_vault_id = azurerm_key_vault.atlas.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P30D"
  }

  depends_on = [azurerm_role_assignment.terraform_key_vault_admin]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
  project_id               = var.project_id
  atlas_azure_app_id       = var.atlas_azure_app_id
  service_principal_id     = var.service_principal_id
  create_service_principal = false
  encryption_client_secret = local.encryption_client_secret

  encryption = {
    enabled        = true
    key_vault_id   = azurerm_key_vault.atlas.id
    key_identifier = azurerm_key_vault_key.atlas.versionless_id
  }
}

output "encryption" {
  value = module.atlas_azure.encryption
}
```

**Additional files needed:**
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)



## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue
