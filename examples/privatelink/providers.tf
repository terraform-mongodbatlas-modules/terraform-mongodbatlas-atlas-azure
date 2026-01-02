terraform {
  required_version = ">= 1.0"

  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "mongodbatlas" {}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
