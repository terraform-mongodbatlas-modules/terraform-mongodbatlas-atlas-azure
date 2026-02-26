## (Unreleased)

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
