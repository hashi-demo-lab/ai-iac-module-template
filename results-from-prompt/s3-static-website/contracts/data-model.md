# Data Model: S3 Static Website Hosting Module

**Feature**: S3 Static Website Hosting Module
**Date**: 2026-02-13
**Source**: Derived from spec.md Key Entities and research findings

## Entity Relationship Overview

All entities are attached to the Storage Bucket (1:1 relationship). The bucket is the root entity; all others are satellite configurations that modify its behavior.

```
                    +-------------------+
                    | Storage Bucket    |
                    | (aws_s3_bucket)   |
                    +--------+----------+
                             |
    +--------+-------+-------+-------+--------+--------+
    |        |       |       |       |        |        |
    v        v       v       v       v        v        v
 +------+ +-----+ +-----+ +-----+ +------+ +------+ +------+
 |Encryp-| |Vers-| |Pub  | |Owner| |Life- | |Web-  | |Log-  |
 |tion   | |ioning| |Acc  | |ship | |cycle | |site  | |ging  |
 |(always)| |Config| |Block| |Ctrl | |Config| |Config| |Config|
 +------+ +-----+ +-----+ +-----+ +------+ +------+ +------+
                                                |
                              +---------+  +----+----+
                              | CORS    |  | Bucket  |
                              | Config  |  | Policy  |
                              +---------+  |(always) |
                                           +---------+
```

## Entities

### Storage Bucket

The primary storage container. All other entities depend on this.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `id` | string | `aws_s3_bucket.this.id` | Bucket name, globally unique |
| `arn` | string | `aws_s3_bucket.this.arn` | Amazon Resource Name |
| `bucket_domain_name` | string | `aws_s3_bucket.this.bucket_domain_name` | e.g., `bucket.s3.amazonaws.com` |
| `bucket_regional_domain_name` | string | `aws_s3_bucket.this.bucket_regional_domain_name` | e.g., `bucket.s3.us-east-1.amazonaws.com` |
| `force_destroy` | bool | `var.force_destroy` | Allows non-empty bucket deletion |
| `tags` | map(string) | `local.all_tags` | Merged mandatory + consumer tags |

**Lifecycle**: Created on first apply. Destroyed on `terraform destroy` (requires `force_destroy = true` if non-empty).

### Encryption Configuration

Defines server-side encryption. Always present, not toggleable.

| Attribute | Type | Value | Notes |
|-----------|------|-------|-------|
| `sse_algorithm` | string | `"AES256"` | SSE-S3 encryption, hardcoded |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Created with bucket. Cannot be disabled (FR-006). Destroying this resource resets to AWS default encryption (still SSE-S3).

### Versioning Configuration

Controls object version retention. Always present, status toggleable.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `status` | string | `var.versioning_enabled ? "Enabled" : "Suspended"` | Enabled by default |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Always created. Status toggleable between `Enabled` and `Suspended`. Note: once enabled, versioning cannot be fully removed -- only suspended.

### Public Access Block

Controls all four public access dimensions. Always present, settings toggleable.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `block_public_acls` | bool | `var.block_public_access` | Default: true |
| `block_public_policy` | bool | `var.block_public_access` | Default: true; must be false before attaching public bucket policy |
| `ignore_public_acls` | bool | `var.block_public_access` | Default: true |
| `restrict_public_buckets` | bool | `var.block_public_access` | Default: true; must be false for anonymous access |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Always created. All four settings move together via single boolean toggle. When relaxed, allows public bucket policies and anonymous access.

### Lifecycle Configuration

Defines storage tiering rules. Conditionally created.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `rule.id` | string | `"glacier-transition"` | Fixed rule identifier |
| `rule.status` | string | `"Enabled"` | Active when created |
| `rule.filter` | block | `{}` | Empty = applies to all objects |
| `rule.transition.days` | number | `var.lifecycle_glacier_days` | Default: 90 |
| `rule.transition.storage_class` | string | `"GLACIER"` | Glacier Flexible Retrieval |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Created only when `var.lifecycle_glacier_days > 0`. Not created when days = 0.
**Dependency**: `depends_on = [aws_s3_bucket_versioning.this]` per provider documentation.

### Website Configuration

Defines static website hosting settings. Conditionally created.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `index_document.suffix` | string | `var.index_document` | Default: `"index.html"` |
| `error_document.key` | string | `var.error_document` | Default: `"error.html"` |
| `website_endpoint` | string | (computed) | e.g., `bucket.s3-website-us-east-1.amazonaws.com` |
| `website_domain` | string | (computed) | Used for Route 53 alias records |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Created only when `var.enable_website = true`. Website endpoint serves HTTP only.

