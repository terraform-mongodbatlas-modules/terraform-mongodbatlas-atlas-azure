variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "primary_azure_location" {
  type        = string
  description = "Primary Azure region in lowercase format (e.g., eastus2)"
}

variable "primary_subnet_id" {
  type        = string
  description = "Azure subnet ID for primary region private endpoint"
}

variable "additional_regions" {
  type = map(object({
    subnet_id = string
  }))
  default     = {}
  description = "Additional regions for multi-region PrivateLink"
}
