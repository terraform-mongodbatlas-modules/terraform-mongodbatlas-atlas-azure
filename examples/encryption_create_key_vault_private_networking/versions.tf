terraform {
  required_version = ">= 1.9"

  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.53"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0"
    }
  }

  # These values are used in the User-Agent Header
  provider_meta "mongodbatlas" {
    module_name    = "atlas-azure"
    module_version = "local"
  }
}

provider "mongodbatlas" {}
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
provider "azuread" {}
provider "azapi" {
  subscription_id = var.subscription_id
}
