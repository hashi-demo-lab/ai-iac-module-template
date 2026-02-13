locals {
  mandatory_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Application = "s3-static-website"
  }

  all_tags = merge(var.tags, local.mandatory_tags)
}
