terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1"
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

# Per-example project variables (for cloud-dev override)
variable "project_id_backup_export" {
  type    = string
  default = ""
}

variable "project_id_encryption" {
  type    = string
  default = ""
}

variable "project_id_privatelink" {
  type    = string
  default = ""
}

variable "project_id_privatelink_byoe" {
  type    = string
  default = ""
}

variable "project_id_privatelink_multi_region" {
  type    = string
  default = ""
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

# Per-example projects
locals {
  example_names = ["backup_export", "encryption", "privatelink", "privatelink_byoe", "privatelink_multi_region"]
  project_vars = {
    backup_export            = var.project_id_backup_export
    encryption               = var.project_id_encryption
    privatelink              = var.project_id_privatelink
    privatelink_byoe         = var.project_id_privatelink_byoe
    privatelink_multi_region = var.project_id_privatelink_multi_region
  }
  examples_needing_projects = [for name in local.example_names : name if local.project_vars[name] == ""]
}

module "project" {
  for_each = toset(local.examples_needing_projects)
  source   = "../project_generator"
  org_id   = var.org_id
}

# VNets for privatelink examples
module "vnet_eastus2" {
  source              = "../vnet_generator"
  location            = "eastus2"
  resource_group_name = local.resource_group_name
  address_space       = "10.0.0.0/16"
  subnet_prefix       = "10.0.1.0/24"
}

module "vnet_westeurope" {
  source              = "../vnet_generator"
  location            = "westeurope"
  resource_group_name = local.resource_group_name
  address_space       = "10.1.0.0/16"
  subnet_prefix       = "10.1.1.0/24"
}

# Random suffix for key vault name
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Client secret for encryption
resource "azuread_service_principal_password" "encryption" {
  service_principal_id = local.service_principal_id
  display_name         = "MongoDB Atlas - Encryption Test"
}

locals {
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : module.rg[0].name
  service_principal_id = var.service_principal_id != "" ? var.service_principal_id : module.sp[0].service_principal_id
  atlas_azure_app_id   = var.atlas_azure_app_id

  # Per-example project IDs
  # tflint-ignore: terraform_unused_declarations
  project_id_backup_export = var.project_id_backup_export != "" ? var.project_id_backup_export : module.project["backup_export"].project_id
  # tflint-ignore: terraform_unused_declarations
  project_id_encryption = var.project_id_encryption != "" ? var.project_id_encryption : module.project["encryption"].project_id
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink = var.project_id_privatelink != "" ? var.project_id_privatelink : module.project["privatelink"].project_id
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_byoe = var.project_id_privatelink_byoe != "" ? var.project_id_privatelink_byoe : module.project["privatelink_byoe"].project_id
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_multi_region = var.project_id_privatelink_multi_region != "" ? var.project_id_privatelink_multi_region : module.project["privatelink_multi_region"].project_id

  # Encryption locals
  # tflint-ignore: terraform_unused_declarations
  key_vault_name = "kv-atlas-${random_string.kv_suffix.id}"
  # tflint-ignore: terraform_unused_declarations
  encryption_client_secret = azuread_service_principal_password.encryption.value

  # PrivateLink locals
  # tflint-ignore: terraform_unused_declarations
  subnet_id_eastus2 = module.vnet_eastus2.subnet_id
  # tflint-ignore: terraform_unused_declarations
  static_ip_eastus2 = module.vnet_eastus2.first_usable_ip
  # tflint-ignore: terraform_unused_declarations
  subnet_ids_multi_region = {
    eastus2    = module.vnet_eastus2.subnet_id
    westeurope = module.vnet_westeurope.subnet_id
  }
}

# Example module calls are generated in modules.generated.tf
