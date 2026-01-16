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

variable "project_id" {
  type    = string
  default = ""
}

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

variable "project_name_prefix" {
  type    = string
  default = "test-acc-tf-p-"
}

variable "resource_group_prefix" {
  type    = string
  default = "rg-atlas-test"
}

variable "azure_location" {
  type    = string
  default = "eastus2"
}

locals {
  needs_generation = var.project_id == "" || var.resource_group_name == "" || var.service_principal_id == ""
}

resource "random_string" "suffix" {
  count = local.needs_generation ? 1 : 0
  keepers = {
    first = timestamp()
  }
  length  = 6
  special = false
  upper   = false
}

module "project" {
  count        = var.project_id == "" ? 1 : 0
  source       = "../project_generator"
  org_id       = var.org_id
  project_name = "${var.project_name_prefix}${random_string.suffix[0].id}"
}

module "rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  source   = "../resource_group_generator"
  name     = "${var.resource_group_prefix}-${random_string.suffix[0].id}"
  location = var.azure_location
}

module "sp" {
  count              = var.service_principal_id == "" ? 1 : 0
  source             = "../service_principal_generator"
  atlas_azure_app_id = var.atlas_azure_app_id
}

locals {
  # tflint-ignore: terraform_unused_declarations
  project_id = var.project_id != "" ? var.project_id : module.project[0].project_id
  # tflint-ignore: terraform_unused_declarations
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : module.rg[0].name
  # tflint-ignore: terraform_unused_declarations
  service_principal_id = var.service_principal_id != "" ? var.service_principal_id : module.sp[0].service_principal_id
  # tflint-ignore: terraform_unused_declarations
  atlas_azure_app_id = var.atlas_azure_app_id
}

# Example module calls are generated in modules.generated.tf
