terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1"
    }
  }
  required_version = ">= 1.9"
}

variable "name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region"
}

resource "azurerm_resource_group" "this" {
  name     = var.name
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
