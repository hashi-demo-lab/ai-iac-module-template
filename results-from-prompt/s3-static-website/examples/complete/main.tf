module "this" {
  source = "../.."

  bucket_name   = var.bucket_name
  environment   = var.environment
  owner         = var.owner
  cost_center   = var.cost_center
  force_destroy = true

  # Website hosting
  enable_website      = true
  block_public_access = false
  index_document      = var.index_document
  error_document      = var.error_document

  # CORS
  cors_allowed_origins = var.cors_allowed_origins

  # Lifecycle
  lifecycle_glacier_days = var.lifecycle_glacier_days

  # Versioning
  versioning_enabled = var.versioning_enabled

  # Tags
  tags = var.tags
}
