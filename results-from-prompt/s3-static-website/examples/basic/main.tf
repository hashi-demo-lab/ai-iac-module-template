module "this" {
  source = "../.."

  bucket_name = var.bucket_name
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center
}
