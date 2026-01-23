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

variable "name_prefix" {
  type    = string
  default = "vnet-atlas-test-"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}${random_string.suffix.id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "atlas" {
  name                              = "snet-atlas-pe"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.subnet_prefix]
  private_endpoint_network_policies = "Disabled"
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_id" {
  value = azurerm_subnet.atlas.id
}

output "subnet_address_prefix" {
  value = var.subnet_prefix
}

output "first_usable_ip" {
  value = cidrhost(var.subnet_prefix, 4)
}
