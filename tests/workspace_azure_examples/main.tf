terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.8"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.9"
}

provider "mongodbatlas" {}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
provider "azuread" {}

variable "org_id" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "service_principal_id" {
  type    = string
  default = ""
}

variable "atlas_azure_app_id" {
  type    = string
  default = "9f2deb0d-be22-4524-a403-df531868bac0"
}

variable "azure_location" {
  type    = string
  default = "eastus2"
}

variable "storage_account_name" {
  type    = string
  default = ""
}

variable "project_ids" {
  type = object({
    backup_export            = optional(string)
    encryption               = optional(string)
    log_integration          = optional(string)
    log_integration_byo      = optional(string)
    privatelink              = optional(string)
    privatelink_byoe         = optional(string)
    privatelink_multi_region = optional(string)
    azure_read_only          = optional(string)
  })
  default = {}
}

# Shared resource group
module "rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  source   = "../resource_group_generator"
  location = var.azure_location
}

# Shared service principal (tenant-scoped)
module "sp" {
  count              = var.service_principal_id == "" ? 1 : 0
  source             = "../service_principal_generator"
  atlas_azure_app_id = var.atlas_azure_app_id
}

# Creates projects for examples that don't have a project_id in var.project_ids
module "project" {
  for_each = toset(local.missing_project_ids)

  source = "../project_generator"
  org_id = var.org_id
}

# VNets for privatelink examples
module "vnet_eastus2" {
  source              = "../vnet_generator"
  location            = "eastus2"
  resource_group_name = local.resource_group_name
  address_space       = "10.0.0.0/16"
  subnet_prefix       = "10.0.1.0/24"
}

# Multi-region uses separate CIDR ranges to avoid conflicts:
# - eastus2: 10.2.0.0/16 (distinct from single-region vnet_eastus2 which uses 10.0.0.0/16)
# - westus2: 10.1.0.0/16
module "vnet_multi_region_eastus2" {
  source              = "../vnet_generator"
  location            = "eastus2"
  resource_group_name = local.resource_group_name
  address_space       = "10.2.0.0/16"
  subnet_prefix       = "10.2.1.0/24"
}

module "vnet_multi_region_westus2" {
  source              = "../vnet_generator"
  location            = "westus2"
  resource_group_name = local.resource_group_name
  address_space       = "10.1.0.0/16" # Distinct from eastus2 ranges
  subnet_prefix       = "10.1.1.0/24"
}

# Random suffix for resource names (key vault, storage account)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : module.rg[0].name
  # tflint-ignore: terraform_unused_declarations
  service_principal_id = var.service_principal_id != "" ? var.service_principal_id : module.sp[0].service_principal_id
  # tflint-ignore: terraform_unused_declarations
  atlas_azure_app_id = var.atlas_azure_app_id

  # Project ID handling (follows cluster workspace pattern)
  missing_project_ids = [for k, v in var.project_ids : k if v == null]
  project_ids         = { for k, v in var.project_ids : k => v != null ? v : module.project[k].project_id }
  # tflint-ignore: terraform_unused_declarations
  project_id_backup_export = local.project_ids.backup_export
  # tflint-ignore: terraform_unused_declarations
  project_id_log_integration = local.project_ids.log_integration
  # tflint-ignore: terraform_unused_declarations
  project_id_log_integration_byo = local.project_ids.log_integration_byo
  # tflint-ignore: terraform_unused_declarations
  project_id_encryption = local.project_ids.encryption
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink = local.project_ids.privatelink
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_byoe = local.project_ids.privatelink_byoe
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_multi_region = local.project_ids.privatelink_multi_region
  # tflint-ignore: terraform_unused_declarations
  project_id_azure_read_only = local.project_ids.azure_read_only

  # Encryption locals
  # tflint-ignore: terraform_unused_declarations
  key_vault_name = "kv-atlas-${random_string.suffix.id}"
  # tflint-ignore: terraform_unused_declarations
  azure_location = var.azure_location
  # Backup/log export locals
  # tflint-ignore: terraform_unused_declarations
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "saatlas${random_string.suffix.id}"
  # tflint-ignore: terraform_unused_declarations
  storage_account_name_byo_log = "sabyolog${random_string.suffix.id}"

  # PrivateLink locals - used by generated example modules (modules.generated.tf)
  # tflint-ignore: terraform_unused_declarations
  subnet_id_eastus2 = module.vnet_eastus2.subnet_id
  # tflint-ignore: terraform_unused_declarations
  static_ip_eastus2 = module.vnet_eastus2.first_usable_ip
  # tflint-ignore: terraform_unused_declarations
  region_eastus2 = "eastus2"
  # tflint-ignore: terraform_unused_declarations
  privatelink_endpoints_multi_region = [
    { region = "eastus2", subnet_id = module.vnet_multi_region_eastus2.subnet_id, name = "pe-atlas-multi-eastus2" },
    { region = "westus2", subnet_id = module.vnet_multi_region_westus2.subnet_id }
  ]
}

# BYO stand-ins for ex_azure_read_only: real Key Vault + key + two storage accounts (data sources in module need existing resources)
data "azurerm_client_config" "azure_read_only" {}

resource "azurerm_key_vault" "azure_read_only" {
  name                       = "kv-aro-${random_string.suffix.id}"
  location                   = local.azure_location
  resource_group_name        = local.resource_group_name
  tenant_id                  = data.azurerm_client_config.azure_read_only.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "azure_read_only_terraform_kv_admin" {
  scope                = azurerm_key_vault.azure_read_only.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.azure_read_only.object_id
}

resource "azurerm_key_vault_key" "azure_read_only" {
  name         = "atlas-aro-key"
  key_vault_id = azurerm_key_vault.azure_read_only.id
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

  depends_on = [azurerm_role_assignment.azure_read_only_terraform_kv_admin]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_storage_account" "azure_read_only_backup" {
  name                            = "sabk${random_string.suffix.id}"
  resource_group_name             = local.resource_group_name
  location                        = local.azure_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
}

resource "azurerm_storage_account" "azure_read_only_log" {
  name                            = "salg${random_string.suffix.id}"
  resource_group_name             = local.resource_group_name
  location                        = local.azure_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
}

locals {
  # tflint-ignore: terraform_unused_declarations
  key_vault_id_azure_read_only = azurerm_key_vault.azure_read_only.id
  # tflint-ignore: terraform_unused_declarations
  key_identifier_azure_read_only = azurerm_key_vault_key.azure_read_only.versionless_id
  # tflint-ignore: terraform_unused_declarations
  backup_storage_account_id_azure_read_only = azurerm_storage_account.azure_read_only_backup.id
  # tflint-ignore: terraform_unused_declarations
  log_storage_account_id_azure_read_only = azurerm_storage_account.azure_read_only_log.id
}

# Example module calls are generated in modules.generated.tf
