################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.all_tags
}

################################################################################
# Encryption Configuration (always created, AES256 hardcoded per FR-006)
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

################################################################################
# Ownership Controls (always created, BucketOwnerEnforced per FR-029)
################################################################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

################################################################################
# Versioning Configuration (always created, status toggled by variable)
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

################################################################################
# Public Access Block (always created, all four settings toggled by variable)
################################################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

################################################################################
# Bucket Policy Document (always created for TLS enforcement per FR-027)
################################################################################

data "aws_iam_policy_document" "this" {
  # Statement 1: DenyInsecureTransport (unconditional, always present)
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Statement 2: PublicReadGetObject (conditional, only when website + public)
  dynamic "statement" {
    for_each = var.enable_website && !var.block_public_access ? [1] : []

    content {
      sid    = "PublicReadGetObject"
      effect = "Allow"

      actions = ["s3:GetObject"]

      resources = [
        "${aws_s3_bucket.this.arn}/*",
      ]

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

################################################################################
# Bucket Policy (always created for TLS enforcement per FR-027)
################################################################################

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Website Configuration (conditional, only when website hosting is enabled)
################################################################################

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

################################################################################
# Lifecycle Configuration (conditional, only when glacier days > 0)
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.lifecycle_glacier_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    filter {}

    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER"
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# CORS Configuration (conditional, only when allowed origins are provided)
################################################################################

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_allowed_origins) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

################################################################################
# Access Logging (conditional, only when logging target bucket is provided)
################################################################################

resource "aws_s3_bucket_logging" "this" {
  count = var.logging_target_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}
