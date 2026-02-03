variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = ""
}

variable "privatelink_endpoints" {
  type = list(object({
    region    = string
    subnet_id = string
    name      = optional(string)
    tags      = optional(map(string), {})
  }))
  description = "PrivateLink endpoints. `region` accepts Atlas (US_EAST_2) or Azure (eastus2) format."
}
