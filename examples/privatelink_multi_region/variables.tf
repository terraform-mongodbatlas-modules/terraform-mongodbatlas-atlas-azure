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
    azure_location = string
    subnet_id      = string
    name           = optional(string)
    tags           = optional(map(string), {})
  }))
  description = "PrivateLink endpoints. Each requires azure_location and subnet_id."
}
