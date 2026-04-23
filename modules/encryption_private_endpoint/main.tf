resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AZURE"
  region_name    = var.region_name

  timeouts = var.timeouts != null ? {
    create = var.timeouts.create
    delete = var.timeouts.delete
  } : null
}

data "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AZURE"
  id             = mongodbatlas_encryption_at_rest_private_endpoint.this.id
}
