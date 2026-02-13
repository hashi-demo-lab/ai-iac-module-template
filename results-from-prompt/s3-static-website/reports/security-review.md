# Security Review: S3 Static Website Hosting Module

**Feature**: S3 Static Website Hosting Module
**Date**: 2026-02-13
**Reviewer**: AWS Security Advisor (automated)
**Spec**: [spec.md](../spec.md) | **Plan**: [plan.md](../plan.md)
**Status**: Complete

---

## Executive Summary

The S3 Static Website Hosting module plan demonstrates a strong security posture with encryption enabled unconditionally (AES256), public access blocked by default, and least-privilege bucket policies gated behind explicit opt-in. The plan follows AWS best practices for standalone S3 resource configuration and correctly addresses provider ordering dependencies.

However, the review identified **7 findings** across 4 security domains. There are **no Critical (P0)** findings that would block deployment. There are **2 High (P1)** findings related to missing TLS enforcement in transit and absent access logging, **3 Medium (P2)** findings covering object ownership controls, CORS wildcard headers, and HTTP-only website endpoint documentation, and **2 Low (P3)** findings related to MFA delete and bucket naming with periods.

**Recommendation**: Address P1 findings before production release. P2 findings should be resolved in the current development sprint. P3 findings can be added to backlog.

---

## Findings

### 1. No TLS Enforcement (HTTPS-Only) via Bucket Policy

**Risk Rating**: High
**Justification**: Without an `aws:SecureTransport` deny policy, the S3 bucket accepts HTTP requests to the REST API endpoint, transmitting data in cleartext. This exposes object uploads and management operations to eavesdropping and man-in-the-middle attacks. While the S3 website endpoint is HTTP-only by design, the REST API endpoint supports both HTTP and HTTPS, and best practice mandates enforcing HTTPS for all API access.
**Finding**: `plan.md` Resource Inventory (lines 23-35) and `spec.md` FR-013a/FR-013b define only a public-read `s3:GetObject` bucket policy. No bucket policy statement enforces TLS for non-website API requests. The plan does not include an `aws:SecureTransport` condition in any bucket policy statement.
**Impact**: Data in transit to/from the S3 REST API endpoint (uploads, management operations) can be intercepted. Violates AWS encryption best practices, CIS AWS Benchmark 2.1.1, and AWS Prescriptive Guidance for S3 encryption.
**Recommendation**:
1. Add a deny-HTTP bucket policy statement that is always created (not conditional) alongside the existing conditional public-read policy.
2. This policy should deny all `s3:*` actions when `aws:SecureTransport` is `false`.
3. When the public website bucket policy is active, merge both statements into a single policy document.

**Code Example**:

```hcl
# Before (vulnerable) - only public-read policy, no TLS enforcement
data "aws_iam_policy_document" "public_read" {
  count = (var.enable_website && !var.block_public_access) ? 1 : 0

  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# After (secure) - combined policy with TLS enforcement
data "aws_iam_policy_document" "this" {
  # Always enforce HTTPS on the REST API endpoint
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
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

  # Conditional public-read statement for website hosting
  dynamic "statement" {
    for_each = (var.enable_website && !var.block_public_access) ? [1] : []
    content {
      sid       = "PublicReadGetObject"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.this.arn}/*"]
      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
```

