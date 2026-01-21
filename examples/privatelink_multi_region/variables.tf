variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = ""
}

variable "subnet_ids" {
  type        = map(string)
  description = "Map of Azure location to subnet ID for PrivateLink endpoints (e.g., {eastus2 = '/subscriptions/.../subnets/...', westeurope = '...'})"
}
