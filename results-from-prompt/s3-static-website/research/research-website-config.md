## Research: What are the Terraform AWS provider resource configurations for aws_s3_bucket_website_configuration?

### Decision
Use `aws_s3_bucket_website_configuration` with `count` conditional on an `enable_website` variable -- this is the canonical standalone resource for S3 website hosting (provider v4+), supporting index/error documents, routing rules, and redirect-all-requests modes.

### Resources Identified
- **Primary Resource**: `aws_s3_bucket_website_configuration` -- configures static website hosting on an S3 bucket
- **Supporting Resources**:
  - `aws_s3_bucket` -- the bucket itself (required dependency; referenced via `bucket` argument)
  - `aws_s3_bucket_public_access_block` -- must be relaxed when public website access is needed
  - `aws_s3_bucket_policy` -- grants `s3:GetObject` for public website hosting
- **Key Arguments**:
  - `bucket` (required, forces new resource) -- name of the S3 bucket
  - `index_document.suffix` (required if no `redirect_all_requests_to`) -- typically `"index.html"`
  - `error_document.key` (optional, conflicts with `redirect_all_requests_to`) -- typically `"error.html"`
  - `redirect_all_requests_to.host_name` (required if no `index_document`) -- conflicts with `error_document`, `index_document`, and `routing_rule`
  - `routing_rule` (optional, conflicts with `redirect_all_requests_to` and `routing_rules`) -- list of condition/redirect blocks
  - `routing_rules` (optional, conflicts with `routing_rule`) -- JSON string alternative for rules containing empty strings
  - `expected_bucket_owner` (optional, **deprecated**, forces new resource)
- **Key Outputs**:
  - `id` (`string`) -- bucket name (or bucket,owner if expected_bucket_owner set)
  - `website_endpoint` (`string`) -- the website endpoint URL (e.g., `bucket-name.s3-website-us-east-1.amazonaws.com`)
  - `website_domain` (`string`) -- domain of website endpoint (used for Route 53 alias records)
- **Security Considerations**:
  - SSE-KMS encrypted buckets require CloudFront with OAC (not OAI) to serve website content; SSE-KMS does not support anonymous users via the S3 website endpoint
  - AES256 (SSE-S3) encryption is compatible with direct S3 website hosting
  - Public access block must be disabled before attaching a public bucket policy
  - S3 website endpoints serve HTTP only; HTTPS requires CloudFront in front

### Conditional Creation Pattern

Use `count` with a boolean variable to conditionally create the resource:

```hcl
variable "enable_website" {
  description = "Enable static website hosting configuration on the S3 bucket"
  type        = bool
  default     = false
}

resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}
```

For outputs, use conditional expressions to return null when the resource is not created:

```hcl
output "website_endpoint" {
  description = "S3 static website hosting endpoint"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_domain" {
  description = "S3 website endpoint domain (for Route 53 alias records)"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_domain : null
}
```

### Nested Block Details

| Block | Sub-argument | Required | Notes |
|-------|-------------|----------|-------|
| `index_document` | `suffix` | Yes | Must not be empty or contain `/` |
| `error_document` | `key` | Yes (within block) | Absolute object key path for 4XX errors |
| `redirect_all_requests_to` | `host_name` | Yes (within block) | Conflicts with index/error/routing |
| `redirect_all_requests_to` | `protocol` | No | `http` or `https` |
| `routing_rule` | `redirect` | Yes (within block) | Must contain at least one redirect field |
| `routing_rule` | `condition` | No | Filter by `key_prefix_equals` or `http_error_code_returned_equals` |

### Rationale
The `aws_s3_bucket_website_configuration` is the standalone resource introduced in AWS provider v4.0 as part of the S3 bucket refactoring (previously inline in `aws_s3_bucket`). Provider documentation (hashicorp/aws v6.32.0) confirms this is the canonical approach. AWS documentation confirms S3 website endpoints only serve HTTP and that SSE-KMS buckets require CloudFront+OAC. The `count`-based conditional pattern is the standard approach used by popular registry modules (e.g., cn-terraform/s3-static-website) for toggling website hosting. The spec requires `enable_website` defaulting to `false` (FR-015), making `count` the appropriate mechanism since there is a single resource instance (not multiple).

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| Inline `website` block on `aws_s3_bucket` | Deprecated in provider v4+; causes conflicts with standalone resource |
| `for_each` conditional | Unnecessary complexity for a single-instance toggle; `count` is simpler and idiomatic |
| `routing_rules` JSON string | Prefer `routing_rule` blocks for type safety; JSON string only needed when rules contain empty strings |
| Always creating website config | Violates secure-by-default principle (FR-015); website hosting should be opt-in |

### Sources
- Provider docs: hashicorp/aws v6.32.0 `aws_s3_bucket_website_configuration` (providerDocID: 11440703)
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/HostingWebsiteOnS3Setup.html
- Registry pattern: cn-terraform/s3-static-website/aws v1.0.13 (135k+ downloads)
