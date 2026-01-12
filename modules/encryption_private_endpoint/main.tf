resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AZURE"
  region_name    = var.region_name
}
