## Research: Lifecycle (GLACIER) and Encryption (SSE-S3 AES256) Configuration

### Decision
Use `aws_s3_bucket_lifecycle_configuration` with conditional creation via `count = var.lifecycle_glacier_days > 0 ? 1 : 0`, and `aws_s3_bucket_server_side_encryption_configuration` with `sse_algorithm = "AES256"` always present (no toggle) -- providing cost-optimized storage tiering and unconditional encryption at rest.

### Resources Identified
- **Primary Resources**:
  - `aws_s3_bucket_lifecycle_configuration` -- manages lifecycle rules for GLACIER transitions
  - `aws_s3_bucket_server_side_encryption_configuration` -- enforces SSE-S3 (AES256) encryption
- **Supporting Resources**:
  - `aws_s3_bucket` -- the bucket itself (required dependency for both)
  - `aws_s3_bucket_versioning` -- lifecycle with versioned buckets requires `depends_on` for versioning resource

- **Key Arguments (lifecycle)**:
  - `bucket` (required) -- name of the S3 bucket
  - `rule.id` (required) -- unique identifier, e.g. `"glacier-transition"`
  - `rule.status` (required) -- `"Enabled"` or `"Disabled"`
  - `rule.filter {}` -- empty block to apply to all objects
  - `rule.transition.days` (optional, defaults to 0) -- number of days after creation; use `var.lifecycle_glacier_days`
  - `rule.transition.storage_class` (required) -- `"GLACIER"` for S3 Glacier Flexible Retrieval
  - `transition_default_minimum_object_size` -- defaults to `all_storage_classes_128K` (objects < 128 KB are skipped)

- **Key Arguments (encryption)**:
  - `bucket` (required) -- ID of the S3 bucket
  - `rule.apply_server_side_encryption_by_default.sse_algorithm` (required) -- `"AES256"` for SSE-S3
  - `rule.bucket_key_enabled` (optional) -- not needed for SSE-S3, only relevant for SSE-KMS

- **Key Outputs**:
  - `aws_s3_bucket_lifecycle_configuration.id` (`string`) -- bucket name (useful for dependency chaining)
  - `aws_s3_bucket_server_side_encryption_configuration.id` (`string`) -- bucket name

- **Security Considerations**:
  - Encryption MUST be unconditional -- no variable to disable it (FR-006 from spec). The encryption resource should always be created with `AES256`.
  - As of Jan 2023, AWS encrypts all new S3 objects with SSE-S3 by default, but the Terraform resource makes this explicit and prevents drift.
  - Destroying the encryption configuration resource resets the bucket to AWS default encryption (still SSE-S3), so there is no risk of unencrypted state.
  - Starting March 2026, AWS will block SSE-C for new buckets; `blocked_encryption_types = ["SSE-C"]` can be added proactively.

### Conditional Lifecycle Creation Pattern

The spec requires lifecycle rules to be absent when `lifecycle_glacier_days = 0` (FR-010). The recommended pattern:

```hcl
variable "lifecycle_glacier_days" {
  description = "Number of days after which objects transition to GLACIER. Set to 0 to disable lifecycle management."
  type        = number
  default     = 90

  validation {
    condition     = var.lifecycle_glacier_days >= 0
    error_message = "lifecycle_glacier_days must be a non-negative integer."
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_glacier_days > 0 ? 1 : 0
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
}
```

For encryption (always created, no conditional):

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Rationale
- **count-based conditional**: Using `count = var.lifecycle_glacier_days > 0 ? 1 : 0` is the idiomatic Terraform pattern for conditionally creating a resource based on a numeric threshold. This is preferred over `for_each` for single-instance resources. Public registry modules (e.g., Senora-dev/s3-bucket) use the same pattern for optional lifecycle rules.
- **Empty filter block**: Provider docs recommend `filter {}` (applies to all objects) instead of the deprecated `prefix` argument. This is the forward-compatible approach.
- **AES256 over aws:kms**: The spec mandates SSE-S3 (AES256) as the default. This avoids KMS key management overhead and additional cost. AWS confirms AES-256 is used for SSE-S3 and is one of the strongest available block ciphers.
- **No kms_master_key_id**: When using `AES256`, the `kms_master_key_id` argument is not applicable and must be omitted.
- **depends_on for versioning**: Provider docs explicitly show that lifecycle configuration on versioned buckets should include `depends_on = [aws_s3_bucket_versioning.this]` to ensure correct ordering.

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| `sse_algorithm = "aws:kms"` | Requires KMS key management, adds cost; spec mandates AES256 (SSE-S3) |
| `INTELLIGENT_TIERING` storage class | More complex, requires monitoring config; GLACIER is simpler and spec explicitly requires GLACIER |
| `DEEP_ARCHIVE` storage class | Higher retrieval latency (12+ hours); GLACIER (Flexible Retrieval) suits static website archival better |
| `GLACIER_IR` (Instant Retrieval) | Higher cost than GLACIER; spec explicitly calls for GLACIER |
| Dynamic block for lifecycle rules | Unnecessary complexity for a single rule; `count` on the resource is cleaner |
| `for_each` instead of `count` | `count` is simpler for a binary on/off pattern on a single resource instance |
| Lifecycle rule with `status = "Disabled"` instead of omitting | Creates unnecessary resource state; cleaner to not create the resource at all when days = 0 |

### Sources
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-configuration-examples.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html
- AWS Prescriptive Guidance: https://docs.aws.amazon.com/prescriptive-guidance/latest/encryption-best-practices/s3.html
- Provider docs: hashicorp/aws `aws_s3_bucket_lifecycle_configuration` (v6.32.0, doc ID 11440689)
- Provider docs: hashicorp/aws `aws_s3_bucket_server_side_encryption_configuration` (v6.32.0, doc ID 11440701)
- Registry pattern: Senora-dev/s3-bucket/aws/1.0.1 (lifecycle_rules input, sse_algorithm default)
