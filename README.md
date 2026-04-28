# MongoDB Atlas Azure Terraform Module

Use this Terraform module to configure MongoDB Atlas integrations with Azure. The module includes recommended defaults based on MongoDB best practices. MongoDB maintains this module. For questions, open a support request or a GitHub issue.

<!-- BEGIN_TOC -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
- [Module status](#module-status)
- [Local setup](#local-setup)
- [Examples](#examples)
- [Requirements](#requirements)
- [Providers](#providers)
- [Resources](#resources)
- [Required Variables](#required-variables)
- [Azure Service Principal](#azure-service-principal)
- [Encryption at Rest](#encryption-at-rest)
- [Private Link](#private-link)
- [Backup Export](#backup-export)
- [Log Integration](#log-integration)
- [Timeouts](#timeouts)
- [Optional Variables](#optional-variables)
- [Outputs](#outputs)
- [FAQ](#faq)
<!-- END_TOC -->

## Module status

This module is in **public preview**: MongoDB publishes it to gather feedback and refine the design. Upgrades from v0 to v1 may not be seamless; plan for migration work when you adopt a v1 release. MongoDB formally supports this module from its v1 release onwards, including bug fixes and security patches for supported versions. Contributors and early adopters are welcome to open GitHub issues with feedback or defects.

## Local setup

<!-- BEGIN_GETTING_STARTED -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
### Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with Azure through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) are the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
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

### (Optional) Create a New Atlas Project Resource

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

<!-- BEGIN_TABLES -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
## Examples

The following examples show common configurations you can copy and adapt. Start with the [encryption](./examples/encryption) example for a minimal setup, then explore other examples for Private Link, backup export, and log integration. Examples can be combined in a single module call; see the [azure_read_only](./examples/azure_read_only) example for multiple features in one configuration.


Feature | Name
--- | ---
Backup Export | [Azure Blob Storage Export](./examples/backup_export)
Encryption at Rest | [Azure Key Vault Integration (User-Provided)](./examples/encryption)
Encryption at Rest | [Azure Key Vault (Module-Managed with Private Networking)](./examples/encryption_create_key_vault_private_networking)
Cloud Provider Access | [Read-Only Azure (BYO Key Vault, Storage, and Log Export)](./examples/azure_read_only)
Private Link | [Azure Private Endpoint (Module-Managed)](./examples/privatelink)
Private Link | [Azure Private Endpoint (Bring Your Own Endpoint)](./examples/privatelink_byoe)
Private Link | [Multi-Region Private Endpoints](./examples/privatelink_multi_region)
Log Integration | [Azure Log Export](./examples/log_integration)
Log Integration | [Azure Log Export (Bring Your Own Storage)](./examples/log_integration_byo)

<!-- END_TABLES -->
<!-- BEGIN_TF_DOCS -->
<!-- @generated
WARNING: This section is auto-generated by terraform-docs. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just docs' to regenerate.
-->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/install) (>= 1.9)

- <a name="requirement_azuread"></a> [azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) (>= 2.53)

- <a name="requirement_azurerm"></a> [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) (>= 4.42)

- <a name="requirement_mongodbatlas"></a> [mongodbatlas](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs) (>= 2.8)

## Providers

The following providers are used by this module:

- <a name="provider_azuread"></a> [azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) (>= 2.53)

- <a name="provider_azurerm"></a> [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) (>= 4.42)

- <a name="provider_mongodbatlas"></a> [mongodbatlas](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs) (>= 2.8)

- <a name="provider_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/language/resources/terraform-data)

## Resources

The following resources are used by this module:

- [azuread_service_principal.atlas](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) (resource)
- [mongodbatlas_cloud_provider_access_authorization.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cloud_provider_access_authorization) (resource)
- [mongodbatlas_cloud_provider_access_setup.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cloud_provider_access_setup) (resource)
- [mongodbatlas_private_endpoint_regional_mode.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/private_endpoint_regional_mode) (resource)
- [mongodbatlas_privatelink_endpoint.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) (resource)
- [terraform_data.region_validations](https://developer.hashicorp.com/terraform/language/resources/terraform-data) (resource)
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

MongoDB Atlas uses a Microsoft Entra ID (Azure AD) [app registration and service principal](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app) to access your Key Vault and storage accounts. Atlas links the service principal through Cloud Provider Access; see [Azure encryption and Key Vault access](https://www.mongodb.com/docs/atlas/security-azure-kms/) in the MongoDB Atlas documentation.

Set `create_service_principal = true` (default) to let the module create the service principal and required role assignments where the feature allows. Set `create_service_principal = false` and pass `service_principal_id` when you already have a principal registered in Entra ID and want the module to use it for Atlas authorization only.

Set `skip_role_assignments = true` only when your platform team pre-assigns the required Azure roles on Key Vault and storage accounts. In that case you must use user-provided Key Vault and storage (`key_vault_id`, `storage_account_id`); the module cannot create module-managed Key Vault or storage without assigning roles. `skip_role_assignments = true` also requires an external service principal (`create_service_principal = false`), because a module-created principal still needs role assignments.

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

### skip_role_assignments

Skip all Azure role assignments (azurerm_role_assignment) in encryption, backup_export, and log_integration submodules. Set true when the service principal already has the required roles pre-assigned externally.

Required roles when true:
- Key Vault: Key Vault Crypto User, Key Vault Reader on the Key Vault
- Storage: Storage Blob Data Contributor on each target storage account

Requires BYO resources: create_key_vault.enabled and create_storage_account.enabled (encryption, backup export, log integration) are disallowed when skip_role_assignments = true.

Type: `bool`

Default: `false`


## Encryption at Rest

Customer-managed keys in Azure Key Vault help you meet control and compliance requirements. Provide an existing Key Vault and key with `key_vault_id` and a versionless `key_identifier` URL, or set `create_key_vault.enabled = true` for a module-managed Key Vault. Optional `private_endpoint_regions` can use [private networking for Key Vault](https://www.mongodb.com/docs/atlas/security-azure-kms/) with supported configurations. The module wires encryption at rest to the Key Vault through Cloud Provider Access.

### encryption

Encryption at rest configuration with Azure Key Vault.
Provide EITHER:

- `key_vault_id` + `key_identifier` (for user-provided Key Vault)
- `create_key_vault.enabled` = true (for module-managed Key Vault)

**Search Node Encryption:**
`enabled_for_search_nodes` (default: `true`) controls whether BYOK encryption applies to dedicated search nodes. The module defaults to `true` (provider default is `false`) for a secure-by-default experience. Flipping from `false` to `true` on a deployment with dedicated search nodes triggers reprovisioning and index rebuild.

**NOTE:** `private_endpoint_regions` accepts both Atlas format (e.g., `US_EAST_2`) and Azure format (e.g., `eastus2`). Child module instances and `encryption` output map keys use normalized Azure location strings.

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
  enabled_for_search_nodes = optional(bool, true)
  private_endpoint_regions = optional(set(string), [])
})
```

Default: `{}`

### encryption_client_secret

Deprecated: Azure AD application client secret for encryption. The module now uses CPA `role_id` automatically. Remove this variable from your configuration. Will be removed at v1.0.

When set, the encryption submodule uses the legacy Key Vault config (tenant_id, client_id, and secret).

Type: `string`

Default: `null`


## Private Link

Private Link keeps application traffic to Atlas on the Azure backbone instead of the public internet, which many security policies require. Use `privatelink_endpoints` or `privatelink_endpoints_single_region` for module-managed `azurerm_private_endpoint` resources, or the bring-your-own-endpoint maps (`privatelink_byo_endpoint` and `privatelink_byo_service`) when you create and manage private endpoints in your own resources.

See the [Private Link documentation](https://www.mongodb.com/docs/atlas/security-private-endpoint/?cloud-provider=azure) for product behavior. For the split between Atlas service creation and registering user endpoints, use the [privatelink_byoe example](./examples/privatelink_byoe).

### privatelink_endpoints

Multi-region PrivateLink endpoints. `region` accepts Atlas format (US_EAST_2) or Azure format (eastus2). All regions must be UNIQUE.

`mongodbatlas_private_endpoint_regional_mode` is only created when `privatelink_regional_mode` is `auto` and there are multiple distinct Atlas service regions. The default is `disabled`.

Type:

```hcl
list(object({
  region    = string
  subnet_id = string
  name      = optional(string)
  tags      = optional(map(string), {})
}))
```

Default: `[]`

### privatelink_endpoints_single_region

Single-region multi-endpoint pattern. Region accepts Atlas format (US_EAST_2) or Azure format (eastus2).
All endpoints MUST be in the same region.

Example:
```hcl
privatelink_endpoints_single_region = [
  { region = "eastus2", subnet_id = "/subscriptions/.../subnets/app1" },
  { region = "eastus2", subnet_id = "/subscriptions/.../subnets/app2" },
]
```

Type:

```hcl
list(object({
  region    = string
  subnet_id = string
  name      = optional(string)
  tags      = optional(map(string), {})
}))
```

Default: `[]`

### privatelink_byo_endpoint

Bring-your-own-endpoint (BYOE) Atlas PrivateLink: Define Atlas endpoint services for regions where you create Azure private endpoints yourself.
Key is a user-defined identifier; `region` accepts Atlas or Azure format. After normalizing to Azure location, values must not duplicate a region already used in `privatelink_endpoints`.
Apply this configuration (optionally with `privatelink_byo_service` in the same workspace) so Terraform creates the Atlas endpoint services, then use `privatelink_service_info` in outputs to build user-managed `azurerm_private_endpoint` resources if you manage endpoints outside the module. If `privatelink_byo_service` is empty on the first apply, run a follow-up `terraform apply` after the Azure private endpoints exist so Terraform can link them in Atlas.

Type:

```hcl
map(object({
  region = string
}))
```

Default: `{}`

### privatelink_byo_service

User-managed Azure private endpoints to register with Atlas for BYOE. Each key must match a key in `privatelink_byo_endpoint` and must supply the Azure private endpoint resource ID and private IP. Supply these values in the same apply as `privatelink_byo_endpoint` if Terraform manages the endpoints, or in a later apply after you create the endpoints. See the [privatelink_byoe](./examples/privatelink_byoe) example.

Type:

```hcl
map(object({
  azure_private_endpoint_id         = string
  azure_private_endpoint_ip_address = string
}))
```

Default: `{}`

### privatelink_regional_mode

Per-region SRV/connection strings for sharded and geo-sharded clusters only, not for replica
sets. Default is `disabled`. Use `auto` to enable when the module detects multiple distinct
Atlas service regions.

- **When it helps:** multi-region sharded topologies. Networks that cannot be peered and need
local private-endpoint connection strings.
- **Tradeoffs:** toggling is project-wide (connection string and DNS churn, possible brief
downtime). A region's PE connection string is not a cross-region disaster-recovery or failover
path on its own.
- **Often skip:** a single global PE with VNet peering, or one PE per region that every app can
reach, is enough. See [regionalized private endpoints (multi-region sharded)](https://www.mongodb.com/docs/atlas/security-private-endpoint/?cloud-provider=azure#-optional--regionalized-private-endpoints-for-multi-region-sharded-clusters).

Type: `string`

Default: `"disabled"`


## Backup Export

Backup export stores Atlas Cloud Backup snapshots in an Azure Storage container you control for retention, air-gapped recovery, and residency. Provide a `storage_account_id` and `container_name`, or set `create_storage_account.enabled = true` for module-managed storage with secure defaults (for example public network access disabled on module-managed accounts in current releases).

See [export backup snapshots](https://www.mongodb.com/docs/atlas/backup/cloud-backup/export/) in the MongoDB Atlas documentation for product details.

### backup_export

Backup snapshot export to Azure Blob Storage.

Provide EITHER:
- `storage_account_id` (user-provided Storage Account)
- `create_storage_account.enabled = true` (module-managed Storage Account)

**Storage account (when module-managed):**
- `create_storage_account.name` - Storage account name (globally unique in Azure)
- `create_storage_account.resource_group_name` and `azure_location` - Where the account is created
- Optional: `replication_type`, `account_tier`, `min_tls_version` (defaults match the type: LRS, Standard, TLS1_2)

**Security defaults (when module-managed):**
- `public_network_access_enabled = false` (same as `log_integration` module-managed storage)
- Container is private, nested blob public access is not allowed, minimum TLS 1.2

**Lifecycle:**
- `create_storage_account.expiration_days` - Delete blobs in the export container after N days since last modification (default 365, 0 to disable and skip `azurerm_storage_management_policy`)

The module creates a blob container for exports unless you use a user-provided `storage_account_id` with `create_container = false` and an existing container.

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
    expiration_days     = optional(number, 365)
  }))
})
```

Default: `{}`


## Log Integration

Log integration exports Atlas operational and audit logs to Azure Blob Storage on a one-minute schedule so your security information and event management (SIEM) platform or observability stack can ingest from storage.

- **User-provided storage account**: Set `storage_account_id` to the target Storage Account resource ID. You must also name the blob container. Set `container_name` on the `log_integration` object for a single default container, or set `container_name` on each entry in `integrations` when each log stream needs its own container.
- **Module-managed storage account**: Set `create_storage_account.enabled = true` and provide the nested `create_storage_account` fields so the module can create the account and apply the same secure defaults as other module-managed storage (for example TLS 1.2 and blocked public access where the module enforces that).
- **Per-integration destination**: On an integration, optional `storage_account_name`, `container_name`, and `resource_group_name` point that integration at a different account or container (for example separate paths for audit and operational logs).

See the [log export to Azure](https://www.mongodb.com/docs/atlas/export-logs-azure/) product documentation.

### log_integration

Log integration for exporting Atlas logs to Azure Blob Storage (`AZURE_LOG_EXPORT`).
Log exports run at 1-minute intervals.

**Storage Strategy (same pattern as `backup_export`):**
- `storage_account_id`: User-provided Storage Account, default for all integrations.
- `create_storage_account.enabled = true`: Module-managed Storage Account with secure defaults (TLS 1.2, public access blocked).
- Per-integration `storage_account_name` and `container_name` override for BYO storage (for example audit logs to a separate account).

**Integrations:**
Each entry in `integrations` creates one `mongodbatlas_log_integration` resource.
`prefix_path` is required by the Atlas API. Use it to isolate log types within a shared container. Atlas writes objects as `{prefix}/{relative_path}`. The module trims a trailing `/` from `prefix_path` so keys do not end up with a double slash (e.g. `mongod//file`) and plans stay stable whether or not callers include `/`.
Valid `log_types`: MONGOD, MONGOS, MONGOD_AUDIT, and MONGOS_AUDIT. The module does not validate these values. The Atlas API is authoritative.

**Container name:**
When `log_integration` is enabled, set `container_name` at the root, or set `container_name` on every integration (per-integration values override the root default for that integration only).

**Lifecycle Management:**
`create_storage_account.expiration_days` (default 90, 0 to disable) adds an `azurerm_storage_management_policy` that auto-deletes blobs after the specified number of days.

**Index Stability:**
Removing an integration from the middle of the list causes subsequent entries to be destroyed and recreated (index shift).
Log integrations are stateless configuration, and the brief delivery gap (about one minute) causes no data loss.

Type:

```hcl
object({
  enabled = optional(bool, false)
  integrations = optional(list(object({
    log_types            = list(string)
    prefix_path          = string
    storage_account_name = optional(string)
    container_name       = optional(string)
    resource_group_name  = optional(string)
  })), [])
  storage_account_id = optional(string)
  container_name     = optional(string)
  create_container   = optional(bool, true)
  create_storage_account = optional(object({
    enabled             = bool
    name                = string
    resource_group_name = string
    azure_location      = string
    replication_type    = optional(string, "LRS")
    account_tier        = optional(string, "Standard")
    min_tls_version     = optional(string, "TLS1_2")
    expiration_days     = optional(number, 90)
  }))
  tags = optional(map(string), {})
})
```

Default: `{}`


## Timeouts

Control Terraform operation timeouts for supported resources. For upgrades from v0.2.x, see [v0.3.0 upgrade guide](docs/v0.3.0-upgrade-guide.md).

### timeouts

Timeouts for resources that the Terraform provider exposes with a `timeouts` block or attribute. Timeout values use [Go duration](https://pkg.go.dev/time#ParseDuration) format (for example, "30m", "1h").

Set `timeouts = null` to omit all module-managed timeouts and use each provider's defaults. This avoids plan diffs when upgrading from earlier module versions. It is also the usual choice right after `terraform import`: imported resources often have no module-managed timeout blocks in state, so the module’s default `"30m"` values would otherwise appear as new configuration in the next plan. Use `timeouts = null` until you are ready to adopt the module’s timeout defaults (or set partial/custom values).

- `timeouts = {}` or unset: 30m for create, update, and delete.
- `timeouts = null`: no module-managed timeouts.
- `timeouts = { create = "1h" }`: custom create timeout; 30m for other operations unless you set them.

Type:

```hcl
object({
  create = optional(string, "30m")
  update = optional(string, "30m")
  delete = optional(string, "30m")
})
```

Default: `{}`


## Optional Variables

### atlas_to_azure_region

Atlas to Azure region mapping. Keys = Atlas format, values = Azure format.
The module accepts either format in all region inputs and normalizes internally.
Override to restrict allowed regions or add custom mappings.

Type: `map(string)`

Default:

```json
{
  "ASIA_EAST": "eastasia",
  "ASIA_SOUTH_EAST": "southeastasia",
  "AUSTRALIA_CENTRAL": "australiacentral",
  "AUSTRALIA_CENTRAL_2": "australiacentral2",
  "AUSTRALIA_EAST": "australiaeast",
  "AUSTRALIA_SOUTH_EAST": "australiasoutheast",
  "BRAZIL_SOUTH": "brazilsouth",
  "BRAZIL_SOUTHEAST": "brazilsoutheast",
  "CANADA_CENTRAL": "canadacentral",
  "CANADA_EAST": "canadaeast",
  "CHILE_CENTRAL": "chilecentral",
  "EUROPE_NORTH": "northeurope",
  "EUROPE_WEST": "westeurope",
  "FRANCE_CENTRAL": "francecentral",
  "FRANCE_SOUTH": "francesouth",
  "GERMANY_NORTH": "germanynorth",
  "GERMANY_WEST_CENTRAL": "germanywestcentral",
  "INDIA_CENTRAL": "centralindia",
  "INDIA_SOUTH": "southindia",
  "INDIA_WEST": "westindia",
  "INDONESIA_CENTRAL": "indonesiacentral",
  "ISRAEL_CENTRAL": "israelcentral",
  "ITALY_NORTH": "italynorth",
  "JAPAN_EAST": "japaneast",
  "JAPAN_WEST": "japanwest",
  "KOREA_CENTRAL": "koreacentral",
  "KOREA_SOUTH": "koreasouth",
  "MALAYSIA_WEST": "malaysiawest",
  "MEXICO_CENTRAL": "mexicocentral",
  "NEW_ZEALAND_NORTH": "newzealandnorth",
  "NORWAY_EAST": "norwayeast",
  "NORWAY_WEST": "norwaywest",
  "POLAND_CENTRAL": "polandcentral",
  "QATAR_CENTRAL": "qatarcentral",
  "SOUTH_AFRICA_NORTH": "southafricanorth",
  "SOUTH_AFRICA_WEST": "southafricawest",
  "SPAIN_CENTRAL": "spaincentral",
  "SWEDEN_CENTRAL": "swedencentral",
  "SWEDEN_SOUTH": "swedensouth",
  "SWITZERLAND_NORTH": "switzerlandnorth",
  "SWITZERLAND_WEST": "switzerlandwest",
  "UAE_CENTRAL": "uaecentral",
  "UAE_NORTH": "uaenorth",
  "UK_SOUTH": "uksouth",
  "UK_WEST": "ukwest",
  "US_CENTRAL": "centralus",
  "US_EAST": "eastus",
  "US_EAST_2": "eastus2",
  "US_EAST_2_EUAP": "eastus2euap",
  "US_NORTH_CENTRAL": "northcentralus",
  "US_SOUTH_CENTRAL": "southcentralus",
  "US_WEST": "westus",
  "US_WEST_2": "westus2",
  "US_WEST_3": "westus3",
  "US_WEST_CENTRAL": "westcentralus"
}
```

### azure_tags

Tags to apply to all Azure resources (Key Vault, Storage Account, Private Endpoints).

Type: `map(string)`

Default: `{}`

<!-- END_TF_INPUTS_RAW -->

## Outputs

The following outputs are exported:

### <a name="output_backup_export"></a> [backup\_export](#output\_backup\_export)

Description: Backup export configuration status

### <a name="output_cloud_provider_access"></a> [cloud\_provider\_access](#output\_cloud\_provider\_access)

Description: Cloud Provider Access summary: role\_id, service principal IDs, and authorization metadata for the Atlas Azure integration.

### <a name="output_encryption"></a> [encryption](#output\_encryption)

Description: Encryption at rest configuration status

### <a name="output_encryption_at_rest_provider"></a> [encryption\_at\_rest\_provider](#output\_encryption\_at\_rest\_provider)

Description: Value for cluster's encryption\_at\_rest\_provider attribute

### <a name="output_export_bucket_id"></a> [export\_bucket\_id](#output\_export\_bucket\_id)

Description: Export bucket ID for backup schedule auto\_export\_enabled

### <a name="output_log_integration"></a> [log\_integration](#output\_log\_integration)

Description: Log integration configuration status

### <a name="output_privatelink"></a> [privatelink](#output\_privatelink)

Description: PrivateLink status per user key (both module-managed and BYOE).

### <a name="output_privatelink_service_info"></a> [privatelink\_service\_info](#output\_privatelink\_service\_info)

Description: Per-key Atlas PrivateLink service identifiers. Use with bring-your-own-endpoint to create `azurerm_private_endpoint` resources and then pass their IDs and IPs to `privatelink_byo_service`.

### <a name="output_regional_mode_enabled"></a> [regional\_mode\_enabled](#output\_regional\_mode\_enabled)

Description: True when privatelink\_regional\_mode is auto and there are multiple distinct Atlas regions. Default variable value is disabled. See https://www.mongodb.com/docs/atlas/security-private-endpoint/?cloud-provider=azure#-optional--regionalized-private-endpoints-for-multi-region-sharded-clusters

### <a name="output_resource_ids"></a> [resource\_ids](#output\_resource\_ids)

Description: Convenience map of role\_id, service principal, Key Vault, keys, and storage account resource IDs for references in your root module or other stacks.

### <a name="output_role_id"></a> [role\_id](#output\_role\_id)

Description: Atlas Cloud Provider Access role\_id for the Azure integration. Reuse this value for other Atlas features that need the same Azure trust relationship.
<!-- END_TF_DOCS -->

## FAQ

### When should I not use this module?

- You need full control of every Azure resource and Atlas API call outside the supported variables, and you cannot accept any module defaults or lifecycle.
- You cannot create or authorize a [service principal](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app) for Atlas or grant the Azure roles the module documents for your chosen features.
- You need a different cloud or integration pattern; consider the [Atlas AWS module](https://registry.terraform.io/modules/terraform-mongodbatlas-modules/atlas-aws/mongodbatlas/latest) or raw `mongodbatlas_*` resources for bespoke stacks.

For typical Atlas-on-Azure projects, start from the [Examples](#examples) section and the [README prerequisites](#prerequisites) under Local setup.

### How do I set `create_service_principal` and `service_principal_id`?

Use `create_service_principal = true` (default) for a module-managed service principal, or set `create_service_principal = false` and set `service_principal_id` to your existing Microsoft Entra ID object ID. Do not set `service_principal_id` when `create_service_principal = true`. Configure `MONGODB_ATLAS_CLIENT_ID` and `MONGODB_ATLAS_CLIENT_SECRET` for the Atlas provider as in [Prerequisites](#prerequisites).

### How do I upgrade to v0.3.0 (timeouts and migration)?

See the [v0.2.x to v0.3.0 upgrade guide](docs/v0.3.0-upgrade-guide.md), including the Configurable Timeouts section for `timeouts = null` (zero-diff) versus default 30m behavior.

### What is `provider_meta "mongodbatlas"` doing?

This block tracks module usage by updating the User-Agent of requests to Atlas:

```
User-Agent: terraform-provider-mongodbatlas/2.1.0 Terraform/1.13.1 module_name/atlas-azure module_version/0.1.0
```

- `provider_meta "mongodbatlas"` does not send any configuration-specific data, only the module's name and version for feature adoption tracking
- Use `export TF_LOG=debug` to see API requests with headers and responses

### Why does encryption require a client secret with a two-year expiration?

Azure limits Client Secret lifetime for CMKs to two years maximum. When the secret expires, Atlas loses access to your encryption key, causing cluster unavailability. Rotate secrets before expiration.

**v1 Roadmap:** The mongodbatlas provider will add secretless `role_id`-based authentication for Azure encryption. Once available, the module will support both methods with secretless as the recommended approach, making `encryption_client_secret` optional.