### CORS Configuration

Defines cross-origin resource sharing rules. Conditionally created.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `cors_rule.allowed_methods` | list(string) | `["GET", "HEAD"]` | Sufficient for static content |
| `cors_rule.allowed_origins` | list(string) | `var.cors_allowed_origins` | Consumer-specified origins |
| `cors_rule.allowed_headers` | list(string) | `["*"]` | Permissive default for simplicity |
| `cors_rule.expose_headers` | list(string) | `["ETag"]` | Cache validation header |
| `cors_rule.max_age_seconds` | number | `3600` | 1 hour preflight cache |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Created only when `length(var.cors_allowed_origins) > 0`. Not created when origins list is empty.

### Bucket Policy

Contains TLS enforcement (always present) and public read access for website hosting (conditional). Always created.

**Statement 1: DenyInsecureTransport (unconditional, always present per FR-027)**

| Attribute | Type | Value | Notes |
|-----------|------|-------|-------|
| `sid` | string | `"DenyInsecureTransport"` | Denies non-TLS requests |
| `effect` | string | `"Deny"` | Blocks access |
| `actions` | list(string) | `["s3:*"]` | All S3 actions |
| `resources` | list(string) | `["${bucket_arn}", "${bucket_arn}/*"]` | Bucket and all objects |
| `principal` | string | `"*"` | All principals |
| `condition` | block | `aws:SecureTransport = "false"` | Triggers on HTTP-only requests |

**Statement 2: PublicReadGetObject (conditional dynamic, only when `enable_website && !block_public_access`)**

| Attribute | Type | Value | Notes |
|-----------|------|-------|-------|
| `sid` | string | `"PublicReadGetObject"` | Standard AWS example SID |
| `effect` | string | `"Allow"` | Grants access |
| `actions` | list(string) | `["s3:GetObject"]` | Read-only object access |
| `resources` | list(string) | `["${bucket_arn}/*"]` | All objects in bucket |
| `principal` | string | `"*"` | Anonymous/public access |

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Always created (TLS enforcement is unconditional). The PublicReadGetObject statement is included only when `var.enable_website = true` AND `var.block_public_access = false` via a dynamic statement block.
**Dependency**: Explicit `depends_on = [aws_s3_bucket_public_access_block.this]` -- AWS API rejects PutBucketPolicy if `block_public_policy` is still true.

### Ownership Controls

Controls object ownership model. Always created.

| Attribute | Type | Value | Notes |
|-----------|------|-------|-------|
| `object_ownership` | string | `"BucketOwnerEnforced"` | Disables ACLs, bucket owner owns all objects |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Always created. Enforces BucketOwnerEnforced to disable ACLs per FR-029.

### Logging Configuration

Directs server access logs to a target bucket. Conditionally created.

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| `target_bucket` | string | `var.logging_target_bucket` | Consumer-provided log destination bucket |
| `target_prefix` | string | `var.logging_target_prefix` | Prefix for log object keys, default "" |
| `bucket` | string | `aws_s3_bucket.this.id` | Parent bucket reference |

**Lifecycle**: Created only when `var.logging_target_bucket != null`. Not created by default (opt-in, because consumer must provide a pre-existing target bucket).

## Entity State Matrix

Shows which entities exist for each configuration pattern:

| Entity | Private (default) | Website + Public | Website + Private (OAC) | Minimal (all off) |
|--------|-------------------|------------------|-------------------------|-------------------|
| Storage Bucket | Yes | Yes | Yes | Yes |
| Encryption Config | Yes | Yes | Yes | Yes |
| Versioning Config | Enabled | Enabled | Enabled | Suspended |
| Public Access Block | All true | All false | All true | All true |
| Ownership Controls | Yes | Yes | Yes | Yes |
| Lifecycle Config | Yes (90 days) | Yes (90 days) | Yes (90 days) | No (0 days) |
| Website Config | No | Yes | Yes | No |
| CORS Config | No | Depends on origins | Depends on origins | No |
| Bucket Policy | Yes (TLS only) | Yes (TLS + PublicRead) | Yes (TLS only) | Yes (TLS only) |
| Logging Config | Depends on target | Depends on target | Depends on target | Depends on target |

## Cross-Reference to Module Interface

All entity attributes that are consumer-configurable are exposed as input variables in [module-interfaces.md](./module-interfaces.md). All computed attributes that consumers need are exposed as outputs. The mapping is documented in the Resource-to-Output Mapping table in module-interfaces.md.
