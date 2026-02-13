# Module Interface Specification

**Feature**: S3 Static Website Hosting Module
**Date**: 2026-02-13
**Source**: Derived from plan.md resource inventory, spec.md requirements, and research findings

## Module: terraform-aws-s3-static-website
**Registry Path:** `terraform-aws-s3-static-website`
**Version:** `0.1.0`

### Inputs (Variables)

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `bucket_name` | `string` | yes | - | Name of the S3 bucket. Must comply with AWS S3 bucket naming rules (lowercase, 3-63 chars, no reserved prefixes/suffixes). |
| `environment` | `string` | yes | - | Target deployment environment. Must be one of: dev, staging, prod. |
| `owner` | `string` | yes | - | Team or individual responsible for this bucket. Used as mandatory tag. |
| `cost_center` | `string` | yes | - | Cost center code for billing attribution. Used as mandatory tag. |
| `versioning_enabled` | `bool` | no | `true` | Enable object versioning on the bucket. When false, versioning status is set to Suspended. |
| `enable_website` | `bool` | no | `false` | Enable static website hosting configuration on the bucket. |
| `index_document` | `string` | no | `"index.html"` | Name of the index document for website hosting. Only used when enable_website is true. |
| `error_document` | `string` | no | `"error.html"` | Name of the error document for website hosting. Only used when enable_website is true. |
| `lifecycle_glacier_days` | `number` | no | `90` | Number of days after which objects transition to GLACIER storage class. Set to 0 to disable lifecycle management. |
| `block_public_access` | `bool` | no | `true` | Block all public access to the bucket. Set to false to enable direct public website hosting. WARNING: Setting this to false allows public access to bucket contents when combined with enable_website. |
| `cors_allowed_origins` | `list(string)` | no | `[]` | List of allowed origins for CORS configuration. Empty list disables CORS. |
| `force_destroy` | `bool` | no | `false` | Allow destruction of non-empty bucket. Set to true only for testing. |
| `tags` | `map(string)` | no | `{}` | Additional tags to apply to all resources. Mandatory tags (Environment, Owner, CostCenter, ManagedBy) take precedence over consumer-provided tags with conflicting keys. |
| `logging_target_bucket` | `string` | no | `null` | Target S3 bucket name for server access logging. When null, access logging is disabled. |
| `logging_target_prefix` | `string` | no | `""` | Prefix for access log object keys in the target bucket. |

### Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `bucket_id` | `string` | no | Name/ID of the S3 bucket |
| `bucket_arn` | `string` | no | ARN of the S3 bucket |
| `bucket_domain_name` | `string` | no | Bucket domain name (e.g., bucket.s3.amazonaws.com) |
| `bucket_regional_domain_name` | `string` | no | Regional bucket domain name (e.g., bucket.s3.us-east-1.amazonaws.com) |
| `website_endpoint` | `string` | no | S3 static website hosting endpoint. Null when enable_website is false. HTTP only; use CloudFront for HTTPS. |
| `website_domain` | `string` | no | S3 website endpoint domain (for Route 53 alias records). Null when enable_website is false. |

### Variable Validation Rules

| Variable | Validation | Error Message |
|----------|-----------|---------------|
| `bucket_name` | `length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63` | Bucket name must be between 3 and 63 characters. |
| `bucket_name` | `can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))` | Bucket name must start and end with a lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods. |
| `bucket_name` | `!can(regex("\\.\\.", var.bucket_name))` | Bucket name must not contain two consecutive periods. |
| `bucket_name` | `!can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name))` | Bucket name must not be formatted as an IP address. |
| `bucket_name` | `!can(regex("^(xn--\|sthree-\|sthree-configurator\|amzn-s3-demo-)", var.bucket_name))` | Bucket name must not start with reserved prefixes. |
| `bucket_name` | `!can(regex("(-s3alias\|--ol-s3\|\\.mrap\|--x-s3\|--table-s3)$", var.bucket_name))` | Bucket name must not end with reserved suffixes. |
| `environment` | `contains(["dev", "staging", "prod"], var.environment)` | Environment must be dev, staging, or prod. |
| `owner` | `length(var.owner) > 0` | Owner must not be empty. |
| `cost_center` | `length(var.cost_center) > 0` | Cost center must not be empty. |
| `lifecycle_glacier_days` | `var.lifecycle_glacier_days >= 0` | lifecycle_glacier_days must be a non-negative integer. |

## Resource Dependencies

