# Basic module tests
# Validates default configuration, feature toggles, and input validation.

mock_provider "aws" {}

################################################################################
# T025: Default configuration (required variables only)
################################################################################

run "default_configuration" {
  command = plan

  variables {
    bucket_name = "test-basic-bucket-001"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  # Bucket name matches input
  assert {
    condition     = aws_s3_bucket.this.bucket == "test-basic-bucket-001"
    error_message = "Bucket name should match the provided variable."
  }

  # force_destroy defaults to false
  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "Force destroy should default to false."
  }

  # Encryption uses AES256 (rule is a set, use one() to extract the single element)
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm) == "AES256"
    error_message = "Encryption should use AES256 algorithm."
  }

  # Versioning status is Enabled
  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be Enabled by default."
  }

  # All four public access block settings are true
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should be true by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy should be true by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls should be true by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true by default."
  }

  # Lifecycle transitions to GLACIER after 90 days (transition is a set, extract with one())
  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[*].days) == 90
    error_message = "Lifecycle should transition to GLACIER after 90 days by default."
  }

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[*].storage_class) == "GLACIER"
    error_message = "Lifecycle should transition to GLACIER storage class."
  }

  # Website outputs are null (enable_website defaults false)
  assert {
    condition     = output.website_endpoint == null
    error_message = "Website endpoint should be null when website is disabled."
  }

  assert {
    condition     = output.website_domain == null
    error_message = "Website domain should be null when website is disabled."
  }

  # Mandatory tags present
  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "dev"
    error_message = "Environment tag should be set."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Owner"] == "platform-team"
    error_message = "Owner tag should be set."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["CostCenter"] == "CC-1234"
    error_message = "CostCenter tag should be set."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be set to terraform."
  }

  # Ownership controls set to BucketOwnerEnforced
  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "Ownership controls should be set to BucketOwnerEnforced."
  }

  # Website configuration should not be created (enable_website defaults to false)
  assert {
    condition     = length(aws_s3_bucket_website_configuration.this) == 0
    error_message = "Website configuration should not be created when enable_website is false."
  }

  # CORS configuration should not be created (cors_allowed_origins defaults to empty)
  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 0
    error_message = "CORS configuration should not be created when cors_allowed_origins is empty."
  }
}

################################################################################
# T027: Feature toggle tests
################################################################################

run "versioning_disabled" {
  command = plan

  variables {
    bucket_name        = "test-versioning-disabled"
    environment        = "dev"
    owner              = "platform-team"
    cost_center        = "CC-1234"
    versioning_enabled = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Suspended"
    error_message = "Versioning status should be Suspended when versioning_enabled is false."
  }
}

run "lifecycle_disabled" {
  command = plan

  variables {
    bucket_name            = "test-lifecycle-disabled"
    environment            = "dev"
    owner                  = "platform-team"
    cost_center            = "CC-1234"
    lifecycle_glacier_days = 0
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "Lifecycle configuration should not be created when lifecycle_glacier_days is 0."
  }
}

run "website_with_blocked_access" {
  command = plan

  variables {
    bucket_name         = "test-website-blocked"
    environment         = "dev"
    owner               = "platform-team"
    cost_center         = "CC-1234"
    enable_website      = true
    block_public_access = true
  }

  # Website config should exist
  assert {
    condition     = length(aws_s3_bucket_website_configuration.this) == 1
    error_message = "Website configuration should be created when enable_website is true."
  }

  # Public access block should be true (blocking public access)
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy should be true when block_public_access is true."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should be true when block_public_access is true."
  }
}

################################################################################
# T028: Input validation tests
################################################################################

run "reject_empty_bucket_name" {
  command = plan

  variables {
    bucket_name = ""
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_uppercase_bucket_name" {
  command = plan

  variables {
    bucket_name = "My-Bucket-Name"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_consecutive_periods" {
  command = plan

  variables {
    bucket_name = "my..bucket"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_ip_address_format" {
  command = plan

  variables {
    bucket_name = "192.168.1.1"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_reserved_prefix" {
  command = plan

  variables {
    bucket_name = "xn--test-bucket"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_reserved_suffix" {
  command = plan

  variables {
    bucket_name = "test-bucket-s3alias"
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.bucket_name]
}

run "reject_invalid_environment" {
  command = plan

  variables {
    bucket_name = "test-bucket-env"
    environment = "production"
    owner       = "platform-team"
    cost_center = "CC-1234"
  }

  expect_failures = [var.environment]
}

run "reject_empty_owner" {
  command = plan

  variables {
    bucket_name = "test-bucket-owner"
    environment = "dev"
    owner       = ""
    cost_center = "CC-1234"
  }

  expect_failures = [var.owner]
}

run "reject_empty_cost_center" {
  command = plan

  variables {
    bucket_name = "test-bucket-cost"
    environment = "dev"
    owner       = "platform-team"
    cost_center = ""
  }

  expect_failures = [var.cost_center]
}

run "reject_negative_lifecycle_days" {
  command = plan

  variables {
    bucket_name            = "test-bucket-lifecycle"
    environment            = "dev"
    owner                  = "platform-team"
    cost_center            = "CC-1234"
    lifecycle_glacier_days = -1
  }

  expect_failures = [var.lifecycle_glacier_days]
}
