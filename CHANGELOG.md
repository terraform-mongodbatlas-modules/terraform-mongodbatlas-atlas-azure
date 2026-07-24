## (Unreleased)

NOTES:

* provider/mongodbatlas: Requires minimum version 2.11.0 for `mongodbatlas_privatelink_endpoint` update timeout support ([#70](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/70))
* terraform: Requires minimum version 1.10 to align with the MongoDB Atlas provider compatibility matrix ([#70](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/70))

## 0.3.0 (April 30, 2026)

BREAKING CHANGES:

* module: Makes private endpoint regional mode opt-in. Set `privatelink_regional_mode` to `auto` to restore the previous automatic behavior when using multiple distinct Atlas regions ([#49](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/49))
* output/encryption.private_endpoints: `module.encryption_private_endpoint` and `encryption` output map keys use normalized Azure location strings ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/43))
* variable/privatelink_byo_endpoint: Changes type from `map(string)` to `map(object({ region }))` to future proof support for cross-region BYOE PrivateLink ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/43))
* variable/privatelink_byo_endpoint: Renames `privatelink_byoe_regions` to `privatelink_byo_endpoint` to represent the Atlas-side BYOE PrivateLink endpoint ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/43))
* variable/privatelink_byo_service: Renames `privatelink_byoe` to `privatelink_byo_service` to represent the user-managed Azure private endpoint linked to Atlas ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/43))

NOTES:

* provider/mongodbatlas: Aligns minimum version to 2.8 in backup export, encryption, and private link submodules ([#47](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/47))
* provider/mongodbatlas: Requires minimum version 2.8.0 for `mongodbatlas_log_integration` resource support ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/39))
* variable/encryption_client_secret: Deprecates this variable in favor of secretless authorization based on the Cloud Provider Access `role_id` ([#42](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/42))

ENHANCEMENTS:

* examples/azure_read_only: Demonstrates module usage for Azure credentials with read only access ([#46](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/46))
* output/log_integration: Exposes log export status with storage account id, container name, service URL, integration ids, and blob expiration_days when `log_integration` is enabled ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/39))
* submodule/encryption: Uses Cloud Provider Access role_id for Azure Key Vault encryption at rest so the default path does not require encryption_client_secret in state ([#42](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/42))
* submodule/log_integration: Adds Log Integration submodule for exporting Atlas logs to Azure Blob Storage via `mongodbatlas_log_integration` ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/39))
* variable/backup_export: Adds `create_storage_account.expiration_days` (default 365, 0 to disable) with optional `azurerm_storage_management_policy` for export container blob retention ([#44](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/44))
* variable/log_integration: Adds `log_integration` variable with optional module-managed Storage Account, user-supplied `storage_account_id` (BYO), container lifecycle, per-integration storage account and container overrides, and Azure role assignments to the existing CPA service principal (with `skip_role_assignments` to manage permissions outside module) ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/39))
* variable/skip_role_assignments: Skip all `azurerm_role_assignment` resources in encryption, backup export, and log integration to allow module users with read-only azure access ([#45](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/45))
* variable/timeouts: Adds optional nullable `timeouts` with 30m defaults for create, update, and delete, applied to supported Atlas and Azure resources. See docs/v0.3.0-upgrade-guide.md for details ([#41](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/41))

BUG FIXES:

* provider/azurerm: Requires minimum version 4.42 ([#47](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-azure/pull/47))

## 0.2.0 (February 25, 2026)

BREAKING CHANGES:

* module: Replaces check blocks (plan-time warnings) with terraform_data preconditions (plan-time errors) for region validation. Configurations with invalid regions that previously produced warnings will now fail during plan ([#31](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-azure/pull/31))
* submodule/encryption: Exposes `enabled_for_search_nodes` with secure default (`true`) to control BYOK encryption for dedicated search nodes. Existing deployments with `encryption.enabled = true` and dedicated search nodes will see `enabled_for_search_nodes` flip from `false` to `true` on upgrade. This triggers search node reprovisioning and index rebuild. Set `enabled_for_search_nodes = false` explicitly to preserve current behavior ([#30](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-azure/pull/30))

ENHANCEMENTS:

* variable/atlas_to_azure_region: Exposes region mapping as an overridable variable instead of hardcoded locals, allowing users to restrict or customize allowed regions ([#31](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-azure/pull/31))

## 0.1.1 (February 11, 2026)

BUG FIXES:

* output/export_bucket_id: Uses correct `export_bucket_id` instead of internal `id` field ([#27](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-azure/pull/27))

## 0.1.0 (February 04, 2026)
* Initial release
