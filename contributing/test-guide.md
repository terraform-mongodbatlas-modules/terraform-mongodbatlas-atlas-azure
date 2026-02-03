# Testing Guide

Guide for running tests on the terraform-mongodbatlas-atlas-azure module.

## Authentication Setup

```bash
# MongoDB Atlas
export MONGODB_ATLAS_CLIENT_ID=your_sa_client_id
export MONGODB_ATLAS_CLIENT_SECRET=your_sa_client_secret
export MONGODB_ATLAS_ORG_ID=your_org_id
export MONGODB_ATLAS_BASE_URL=https://cloud.mongodb.com/  # optional

# Azure
export ARM_CLIENT_ID=your_azure_client_id
export ARM_CLIENT_SECRET=your_azure_client_secret
export ARM_TENANT_ID=your_azure_tenant_id
export ARM_SUBSCRIPTION_ID=your_azure_subscription_id
```

See [MongoDB Atlas Provider Authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) and [Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) for details.

## Test Commands

```bash
# Plan-only tests (no resources created)
just unit-plan-tests
```

## Version Compatibility Testing

```bash
just test-compat
```

Runs `terraform init` and `terraform validate` across all supported Terraform versions. Requires [mise](https://mise.jdx.dev/).

## Plan Snapshot Tests

Plan snapshot tests verify `terraform plan` output consistency. They use workspace directories under `tests/workspace_azure_examples/`.

### Generating dev.tfvars

The `dev-vars-azure` command reads from environment variables (see Authentication Setup above):

```bash
# Generate dev.tfvars from environment variables
just dev-vars-azure
```

Optional env vars:
- `MONGODB_ATLAS_PROJECT_ID` - Use same project ID for all examples (plan snapshot tests)
- `AZURE_RESOURCE_GROUP_NAME` - Use existing resource group
- `AZURE_SERVICE_PRINCIPAL_ID` - Use existing service principal (see note below)
- `EXISTING_ENCRYPTION_CLIENT_SECRET` - Use existing encryption client secret (skips creation)

**Service Principal Note**: CI uses a shared service principal for Atlas-Azure integration. Do not delete or recreate it. If you need the client secret value for local testing, retrieve it from your team's secret manager.

### Running Tests

```bash
# Run plan snapshot tests (requires full path to var file)
just plan-snapshot-test --var-file $(pwd)/tests/workspace_azure_examples/dev.tfvars

# Apply examples (creates real resources)
just apply-examples --var-file $(pwd)/tests/workspace_azure_examples/dev.tfvars --auto-approve

# Destroy resources after testing
just destroy-examples --auto-approve
```

### Snapshot Configuration

Configure examples in `tests/workspace_azure_examples/workspace_test_config.yaml`:

```yaml
examples:
  - name: encryption          # folder name (no number prefix needed)
    var_groups: [encryption]
    plan_regressions:
      - address: module.atlas_azure.module.encryption[0].mongodbatlas_encryption_at_rest.this
```

## Provider Dev Branch Testing

```bash
git clone https://github.com/mongodb/terraform-provider-mongodbatlas ../provider
just setup-provider-dev ../provider
export TF_CLI_CONFIG_FILE=$(pwd)/dev.tfrc
just unit-plan-tests
```

## CI Required Secrets

| Secret | Description |
|--------|-------------|
| `MONGODB_ATLAS_ORG_ID` | Atlas organization ID |
| `MONGODB_ATLAS_CLIENT_ID` | Service account client ID |
| `MONGODB_ATLAS_CLIENT_SECRET` | Service account client secret |
| `ARM_CLIENT_ID` | Azure service principal client ID |
| `ARM_CLIENT_SECRET` | Azure service principal client secret |
| `ARM_TENANT_ID` | Azure tenant ID |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_SERVICE_PRINCIPAL_ID` | Azure service principal object ID (for Atlas integration) |
