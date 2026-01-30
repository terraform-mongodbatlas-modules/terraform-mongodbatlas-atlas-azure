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
  description = "Region in Atlas format (US_EAST_2) or Azure format (eastus2)"
}

variable "subnet_id" {
  type        = string
  description = "Azure subnet ID for private endpoint"
}
