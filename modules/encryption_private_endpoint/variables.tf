variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = null
  nullable    = true
  description = "When null, the module does not set the `timeouts` attribute on the Atlas resource. Pass the root module `timeouts` value."
}

variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "region_name" {
  type        = string
  description = "Atlas region format (e.g., US_EAST_2, EUROPE_WEST)"
}
