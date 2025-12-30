variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "azure_location" {
  type        = string
  description = "Azure region in lowercase format (e.g., eastus2, westeurope)"
}

variable "private_link_id" {
  type        = string
  description = "Atlas PrivateLink endpoint ID from mongodbatlas_privatelink_endpoint resource"
}

variable "private_link_service_name" {
  type        = string
  description = "Azure Private Link Service name from mongodbatlas_privatelink_endpoint resource"
}

variable "private_link_service_resource_id" {
  type        = string
  description = "Azure Private Link Service resource ID from mongodbatlas_privatelink_endpoint resource"
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
