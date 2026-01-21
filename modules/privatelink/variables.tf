variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "azure_location" {
  type        = string
  description = "Azure region in lowercase format (e.g., eastus2, westeurope)."
}

variable "use_existing_endpoint" {
  type        = bool
  default     = false
  description = "Use existing Atlas PrivateLink endpoint. When true, private_link_id/service_name/service_resource_id are required."
}

variable "private_link_id" {
  type        = string
  default     = null
  description = "Atlas PrivateLink endpoint ID. Required when use_existing_endpoint = true."
}

variable "private_link_service_name" {
  type        = string
  default     = null
  description = "Atlas Private Link service name. Required when use_existing_endpoint = true."
}

variable "private_link_service_resource_id" {
  type        = string
  default     = null
  description = "Atlas Private Link endpoint resource ID. Required when use_existing_endpoint = true."
}

variable "create_azure_private_endpoint" {
  type        = bool
  default     = true
  description = "Create Azure private endpoint (module-managed). Set false for BYOE pattern."
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "Azure subnet ID. Resource group derived from this. Required when create_azure_private_endpoint = true."
}

variable "azure_private_endpoint_id" {
  type        = string
  default     = null
  description = "User-provided Azure private endpoint resource ID. Required when create_azure_private_endpoint = false."
}

variable "azure_private_endpoint_ip_address" {
  type        = string
  default     = null
  description = "Private IP address of the user-provided Azure private endpoint. Required when create_azure_private_endpoint = false."
}

variable "azure_private_endpoint_name" {
  type        = string
  default     = null
  description = "Custom name for the Azure private endpoint. Defaults to 'pe-atlas-{azure_location}'. Must be unique within resource group."
}

variable "azure_private_endpoint_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the Azure private endpoint resource."
}
