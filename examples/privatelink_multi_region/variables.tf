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
  type = map(object({
    subnet_id = string
    name      = optional(string)
  }))
  description = "Map of Azure location to PrivateLink endpoint config (e.g., {eastus2 = {subnet_id = '/subscriptions/.../subnets/...', name = 'pe-my-eastus2'}})"
}
