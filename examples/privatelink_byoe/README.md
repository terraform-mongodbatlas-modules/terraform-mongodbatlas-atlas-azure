<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Private Endpoint (Bring Your Own Endpoint)

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
# BYOE (Bring Your Own Endpoint) pattern
# 
# For BYOE, we use a two-step approach:
# Step 1: Root module creates Atlas-side PrivateLink endpoint and exposes service info
# Step 2: User-managed Azure Private Endpoint references the Atlas service info (see below)
#
# Note: Step 2 (azurerm_private_endpoint.custom) depends on Step 1 output (privatelink_service_info)

# Step 1: Configure Atlas PrivateLink with BYOE locations

locals {
  pe1 = "pe1"
}

module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"

  project_id = var.project_id

  # BYOE: provide your own Azure Private Endpoint details
  privatelink_byoe = {
    (local.pe1) = {
      azure_private_endpoint_id         = azurerm_private_endpoint.custom.id
      azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
    }
  }
  privatelink_byoe_locations = { (local.pe1) = var.azure_location }
}

# Step 2: User-managed Azure Private Endpoint with custom configuration
resource "azurerm_private_endpoint" "custom" {
  name                = "pe-atlas-static-ip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = module.atlas_azure.privatelink_service_info[local.pe1].atlas_private_link_service_name
    private_connection_resource_id = module.atlas_azure.privatelink_service_info[local.pe1].atlas_private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "MongoDB Atlas PrivateLink"
  }

  ip_configuration {
    name               = "atlas-static"
    private_ip_address = var.static_ip_address
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_azure.privatelink[local.pe1]
}

output "static_ip" {
  description = "Static IP address of the private endpoint"
  value       = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
}
```

**Additional files needed:**
- [providers.tf](./providers.tf)
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)




## Feedback or Help

- If you have any feedback or trouble please open a Github Issue
