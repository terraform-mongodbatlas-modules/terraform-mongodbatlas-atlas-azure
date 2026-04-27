variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = null
  nullable    = true
  description = "When null, the module does not set provider timeouts on supported resources. Pass the root module `timeouts` value."
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

variable "container_name" {
  type        = string
  description = "Azure Blob Storage container name for backup exports"
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Azure Storage Account resource ID. Required if create_storage_account is not set."
}

variable "create_container" {
  type        = bool
  default     = true
  description = "Create the storage container. Only applies when using storage_account_id."
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
    expiration_days     = optional(number, 365)
  })
  default     = null
  description = "Create module-managed Storage Account. Mutually exclusive with storage_account_id. expiration_days defaults to 365 (AWS parity for backup export), 0 disables the management policy."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to Azure resources."
}

variable "skip_role_assignments" {
  type        = bool
  default     = false
  description = "Omit Storage Blob Data Contributor for the service principal. Pass root skip_role_assignments. The service principal must use a pre-assigned role for the target storage account."
}
