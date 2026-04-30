<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# Azure Private Endpoint (Bring Your Own Endpoint)

The Azure Private Endpoint (Bring Your Own Endpoint) example provisions Atlas Private Link services, then links user-managed Azure private endpoints in a follow-up apply or the same configuration.

<!-- BEGIN_GETTING_STARTED -->
## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) are the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
5. Authenticate your Azure CLI (`az login`) or configure your service principal credentials. For the Azure role assignments required per feature, see [Azure Service Principal](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure#azure-service-principal).

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

- You can use this and replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/blob/v0.3.0/examples/privatelink_byoe/main.tf) file.
<!-- END_GETTING_STARTED -->

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
# BYOE (Bring Your Own Endpoint) pattern
# 
# Use BYOE when you need custom Azure Private Endpoint configuration (e.g., static IP addresses,
# custom naming, or integration with existing networking infrastructure).
#
# Single `terraform apply` approach:
# 1: Create Atlas-side PrivateLink using `privatelink_byo_endpoint` to get service connection info
# 2: Create your own Azure Private Endpoint using the output `privatelink_service_info`
# 3: Register your endpoint with Atlas using `privatelink_byo_service` to complete the connection
#
# Note: azurerm_private_endpoint.custom depends on Step 1 output (module.atlas_azure.privatelink_service_info)

locals {
  pe1 = "pe1"
}

module "atlas_azure" {
  source  = "terraform-mongodbatlas-modules/atlas-azure/mongodbatlas"
  version = "v0.3.0"

  project_id = var.project_id

  privatelink_byo_endpoint = { (local.pe1) = { region = var.region } } # 1
  privatelink_byo_service = {                                          # 3
    (local.pe1) = {
      azure_private_endpoint_id         = azurerm_private_endpoint.custom.id
      azure_private_endpoint_ip_address = azurerm_private_endpoint.custom.private_service_connection[0].private_ip_address
    }
  }
}

resource "azurerm_private_endpoint" "custom" { # 2
  name                = "pe-atlas-static-ip"
  location            = module.atlas_azure.privatelink_service_info[local.pe1].region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = module.atlas_azure.privatelink_service_info[local.pe1].atlas_endpoint_service_name
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
- [variables.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/blob/v0.3.0/examples/privatelink_byoe/variables.tf)
- [versions.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/blob/v0.3.0/examples/privatelink_byoe/versions.tf)



## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue.