**Source**: [Protecting data in transit with encryption - Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryptionInTransit.html)
**Reference**: CIS AWS Foundations Benchmark v3.0.0 - 2.1.1 "Ensure S3 Bucket Policy is set to deny HTTP requests", AWS Prescriptive Guidance - [Encryption best practices for S3](https://docs.aws.amazon.com/prescriptive-guidance/latest/encryption-best-practices/s3.html), NIST SP 800-53 SC-8 (Transmission Confidentiality)
**Effort**: Medium (requires refactoring the bucket policy from conditional-only to always-present with a conditional statement, and updating the `depends_on` and `count` logic)

---

### 2. S3 Server Access Logging Not Included

**Risk Rating**: High
**Justification**: The spec explicitly lists "S3 access logging configuration" as out of scope. However, AWS security best practices strongly recommend enabling server access logging for all S3 buckets. Without access logs, there is no audit trail of who accessed what objects, making incident response and forensic analysis impossible. The constitution (section 4.2) states resources MUST enable logging by default, and section 7.4 states logging resources SHOULD be created by default with opt-out variables.
**Finding**: `spec.md` line 36 states access logging is out of scope. `plan.md` Security Controls Checklist (line 93) notes "logging out of scope per spec but noted." No `aws_s3_bucket_logging` resource is planned.
**Impact**: No audit trail for bucket access requests. Cannot detect unauthorized access, data exfiltration, or anomalous access patterns. Violates AWS security best practices and CIS AWS Benchmark 3.6.
**Recommendation**:
1. Add an optional `aws_s3_bucket_logging` resource with a `enable_access_logging` boolean variable defaulting to `true`.
2. Accept a `logging_target_bucket` variable for the destination bucket (required when logging is enabled).
3. If adding this to the current module scope is not feasible, document the omission as an accepted risk with a planned follow-up and add a prominent warning in the module README.

**Code Example**:

```hcl
# Before (no logging)
# No aws_s3_bucket_logging resource exists

# After (secure) - optional access logging
variable "enable_access_logging" {
  description = "Enable S3 server access logging. Recommended for audit and security monitoring."
  type        = bool
  default     = true
}

variable "logging_target_bucket" {
  description = "Name of the S3 bucket to receive access logs. Required when enable_access_logging is true."
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects in the target bucket."
  type        = string
  default     = ""
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}
```

**Source**: [Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html), [Enabling Amazon S3 server access logging](https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html)
**Reference**: CIS AWS Foundations Benchmark v3.0.0 - 3.6 "Ensure S3 bucket access logging is enabled on the S3 bucket storing CloudTrail logs", AWS Well-Architected Framework - Security Pillar (SEC04-BP02), Constitution sections 4.2 and 7.4
**Effort**: Medium (new resource, 2-3 new variables, validation that target_bucket is provided when logging enabled)

---

### 3. Missing S3 Object Ownership Controls

**Risk Rating**: Medium
**Justification**: The module plan does not include an `aws_s3_bucket_ownership_controls` resource. While S3 defaults to `BucketOwnerEnforced` (ACLs disabled) for new buckets since April 2023, explicitly setting this in Terraform makes the configuration declarative and prevents drift. AWS security best practices recommend disabling ACLs, and the explicit resource ensures the module enforces this posture regardless of changes to AWS defaults or account-level settings.
**Finding**: `plan.md` Resource Inventory (lines 23-35) does not include `aws_s3_bucket_ownership_controls`. The data model (`contracts/data-model.md`) has no entity for ownership controls.
**Impact**: Without explicit ownership controls, cross-account uploads could potentially use ACLs to retain object ownership in edge cases. The bucket may not match the module's intended security posture if AWS defaults change or if account-level settings differ.
**Recommendation**:
1. Add `aws_s3_bucket_ownership_controls` resource with `BucketOwnerEnforced` rule (always created, not conditional).
2. This aligns with the AWS best practice of disabling ACLs entirely.

**Code Example**:

```hcl
# Before (missing)
# No ownership controls resource

# After (secure)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

**Source**: [Controlling ownership of objects and disabling ACLs for your bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
**Reference**: CIS AWS Foundations Benchmark v3.0.0 - 2.1.4, AWS Security Best Practices - "Disable access control lists (ACLs)"
**Effort**: Low (single resource, no variables, no conditional logic)

---

### 4. CORS Configuration Uses Wildcard Allowed Headers

**Risk Rating**: Medium
**Justification**: The planned CORS configuration in the data model (`contracts/data-model.md` line 123) sets `allowed_headers = ["*"]`, which permits any header in preflight requests. While this is common for static websites, it reduces the security boundary by allowing potentially malicious headers through CORS preflight checks. The risk is moderate because the bucket only allows GET/HEAD methods and the impact is limited to information disclosure scenarios.
**Finding**: `contracts/data-model.md` line 123 specifies `allowed_headers = ["*"]` as a hardcoded default for the CORS rule.
**Impact**: Overly permissive CORS headers could be leveraged in conjunction with other vulnerabilities to facilitate cross-origin attacks. Reduces defense-in-depth posture.
**Recommendation**:
1. Make `cors_allowed_headers` a configurable variable with a sensible default such as `["Content-Type", "Authorization"]` instead of a wildcard.
2. If wildcard is retained for simplicity, document the security implications in the variable description.

**Code Example**:

```hcl
# Before (overly permissive)
cors_rule {
  allowed_headers = ["*"]
  allowed_methods = ["GET", "HEAD"]
  allowed_origins = var.cors_allowed_origins
  expose_headers  = ["ETag"]
  max_age_seconds = 3600
}

# After (configurable)
variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS preflight requests. Use [\"*\"] to allow all headers (less secure). Default allows common static website headers."
  type        = list(string)
  default     = ["Content-Type", "Accept", "Origin"]
}

cors_rule {
  allowed_headers = var.cors_allowed_headers
  allowed_methods = ["GET", "HEAD"]
  allowed_origins = var.cors_allowed_origins
  expose_headers  = ["ETag"]
  max_age_seconds = 3600
}
```

**Source**: [CORS configuration - Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManageCorsUsing.html)
**Reference**: OWASP Cross-Origin Resource Sharing (CORS) guidance, AWS S3 CORS documentation
**Effort**: Low (add one variable, update CORS block)

---

### 5. HTTP-Only Website Endpoint Requires Prominent Security Documentation

**Risk Rating**: Medium
**Justification**: The S3 website endpoint serves content over HTTP only and does not support HTTPS. While the plan and research acknowledge this (research-website-config.md line 28, plan.md line 75), the module interface does not make this limitation sufficiently visible to consumers. Users who enable public website hosting without understanding this limitation may serve sensitive content over an unencrypted channel. AWS documentation explicitly states that S3 website endpoints do not support HTTPS.
**Finding**: `contracts/module-interfaces.md` line 37 mentions "HTTP only; use CloudFront for HTTPS" in the `website_endpoint` output description. However, the `enable_website` variable description and `block_public_access` variable description do not prominently warn about HTTP-only serving.
**Impact**: Consumers may unknowingly serve website content over unencrypted HTTP, exposing users to eavesdropping and content manipulation attacks. This is especially concerning if the website includes forms, authentication flows, or personalized content.
**Recommendation**:
1. Add explicit warnings in the `enable_website` variable description about HTTP-only access.
2. Add a prominent note in the module README about the HTTPS limitation.
3. Consider adding a Terraform output or variable description that recommends CloudFront for production use.

**Code Example**:

```hcl
# Before (insufficient warning)
variable "enable_website" {
  description = "Enable static website hosting configuration on the bucket."
  type        = bool
  default     = false
}

# After (clear security guidance)
variable "enable_website" {
  description = <<-EOT
    Enable static website hosting configuration on the bucket.
    WARNING: S3 website endpoints serve content over HTTP only and do not support HTTPS.
    For production websites requiring HTTPS, use Amazon CloudFront with Origin Access
    Control (OAC) in front of this bucket. See AWS documentation:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html
  EOT
  type        = bool
  default     = false
}
```

**Source**: [Website endpoints - Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html)
**Reference**: OWASP A02:2021 - Cryptographic Failures, NIST SP 800-53 SC-8 (Transmission Confidentiality)
**Effort**: Low (documentation-only change to variable descriptions and README)

---

### 6. MFA Delete Not Addressed for Versioned Buckets

**Risk Rating**: Low
**Justification**: The module enables versioning by default but does not provide an option for MFA Delete, which requires multi-factor authentication to delete object versions or change the versioning state of a bucket. For a static website module, the risk is lower because the content is typically non-sensitive and replaceable. However, for production use cases where versioning serves as a data protection mechanism, MFA Delete adds a valuable layer of protection.
**Finding**: `plan.md` and `contracts/module-interfaces.md` define versioning configuration but do not reference MFA Delete. No `mfa_delete` attribute is planned.
**Impact**: Without MFA Delete, any principal with `s3:PutBucketVersioning` permissions can suspend versioning or delete object versions, potentially destroying the version history that protects against accidental or malicious deletion.
**Recommendation**:
1. Document in the README that MFA Delete is not managed by this module and should be configured separately for high-security use cases.
2. Optionally, add `mfa_delete` support as a future enhancement (note: MFA Delete can only be enabled by the root account via the AWS CLI, not via standard API calls, making Terraform management complex).

**Code Example**:

```hcl
# No code change required for initial release.
# Add documentation note in README:
# > **Note**: This module does not manage MFA Delete. For buckets storing
# > critical data, consider enabling MFA Delete via the AWS CLI using
# > the root account. See: https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html
```

**Source**: [Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
**Reference**: CIS AWS Foundations Benchmark v3.0.0 - 2.1.3 "Ensure MFA Delete is enabled on S3 buckets", AWS Well-Architected Framework - Security Pillar
**Effort**: Low (documentation only; full implementation is complex due to root-account requirement)

---

### 7. Bucket Naming Allows Periods Which Breaks Virtual-Host HTTPS

**Risk Rating**: Low
**Justification**: The planned bucket name validation (research-naming-validation.md lines 20-54, contracts/module-interfaces.md lines 44-49) allows periods in bucket names per AWS general naming rules. However, periods in bucket names prevent the use of virtual-host-style HTTPS URLs because the SSL certificate for `*.s3.amazonaws.com` does not cover subdomains with periods (e.g., `my.bucket.s3.amazonaws.com`). For a static website module where HTTPS via CloudFront is a recommended pattern, this creates friction.
**Finding**: `contracts/module-interfaces.md` line 45 validation allows periods in the regex pattern `^[a-z0-9][a-z0-9.-]*[a-z0-9]$`. Research file `research-naming-validation.md` lines 57-63 notes this concern and provides an optional validation but does not include it in the plan.
**Impact**: Consumers who create buckets with periods will encounter SSL certificate validation errors when using virtual-host-style HTTPS URLs or when configuring CloudFront with the bucket's default domain name.
**Recommendation**:
1. Add a variable `allow_periods_in_name` defaulting to `false` with a validation that rejects periods unless explicitly allowed.
2. Alternatively, add a note in the `bucket_name` variable description warning about HTTPS compatibility issues with periods.

**Code Example**:

```hcl
# Before (allows periods)
variable "bucket_name" {
  # ... existing validations ...
}

# After (warns about periods)
variable "bucket_name" {
  description = <<-EOT
    Name of the S3 bucket. Must comply with AWS S3 bucket naming rules.
    NOTE: Avoid periods in bucket names for HTTPS compatibility with
    virtual-host-style URLs and CloudFront integration.
  EOT
  type = string

  # ... existing validations ...

  # Optional: reject periods by default
  validation {
    condition     = var.allow_periods_in_name || !can(regex("\\.", var.bucket_name))
    error_message = "Bucket name contains periods which break virtual-host HTTPS. Set allow_periods_in_name = true to override."
  }
}
```

**Source**: [Bucket naming rules - Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
**Reference**: AWS S3 Best Practices - "Avoid using periods in bucket names for all new buckets"
**Effort**: Low (add validation or documentation)

---

## Compliance Matrix

| Control | Standard | Status | Finding |
|---------|----------|--------|---------|
| Encryption at rest (SSE-S3 AES256) | CIS 2.1.1, NIST SC-28 | **PASS** | Unconditional encryption, no toggle |
| Block public access by default | CIS 2.1.2, AWS Best Practices | **PASS** | All four settings default to `true` |
| Enforce HTTPS (TLS) for API access | CIS 2.1.1, NIST SC-8 | **FAIL** | Finding #1 - No `aws:SecureTransport` policy |
| Server access logging | CIS 3.6, AWS Well-Architected SEC04 | **FAIL** | Finding #2 - Logging out of scope |
| Disable ACLs (Object Ownership) | CIS 2.1.4, AWS Best Practices | **WARN** | Finding #3 - Missing explicit resource |
| Least-privilege bucket policy | CIS 1.16, NIST AC-6 | **PASS** | `s3:GetObject` only, gated by dual opt-in |
| No hardcoded credentials | CIS 1.12-1.14, OWASP A07 | **PASS** | Module inherits provider, no credentials |
| Versioning enabled by default | AWS Best Practices | **PASS** | Enabled by default, toggleable |
| Force destroy defaults to false | Constitution 4.3 | **PASS** | `force_destroy` defaults to `false` |
| Input validation | AWS Best Practices | **PASS** | Comprehensive bucket name and variable validation |
| Tag enforcement | Organizational policy | **PASS** | Mandatory tags override consumer tags |
| CORS least privilege | OWASP CORS guidance | **WARN** | Finding #4 - Wildcard headers |
| HTTPS for website content | NIST SC-8, OWASP A02 | **INFO** | Finding #5 - HTTP-only by S3 design, documented |
| MFA Delete | CIS 2.1.3 | **INFO** | Finding #6 - Not in scope, documented |
| Dependency ordering (NFR-007) | Provider best practices | **PASS** | Explicit `depends_on` for public access block |

---

## Spec Impact Summary

| Finding | Spec Change Needed | Suggested FR ID |
|---------|--------------------|-----------------|
| #1 No TLS enforcement | Yes - Add requirement for `aws:SecureTransport` deny policy on all buckets | FR-027 |
| #2 No access logging | Yes - Add optional access logging with secure default (enabled) | FR-028 |
| #3 Missing ownership controls | Yes - Add requirement for explicit `BucketOwnerEnforced` ownership | FR-029 |
| #4 CORS wildcard headers | Minor - Make `cors_allowed_headers` configurable | FR-030 |
| #5 HTTP-only documentation | No spec change - Documentation enhancement only | N/A |
| #6 MFA Delete | No spec change - Document as out of scope with rationale | N/A |
| #7 Periods in bucket names | No spec change - Documentation enhancement to variable description | N/A |