| Resource | Logical Name | Depends On | Relationship |
|----------|-------------|-----------|--------------|
| `aws_s3_bucket` | `this` | (none) | Root resource; all others depend on it |
| `aws_s3_bucket_server_side_encryption_configuration` | `this` | `aws_s3_bucket.this` | Encryption config attached to bucket |
| `aws_s3_bucket_versioning` | `this` | `aws_s3_bucket.this` | Versioning config attached to bucket |
| `aws_s3_bucket_public_access_block` | `this` | `aws_s3_bucket.this` | Public access controls attached to bucket |
| `aws_s3_bucket_lifecycle_configuration` | `this` | `aws_s3_bucket.this`, `aws_s3_bucket_versioning.this` | Lifecycle rules; depends_on versioning per provider docs |
| `aws_s3_bucket_website_configuration` | `this` | `aws_s3_bucket.this` | Website hosting config attached to bucket |
| `aws_s3_bucket_cors_configuration` | `this` | `aws_s3_bucket.this` | CORS rules attached to bucket |
| `aws_s3_bucket_ownership_controls` | `this` | `aws_s3_bucket.this` | Ownership controls attached to bucket |
| `aws_s3_bucket_logging` | `this` | `aws_s3_bucket.this` | Access logging configuration (conditional) |
| `data.aws_iam_policy_document` | `this` | `aws_s3_bucket.this` | References bucket ARN for resource field; contains DenyInsecureTransport (always) and PublicReadGetObject (conditional dynamic) |
| `aws_s3_bucket_policy` | `this` | `aws_s3_bucket.this`, `aws_s3_bucket_public_access_block.this` | Explicit depends_on public access block; always created for TLS enforcement |

## Resource-to-Output Mapping

| Resource | Attribute | Output |
|----------|-----------|--------|
| `aws_s3_bucket.this` | `id` | `bucket_id` |
| `aws_s3_bucket.this` | `arn` | `bucket_arn` |
| `aws_s3_bucket.this` | `bucket_domain_name` | `bucket_domain_name` |
| `aws_s3_bucket.this` | `bucket_regional_domain_name` | `bucket_regional_domain_name` |
| `aws_s3_bucket_website_configuration.this[0]` | `website_endpoint` | `website_endpoint` (via `try()`, null when not created) |
| `aws_s3_bucket_website_configuration.this[0]` | `website_domain` | `website_domain` (via `try()`, null when not created) |

## Conditional Creation Logic

| Resource | Condition | Count Expression |
|----------|-----------|-----------------|
| `aws_s3_bucket.this` | Always created | (no count) |
| `aws_s3_bucket_server_side_encryption_configuration.this` | Always created | (no count) |
| `aws_s3_bucket_versioning.this` | Always created (status varies) | (no count; status = `var.versioning_enabled ? "Enabled" : "Suspended"`) |
| `aws_s3_bucket_public_access_block.this` | Always created (settings vary) | (no count; all four settings = `var.block_public_access`) |
| `aws_s3_bucket_lifecycle_configuration.this` | Only when lifecycle days > 0 | `count = var.lifecycle_glacier_days > 0 ? 1 : 0` |
| `aws_s3_bucket_website_configuration.this` | Only when website enabled | `count = var.enable_website ? 1 : 0` |
| `aws_s3_bucket_cors_configuration.this` | Only when CORS origins provided | `count = length(var.cors_allowed_origins) > 0 ? 1 : 0` |
| `data.aws_iam_policy_document.this` | Always created (TLS enforcement unconditional per FR-027; PublicReadGetObject statement conditional via dynamic block) | (no count) |
| `aws_s3_bucket_policy.this` | Always created (TLS enforcement unconditional per FR-027) | (no count) |
| `aws_s3_bucket_ownership_controls.this` | Always created | (no count; `object_ownership = "BucketOwnerEnforced"`) |
| `aws_s3_bucket_logging.this` | Only when logging target provided | `count = var.logging_target_bucket != null ? 1 : 0` |

## Locals

| Local | Expression | Purpose |
|-------|-----------|---------|
| `mandatory_tags` | `{ Environment = var.environment, Owner = var.owner, CostCenter = var.cost_center, ManagedBy = "terraform" }` | Tags that are always applied and override consumer tags (includes ManagedBy per constitution 7.4) |
| `all_tags` | `merge(var.tags, local.mandatory_tags)` | Consumer tags merged with mandatory tags (mandatory wins on conflict) |
