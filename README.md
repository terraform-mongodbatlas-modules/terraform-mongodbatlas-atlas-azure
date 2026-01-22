# Atlas Azure Terraform Module

<!-- BEGIN_TOC -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
- [Public Preview Note](#public-preview-note)
- [Disclaimer](#disclaimer)
- [Getting Started](#getting-started)
- [Examples](#examples)
- [Requirements](#requirements)
- [Providers](#providers)
- [Resources](#resources)
- [Required Variables](#required-variables)
- [Azure Service Principal](#azure-service-principal)
- [Encryption at Rest](#encryption-at-rest)
- [Private Link](#private-link)
- [Backup Export](#backup-export)
- [Optional Variables](#optional-variables)
- [Outputs](#outputs)
- [FAQ](#faq)
<!-- END_TOC -->

## Public Preview Note

The MongoDB Atlas Azure Module (Public Preview) simplifies Atlas-Azure integrations and embeds MongoDB's best practices as intelligent defaults. This preview validates that these patterns meet the needs of most workloads without constant maintenance or rework. We welcome your feedback and contributions during this preview phase. MongoDB formally supports this module from its v1 release onwards.

<!-- BEGIN_DISCLAIMER -->
## Disclaimer

One of this project's primary objectives is to provide durable modules that support non-breaking migration and upgrade paths. The v0 release (public preview) of the MongoDB Atlas Azure Module focuses on gathering feedback and refining the design. Upgrades from v0 to v1 may not be seamless. We plan to deliver a finalized v1 release early next year with long term upgrade support.  

<!-- END_DISCLAIMER -->
## Getting Started

<!-- BEGIN_GETTING_STARTED -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
### Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run the `terraform` [commands](#commands)
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method
   **NOTE**: Service Accounts (SA) is the preferred authentication method. See [Grant Programatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project
4. Use an existing [MongoDB Atlas Project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [optionally create a new Atlas project resource](#optionally-create-a-new-atlas-project-resource)
5. Authenticate your Azure CLI (`az login`) or configure your service principal credentials.

### Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, ARM_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

<!-- END_GETTING_STARTED -->

### Set Up Atlas-Azure Access

Take the following steps to configure your Atlas-Azure access:  

1. Prepare your `vars.tfvars` file.
  Choose whether to create a new Azure AD service principal or reuse an existing one.

    The following example shows a `vars.tfvars` configuration that reuses an existing `service_principal_id`:

    ```hcl
    # vars.tfvars
    project_id               = "YOUR_ATLAS_PROJECT_ID"
    create_service_principal = false
    service_principal_id     = "00000000-0000-0000-0000-000000000000" # Azure AD object ID
    ```

    The following example shows a `vars.tfvars` configuration that uses a module-managed service principal (`create_service_principal = true`):

    ```hcl
    # vars.tfvars
    project_id              = "YOUR_ATLAS_PROJECT_ID"
    create_service_principal = true
    # atlas_azure_app_id has a sensible default; override only if needed
    ```

    **IMPORTANT:** Do not set `service_principal_id` when `create_service_principal = true`.

2. Ensure your authentication environment variables are configured.

      ```sh
    export MONGODB_ATLAS_CLIENT_ID="your-client-id-goes-here"
    export MONGODB_ATLAS_CLIENT_SECRET="your-client-secret-goes-here"
    ```

   See [Prerequisites](#prerequisites) for more details.

3. Initialize and apply your Terraform configuration (see [Commands](#commands)).

4. Verify outputs. After apply, note:
  
    - [role_id](#output_role_id)
    - [authorized_date](#output_authorized_date)
    - [service_principal_id](#output_service_principal_id)
    - [service_principal_resource_id](#output_service_principal_resource_id)

You now have access. See the [Examples](#examples) section for additional details of specific actions you can execute with this module.

### Clean up your configuration

Run `terraform destroy -var-file vars.tfvars` to undo all changes that Terraform did on your infrastructure.

<!-- BEGIN_TABLES -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
## Examples

Feature | Name
--- | ---
Backup Export | [Azure Blob Storage Export](./examples/backup_export)
Encryption at Rest | [Azure Key Vault Integration (User-Provided)](./examples/encryption)
Encryption at Rest | [Azure Key Vault (Module-Managed with Private Networking)](./examples/encryption_create_key_vault_private_networking)
Private Link | [Azure Private Endpoint (Module-Managed)](./examples/privatelink)
Private Link | [Azure Private Endpoint (Bring Your Own Endpoint)](./examples/privatelink_byoe)
Private Link | [Multi-Region Private Endpoints](./examples/privatelink_multi_region)

<!-- END_TABLES -->
<!-- BEGIN_TF_DOCS -->
<!-- @generated
WARNING: This section is auto-generated by terraform-docs. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just docs' to regenerate.
-->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) (>= 2.53)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.0)

- <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) (>= 2.0)

## Providers

The following providers are used by this module:

- <a name="provider_azuread"></a> [azuread](#provider\_azuread) (>= 2.53)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.0)

- <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) (>= 2.0)

## Resources

The following resources are used by this module:

- [azuread_service_principal.atlas](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) (resource)
- [mongodbatlas_cloud_provider_access_authorization.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cloud_provider_access_authorization) (resource)
- [mongodbatlas_cloud_provider_access_setup.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cloud_provider_access_setup) (resource)
- [mongodbatlas_private_endpoint_regional_mode.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/private_endpoint_regional_mode) (resource)
- [mongodbatlas_privatelink_endpoint.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) (resource)
- [azuread_service_principal.existing](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- BEGIN_TF_INPUTS_RAW -->
<!-- @generated
WARNING: This grouped inputs section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just docs' to regenerate.
-->
## Required Variables

### project_id

MongoDB Atlas project ID

Type: `string`


## Azure Service Principal

Configure the Azure AD service principal used by MongoDB Atlas.

### atlas_azure_app_id

MongoDB Atlas Azure application ID. This is the application ID registered in Azure AD for MongoDB Atlas.

Type: `string`

Default: `"9f2deb0d-be22-4524-a403-df531868bac0"`

### create_service_principal

Create Azure AD service principal. Set as `false` and provide `service_principal_id` for existing.

Type: `bool`

Default: `true`

### service_principal_id

Existing service principal object ID. Required if `create_service_principal = false`.

Type: `string`

Default: `null`


## Encryption at Rest

Configure encryption at rest using Azure Key Vault. See the [Azure encryption documentation](https://www.mongodb.com/docs/atlas/security-azure-kms/) for details.

### encryption

Encryption at rest configuration with Azure Key Vault.
Provide EITHER:

- `key_vault_id` + `key_identifier` (for user-provided Key Vault)
- `create_key_vault.enabled` = true (for module-managed Key Vault)

**NOTE:** `private_endpoint_regions` uses the Atlas region format (e.g., `US_EAST_2`, `EUROPE_WEST`), not Azure format (e.g., `eastus2`, `westeurope`). See [Availability Zones and Supported Regions](https://www.mongodb.com/docs/atlas/reference/microsoft-azure/#availability-zones-and-supported-regions) for a comprehensive list of equivalencies between Atlas and Azure regions.

Type:

```hcl
object({
  enabled        = optional(bool, false)
  key_vault_id   = optional(string)
  key_identifier = optional(string)
  create_key_vault = optional(object({
    enabled                    = bool
    name                       = string
    resource_group_name        = string
    azure_location             = string
    purge_protection_enabled   = optional(bool, true)
    soft_delete_retention_days = optional(number, 90)
    key_rotation_policy = optional(object({
      expire_after         = optional(string, "P365D")
      rotate_before_expiry = optional(string, "P30D")
      notify_before_expiry = optional(string, "P30D")
    }), {})
  }))
  require_private_networking = optional(bool, false)
  private_endpoint_regions   = optional(set(string), [])
})
```

Default: `{}`

### encryption_client_secret

Azure AD application client secret for encryption. This value is required when using module-managed encryption (`encryption.enabled = true`).

**IMPORTANT:** Azure limits the client secret lifetime to two years. When the secret expires, Atlas loses CMK access, causing cluster unavailability. Rotate secrets before expiration.

Future provider enhancements may support `roleId`-based authentication, eliminating the need for `client_secret`.

Type: `string`

Default: `null`


## Private Link

Configure Azure Private Link endpoints for secure connectivity. See the [Azure Private Link documentation](https://www.mongodb.com/docs/atlas/security-private-endpoint/) for details.

### privatelink_endpoints

Module-managed PrivateLink endpoints. Key is user identifier (or Azure location if `azure_location` is omitted).

Type:

```hcl
map(object({
  azure_location = optional(string)
  subnet_id      = string
  name           = optional(string)
  tags           = optional(map(string), {})
}))
```

Default: `{}`

### privatelink_byoe_locations

Atlas-side PrivateLink endpoints for BYOE. Key is user identifier, value is Azure location.

Type: `map(string)`

Default: `{}`

### privatelink_byoe

BYOE endpoint details. Key must exist in `privatelink_byoe_locations`.

Type:

```hcl
map(object({
  azure_private_endpoint_id         = string
  azure_private_endpoint_ip_address = string
}))
```

Default: `{}`


## Backup Export

Configure backup snapshot export to Azure Blob Storage.

### backup_export

Backup snapshot export to Azure Blob Storage. Provide EITHER `storage_account_id` (user-provided) OR `create_storage_account.enabled = true` (module-managed).

Type:

```hcl
object({
  enabled        = optional(bool, false)
  container_name = optional(string)
  # User-provided storage account
  storage_account_id = optional(string)
  create_container   = optional(bool, true)
  # Module-managed storage account
  create_storage_account = optional(object({
    enabled             = bool
    name                = string
    resource_group_name = string
    azure_location      = string
    replication_type    = optional(string, "LRS")
    account_tier        = optional(string, "Standard")
    min_tls_version     = optional(string, "TLS1_2")
  }))
})
```

Default: `{}`


## Optional Variables

_No variables in this section yet._

<!-- END_TF_INPUTS_RAW -->

## Outputs

The following outputs are exported:

### <a name="output_authorized_date"></a> [authorized\_date](#output\_authorized\_date)

Description: Date when the cloud provider access was authorized.

### <a name="output_backup_export"></a> [backup\_export](#output\_backup\_export)

Description: Backup export configuration status

### <a name="output_encryption"></a> [encryption](#output\_encryption)

Description: Encryption at rest configuration status

### <a name="output_encryption_at_rest_provider"></a> [encryption\_at\_rest\_provider](#output\_encryption\_at\_rest\_provider)

Description: Value for cluster's encryption\_at\_rest\_provider attribute

### <a name="output_export_bucket_id"></a> [export\_bucket\_id](#output\_export\_bucket\_id)

Description: Export bucket ID for backup schedule auto\_export\_enabled

### <a name="output_feature_usages"></a> [feature\_usages](#output\_feature\_usages)

Description: List of features using this cloud provider access role.

### <a name="output_privatelink"></a> [privatelink](#output\_privatelink)

Description: PrivateLink status per user key (both module-managed and BYOE).

### <a name="output_privatelink_service_info"></a> [privatelink\_service\_info](#output\_privatelink\_service\_info)

Description: Atlas PrivateLink service info per user key (for BYOE - create your Azure PE using these values)

### <a name="output_regional_mode_enabled"></a> [regional\_mode\_enabled](#output\_regional\_mode\_enabled)

Description: Whether private endpoint regional mode is enabled (auto-enabled for multi-region)

### <a name="output_role_id"></a> [role\_id](#output\_role\_id)

Description: Atlas role ID for reuse with other Atlas-Azure features.

### <a name="output_service_principal_id"></a> [service\_principal\_id](#output\_service\_principal\_id)

Description: Service principal object ID used for Atlas-Azure integration.

### <a name="output_service_principal_resource_id"></a> [service\_principal\_resource\_id](#output\_service\_principal\_resource\_id)

Description: Service principal full resource ID for creating passwords/credentials.
<!-- END_TF_DOCS -->

## FAQ

### What is `provider_meta "mongodbatlas"` doing?

This block tracks module usage by updating the User-Agent of requests to Atlas:

```
User-Agent: terraform-provider-mongodbatlas/2.1.0 Terraform/1.13.1 module_name/atlas-azure module_version/0.1.0
```

- `provider_meta "mongodbatlas"` does not send any configuration-specific data, only the module's name and version for feature adoption tracking
- Use `export TF_LOG=debug` to see API requests with headers and responses

### Why does encryption require a client secret with a two-year expiration?

Azure limits Client Secret lifetime for CMKs to two years maximum. When the secret expires, Atlas loses access to your encryption key, causing cluster unavailability. Rotate secrets before expiration.

**Future enhancement:** The Terraform provider will support `role_id`-based authentication soon, eliminating the need for client secrets.
