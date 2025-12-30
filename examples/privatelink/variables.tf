variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_location" {
  type        = string
  description = "Azure region in lowercase format (e.g., eastus2)"
}

variable "subnet_id" {
  type        = string
  description = "Azure subnet ID for private endpoint"
}
