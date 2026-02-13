## Research: S3 Bucket Naming Rules, Terraform Validation, and Minimum Provider Version

### Decision
Enforce AWS S3 general-purpose bucket naming rules via Terraform `variable` validation blocks using regex, and require AWS provider `>= 4.9.0` as the minimum version for stable standalone S3 resources.

### S3 Bucket Naming Rules (from AWS docs)

1. **Length**: 3-63 characters
2. **Allowed characters**: lowercase letters (`a-z`), numbers (`0-9`), hyphens (`-`), and periods (`.`)
3. **Must begin and end** with a letter or number
4. **Must not** contain two adjacent periods (`..`)
5. **Must not** be formatted as an IP address (e.g., `192.168.5.4`)
6. **Reserved prefixes**: must not start with `xn--`, `sthree-`, `sthree-configurator`, or `amzn-s3-demo-`
7. **Reserved suffixes**: must not end with `-s3alias`, `--ol-s3`, `.mrap`, `--x-s3`, or `--table-s3`
8. **Globally unique** across all AWS accounts in a partition
9. **Best practice**: avoid periods for non-website buckets (breaks virtual-host-style HTTPS)

### Terraform Variable Validation Expressions

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket. Must comply with AWS naming rules."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }

  validation {
    condition     = !can(regex("\\.\\.", var.bucket_name))
    error_message = "Bucket name must not contain two consecutive periods."
  }

  validation {
    condition     = !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name))
    error_message = "Bucket name must not be formatted as an IP address."
  }

  validation {
    condition     = !can(regex("^(xn--|sthree-|sthree-configurator|amzn-s3-demo-)", var.bucket_name))
    error_message = "Bucket name must not start with reserved prefixes (xn--, sthree-, sthree-configurator, amzn-s3-demo-)."
  }

  validation {
    condition     = !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3)$", var.bucket_name))
    error_message = "Bucket name must not end with reserved suffixes (-s3alias, --ol-s3, .mrap, --x-s3, --table-s3)."
  }
}
```

**For static website modules that disallow periods** (to support Transfer Acceleration and virtual-host HTTPS):

```hcl
  validation {
    condition     = !can(regex("\\.", var.bucket_name))
    error_message = "Bucket name must not contain periods (recommended for non-website S3 usage and Transfer Acceleration compatibility)."
  }
```

### Minimum AWS Provider Version for Standalone S3 Resources

| Resource | Introduced | Stable Since | Notes |
|----------|-----------|-------------|-------|
| `aws_s3_bucket` | v1.x | v1.x | Core resource |
| `aws_s3_bucket_public_access_block` | v2.x | v2.x | Predates v4 refactor |
| `aws_s3_bucket_policy` | v1.x | v1.x | Predates v4 refactor |
| `aws_s3_bucket_versioning` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_server_side_encryption_configuration` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_website_configuration` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_cors_configuration` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_logging` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_lifecycle_configuration` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |
| `aws_s3_bucket_ownership_controls` | v3.x | v3.x | Predates v4 refactor |
| `aws_s3_bucket_acl` | v4.0.0 | **v4.9.0** | Part of S3 bucket refactor |

**Recommended minimum**: `>= 4.9.0` -- v4.0.0 through v4.8.0 had significant breaking changes to `aws_s3_bucket`. v4.9.0 restored backward compatibility with deprecation warnings and stabilized all standalone resources. In v5.0.0, the deprecated inline parameters were fully removed from `aws_s3_bucket`.

**Practical recommendation for new modules**: `>= 5.0.0` since v5 removes all deprecated inline S3 bucket parameters, enforcing use of standalone resources. This prevents mixing inline and standalone configuration.

### Rationale
AWS naming rules are documented at `bucketnamingrules.html` and are enforced server-side. Implementing validation in Terraform catches naming errors at `plan` time rather than `apply` time, improving developer experience. Multiple validation blocks are used rather than a single complex regex for readability and clear error messages. The provider version `>= 4.9.0` is the minimum for stable standalone S3 resources, though `>= 5.0.0` is preferred for new modules since it eliminates the risk of accidentally using deprecated inline parameters.

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| Single complex regex for all rules | Poor error messages; hard to maintain and debug |
| No validation (rely on API errors) | API errors at apply time are slower feedback; bucket names are `ForceNew` so mistakes are costly |
| `bucket_prefix` instead of `bucket` | Less control over full name; still need validation on the prefix portion (max 37 chars) |
| Provider `>= 4.0.0` | v4.0.0-v4.8.0 had breaking changes to `aws_s3_bucket`; v4.9.0 stabilized the migration path |
| Provider `>= 3.x` | Standalone versioning/encryption/website resources do not exist in v3 |

### Sources
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
- Provider docs: hashicorp/aws `aws_s3_bucket` (providerDocID: 11440681)
- Provider docs: hashicorp/aws `aws_s3_bucket_versioning` (providerDocID: 11440702)
- Provider docs: hashicorp/aws `aws_s3_bucket_server_side_encryption_configuration` (providerDocID: 11440701)
- Provider docs: hashicorp/aws `aws_s3_bucket_website_configuration` (providerDocID: 11440703)
- Provider v4 Upgrade Guide: hashicorp/aws (providerDocID: 11438831) -- S3 Bucket Refactor and Changes to S3 Bucket Drift Detection sections
