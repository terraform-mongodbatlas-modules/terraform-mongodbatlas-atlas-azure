variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "region" {
  type        = string
  description = "Region in Atlas (US_EAST_2) or Azure (eastus2) format"
}

variable "subnet_id" {
  type        = string
  description = "Azure subnet ID for private endpoint"
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name for private endpoint"
}

variable "static_ip_address" {
  type        = string
  description = "Static IP address for the private endpoint (must be within subnet range)"
}
