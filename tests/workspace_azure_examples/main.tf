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

variable "project_ids" {
  type = object({
    backup_export            = optional(string)
    encryption               = optional(string)
    privatelink              = optional(string)
    privatelink_byoe         = optional(string)
    privatelink_multi_region = optional(string)
  })
  default = {}
}

variable "encryption_client_secret" {
  type      = string
  default   = ""
  sensitive = true
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

# Client secret for encryption (only if not provided)
resource "azuread_service_principal_password" "encryption" {
  count                = var.encryption_client_secret == "" ? 1 : 0
  service_principal_id = local.service_principal_id
  display_name         = "MongoDB Atlas - Encryption Test"
}

locals {
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : module.rg[0].name
  service_principal_id = var.service_principal_id != "" ? var.service_principal_id : module.sp[0].service_principal_id
  # tflint-ignore: terraform_unused_declarations
  atlas_azure_app_id = var.atlas_azure_app_id

  # Project ID handling (follows cluster workspace pattern)
  missing_project_ids = [for k, v in var.project_ids : k if v == null]
  project_ids         = { for k, v in var.project_ids : k => v != null ? v : module.project[k].project_id }
  # tflint-ignore: terraform_unused_declarations
  project_id_backup_export = local.project_ids.backup_export
  # tflint-ignore: terraform_unused_declarations
  project_id_encryption = local.project_ids.encryption
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink = local.project_ids.privatelink
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_byoe = local.project_ids.privatelink_byoe
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_multi_region = local.project_ids.privatelink_multi_region

  # Encryption locals
  # tflint-ignore: terraform_unused_declarations
  key_vault_name = "kv-atlas-${random_string.kv_suffix.id}"
  # tflint-ignore: terraform_unused_declarations
  encryption_client_secret = var.encryption_client_secret != "" ? var.encryption_client_secret : azuread_service_principal_password.encryption[0].value

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
