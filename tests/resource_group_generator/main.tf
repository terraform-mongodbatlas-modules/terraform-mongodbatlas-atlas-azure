terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.9"
}

variable "name" {
  type        = string
  default     = ""
  description = "Resource group name. If empty, generates from prefix + random suffix."
}

variable "name_prefix" {
  type        = string
  default     = "rg-atlas-test-"
  description = "Resource group name prefix when auto-generating."
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region."
}

resource "random_string" "suffix" {
  count = var.name == "" ? 1 : 0
  keepers = {
    first = timestamp()
  }
  length  = 6
  special = false
  upper   = false
}

locals {
  name = var.name != "" ? var.name : "${var.name_prefix}${random_string.suffix[0].id}"
}

resource "azurerm_resource_group" "this" {
  name     = local.name
  location = var.location
}

output "name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "id" {
  value = azurerm_resource_group.this.id
}
