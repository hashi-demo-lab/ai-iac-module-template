# Complete module tests
# Validates full-featured configuration with all features enabled.

mock_provider "aws" {}

################################################################################
# T026: Full-featured configuration
################################################################################

run "full_featured_configuration" {
  command = plan

  variables {
    bucket_name            = "test-complete-bucket-001"
    environment            = "prod"
    owner                  = "web-team"
    cost_center            = "CC-5678"
    enable_website         = true
    block_public_access    = false
    index_document         = "home.html"
    error_document         = "404.html"
    lifecycle_glacier_days = 30
    cors_allowed_origins   = ["https://example.com"]
    force_destroy          = true
    tags = {
      Project = "test"
    }
  }

  # Website config created with custom documents
  assert {
    condition     = length(aws_s3_bucket_website_configuration.this) == 1
    error_message = "Website configuration should be created when enable_website is true."
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.this[0].index_document[0].suffix == "home.html"
    error_message = "Index document should be set to home.html."
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.this[0].error_document[0].key == "404.html"
    error_message = "Error document should be set to 404.html."
  }

  # Public access block all false
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == false
    error_message = "block_public_acls should be false when block_public_access is false."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == false
    error_message = "block_public_policy should be false when block_public_access is false."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == false
    error_message = "ignore_public_acls should be false when block_public_access is false."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == false
    error_message = "restrict_public_buckets should be false when block_public_access is false."
  }

  # Bucket policy is always created (TLS enforcement + public read)
  # Verify the bucket name is correct on the bucket resource
  assert {
    condition     = aws_s3_bucket.this.bucket == "test-complete-bucket-001"
    error_message = "Bucket name should match the provided variable."
  }

  # CORS configured with specified origins
  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 1
    error_message = "CORS configuration should be created when cors_allowed_origins is non-empty."
  }

  assert {
    condition     = contains(one(aws_s3_bucket_cors_configuration.this[0].cors_rule[*].allowed_origins), "https://example.com")
    error_message = "CORS allowed origins should contain https://example.com."
  }

  assert {
    condition     = contains(one(aws_s3_bucket_cors_configuration.this[0].cors_rule[*].allowed_methods), "GET")
    error_message = "CORS allowed methods should contain GET."
  }

  assert {
    condition     = contains(one(aws_s3_bucket_cors_configuration.this[0].cors_rule[*].allowed_methods), "HEAD")
    error_message = "CORS allowed methods should contain HEAD."
  }

  # Lifecycle transition at 30 days (transition is a set, use one() to extract)
  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[*].days) == 30
    error_message = "Lifecycle should transition after 30 days."
  }

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[*].storage_class) == "GLACIER"
    error_message = "Lifecycle should transition to GLACIER storage class."
  }

  # Website configuration exists (which means the endpoint output will be non-null)
  # output.website_endpoint is computed and unknown at plan time with mock provider,
  # so we verify the website resource exists instead
  assert {
    condition     = aws_s3_bucket_website_configuration.this[0].index_document[0].suffix == "home.html"
    error_message = "Website configuration should exist with the correct index document."
  }

  # Custom tags merged with mandatory tags
  assert {
    condition     = aws_s3_bucket.this.tags["Project"] == "test"
    error_message = "Custom tag Project should be present."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "prod"
    error_message = "Mandatory Environment tag should be present."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Owner"] == "web-team"
    error_message = "Mandatory Owner tag should be present."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["CostCenter"] == "CC-5678"
    error_message = "Mandatory CostCenter tag should be present."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "Mandatory ManagedBy tag should be present."
  }

  # force_destroy is true
  assert {
    condition     = aws_s3_bucket.this.force_destroy == true
    error_message = "force_destroy should be true when set."
  }
}

################################################################################
# Tag precedence: mandatory tags override conflicting consumer tags
################################################################################

run "mandatory_tag_precedence" {
  command = plan

  variables {
    bucket_name = "test-tag-precedence-001"
    environment = "dev"
    owner       = "infra-team"
    cost_center = "CC-9999"
    tags = {
      Environment = "should-be-overridden"
      ManagedBy   = "should-be-overridden"
      CustomTag   = "should-survive"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "dev"
    error_message = "Mandatory Environment tag must override consumer tag."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "Mandatory ManagedBy tag must override consumer tag."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["CustomTag"] == "should-survive"
    error_message = "Non-conflicting consumer tags must be preserved."
  }
}

################################################################################
# Logging feature toggle
################################################################################

run "logging_enabled" {
  command = plan

  variables {
    bucket_name           = "test-logging-001"
    environment           = "dev"
    owner                 = "infra-team"
    cost_center           = "CC-0001"
    logging_target_bucket = "my-log-bucket"
    logging_target_prefix = "s3-logs/"
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 1
    error_message = "Logging should be created when logging_target_bucket is provided."
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "my-log-bucket"
    error_message = "Logging target bucket should match provided variable."
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_prefix == "s3-logs/"
    error_message = "Logging target prefix should match provided variable."
  }
}
