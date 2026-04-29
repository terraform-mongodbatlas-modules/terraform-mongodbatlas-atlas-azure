variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = null
  nullable    = true
  description = "When null, the module does not set provider timeouts on supported resources. Pass the root module `timeouts` value. `mongodbatlas_log_integration` has no `timeouts` in the current mongodbatlas provider schema."
}

variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "role_id" {
  type        = string
  description = "Atlas cloud provider access role ID from cloud_provider_access_authorization"
}

variable "service_principal_id" {
  type        = string
  description = "Azure AD service principal object ID for role assignments"
}

variable "skip_role_assignments" {
  type        = bool
  default     = false
  description = "Skip Azure role assignments (for externally managed permissions)"
}

variable "container_name" {
  type        = string
  description = "Azure Blob Storage container name for log exports"
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Azure Storage Account resource ID. Required if create_storage_account is not set"
}

variable "create_container" {
  type        = bool
  default     = true
  description = "Create the storage container. Only applies when using storage_account_id"
}

variable "create_storage_account" {
  type = object({
    enabled             = bool
    name                = string
    resource_group_name = string
    azure_location      = string
    replication_type    = optional(string, "LRS")
    account_tier        = optional(string, "Standard")
    min_tls_version     = optional(string, "TLS1_2")
    expiration_days     = optional(number, 90)
  })
  default     = null
  description = "Create module-managed Storage Account. Mutually exclusive with storage_account_id"
}

variable "integrations" {
  type = list(object({
    log_types            = set(string)
    prefix_path          = string
    storage_account_name = optional(string)
    container_name       = optional(string)
    resource_group_name  = optional(string)
  }))
  description = "List of log integration configurations. Each entry creates one mongodbatlas_log_integration resource. Per-integration BYO: set storage_account_name and optionally resource_group_name (defaults to resource group inferred from storage_account_id)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to Azure resources"
}
