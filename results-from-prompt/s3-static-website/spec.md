# Feature Specification: S3 Static Website Hosting Module

**Feature Branch**: `001-s3-static-website`
**Created**: 2026-02-13
**Status**: Draft
**Input**: User description: "Terraform module for an S3 bucket configured for static website hosting with encryption, versioning, lifecycle rules, and configurable public access."

---

## Module Purpose

This module creates and manages an S3 bucket purpose-built for static website hosting. It provides a secure-by-default storage configuration with server-side encryption, versioning, and lifecycle management, while allowing consumers to optionally enable public website hosting with configurable access controls. The module supports both private (internal) and public-facing website use cases through a single, cohesive interface.

---

## Scope

### In Scope

- S3 bucket creation with configurable naming
- Server-side encryption (always on, non-negotiable)
- Object versioning (enabled by default, toggleable)
- Lifecycle rules for cost-optimized storage tiering
- Public access controls (blocked by default, configurable for website hosting)
- Static website configuration with index and error documents
- Cross-origin resource sharing (CORS) configuration
- Mandatory and custom tagging
- Force-destroy configurability for testing and teardown scenarios

### Out of Scope

- CloudFront distribution or CDN configuration (separate module responsibility)
- DNS record management (Route 53 or other DNS providers)
- SSL/TLS certificate provisioning
- Bucket policy authoring beyond what is needed for website hosting
- S3 access logging configuration beyond optional target bucket pass-through (log bucket creation and management is consumer responsibility)
- Replication configuration (cross-region or same-region)
- Object Lock or compliance retention policies
- IAM user or role creation for bucket access

### Assumptions

- Consumers provide their own provider configuration (region, credentials)
- The bucket name is globally unique and provided by the consumer
- Consumers are responsible for uploading website content after bucket creation
- When website hosting is enabled with public access, consumers understand the security implications of making bucket contents publicly readable
- The module targets a single AWS region; cross-region concerns are out of scope

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Private S3 Bucket with Encryption and Versioning (Priority: P1)

As a module consumer, I want to create a private S3 bucket with encryption and versioning enabled by default, so that my stored objects are protected at rest and I can recover from accidental deletions or overwrites without any additional configuration.

**Why this priority**: This is the foundational capability. Every use case -- whether private storage or public website -- requires a securely configured bucket. Encryption and versioning are non-negotiable security baselines per organizational policy.

**Independent Test**: Can be fully tested by running `terraform test` against `tests/basic.tftest.hcl` with only required variables (bucket_name, environment, owner, cost_center). Delivers a fully encrypted, versioned, private S3 bucket.

**Acceptance Scenarios**:

1. **Given** only the required variables are provided (bucket_name, environment, owner, cost_center), **When** the module is applied, **Then** an S3 bucket is created with server-side encryption enabled, versioning enabled, and all public access blocked.
2. **Given** default configuration, **When** the module is applied, **Then** the bucket has the required tags (Environment, Owner, CostCenter) applied automatically.
3. **Given** default configuration, **When** the module is applied, **Then** there is no way to create the bucket without encryption -- encryption is always enforced regardless of input variables.
4. **Given** `versioning_enabled = false`, **When** the module is applied, **Then** versioning is suspended on the bucket while all other secure defaults remain in effect.

---

### User Story 2 - Static Website Hosting with Public Access (Priority: P2)

As a module consumer, I want to enable static website hosting on my S3 bucket with configurable index and error documents, so that I can serve a static website directly from S3 without additional infrastructure.

**Why this priority**: Website hosting is the primary differentiator of this module compared to a generic S3 module. It requires careful handling of public access controls to balance functionality with security.

**Independent Test**: Can be tested by running `terraform test` against `tests/complete.tftest.hcl` with website hosting enabled and public access unblocked. Validates that the website endpoint is exposed and documents are correctly configured.

**Acceptance Scenarios**:

1. **Given** `enable_website = true` and `block_public_access = false`, **When** the module is applied, **Then** the bucket is configured for static website hosting with the specified index and error documents, and a website endpoint is exposed as an output.
2. **Given** `enable_website = true` and `block_public_access = true` (default), **When** the module is applied, **Then** the website configuration is created but public access remains blocked (suitable for use behind CloudFront with Origin Access Identity).
3. **Given** `enable_website = true` with custom `index_document` and `error_document` values, **When** the module is applied, **Then** the website configuration uses the consumer-specified document names.
4. **Given** `enable_website = false`, **When** the module is applied, **Then** no website configuration is created and website-related outputs return null or empty values.

---

### User Story 3 - Lifecycle Management for Cost Optimization (Priority: P3)

As a module consumer, I want objects in my bucket to automatically transition to cheaper storage tiers after a configurable period, so that I can reduce storage costs for aging content without manual intervention.

**Why this priority**: Lifecycle management is important for cost optimization but is not required for the bucket to be functional. It provides significant long-term value for production workloads.

**Independent Test**: Can be tested by verifying the lifecycle configuration is present on the bucket with the expected transition period. Does not require waiting for actual transitions to occur.

**Acceptance Scenarios**:

1. **Given** default configuration, **When** the module is applied, **Then** a lifecycle rule transitions objects to the GLACIER storage class after 90 days.
2. **Given** `lifecycle_glacier_days = 30`, **When** the module is applied, **Then** the lifecycle rule transitions objects to the GLACIER storage class after 30 days instead of the default 90.
3. **Given** `lifecycle_glacier_days = 0`, **When** the module is applied, **Then** no lifecycle transition rule is created (lifecycle management is disabled).

---

### User Story 4 - CORS Configuration for Web Applications (Priority: P4)

As a module consumer, I want to configure CORS rules on my S3 bucket, so that my web application hosted on a different domain can make cross-origin requests to assets stored in this bucket.

**Why this priority**: CORS is an optional enhancement needed only when the bucket serves assets to web applications on different origins. It is not required for basic website hosting or private storage.

**Independent Test**: Can be tested by providing a list of allowed origins and verifying the CORS configuration is applied to the bucket.

**Acceptance Scenarios**:

1. **Given** `cors_allowed_origins = ["https://example.com", "https://app.example.com"]`, **When** the module is applied, **Then** a CORS configuration is created on the bucket allowing requests from the specified origins.
2. **Given** `cors_allowed_origins = []` (default), **When** the module is applied, **Then** no CORS configuration is created on the bucket.

---

### User Story 5 - Custom Tagging and Organizational Compliance (Priority: P5)

As a module consumer, I want to provide additional custom tags that are merged with the mandatory tags, so that I can meet my team's tagging standards while the module enforces organizational minimums.

**Why this priority**: Tagging is essential for governance but does not affect the functional behavior of the bucket. The mandatory tags (Environment, Owner, CostCenter) are always applied via required variables, and custom tags supplement them.

**Independent Test**: Can be tested by providing custom tags and verifying all resources have both mandatory and custom tags applied.

**Acceptance Scenarios**:

1. **Given** `tags = { Project = "marketing-site", Team = "frontend" }`, **When** the module is applied, **Then** all created resources have the custom tags merged with the mandatory Environment, Owner, and CostCenter tags.
2. **Given** no custom tags are provided (default empty map), **When** the module is applied, **Then** all resources still have the mandatory tags applied.
3. **Given** a custom tag key conflicts with a mandatory tag key, **When** the module is applied, **Then** the mandatory tag value takes precedence to enforce organizational compliance.

---

### Edge Cases

- **Invalid bucket name**: When `bucket_name` contains characters that violate bucket naming rules (uppercase, underscores, etc.), the module must reject the input with a clear validation error before any resources are planned.
- **Invalid environment value**: When `environment` is not one of the allowed values (dev, staging, prod), the module must reject the input with a validation error.
- **Invalid owner format**: When `owner` does not appear to be an email address or a team name, the module should still accept it (no overly strict validation on format, but it must be non-empty).
- **Website enabled with public access blocked**: This is a valid configuration (for CloudFront OAI/OAC use cases). The module must create the website configuration without error, even though the bucket is not directly publicly accessible.
- **Zero lifecycle days**: When `lifecycle_glacier_days = 0`, lifecycle management is disabled entirely. No lifecycle rules are created.
- **Empty CORS origins list**: When `cors_allowed_origins` is an empty list, no CORS configuration is created. The module must not create an empty CORS rule.
- **Force destroy**: The module must support a `force_destroy` option (defaulting to false) so that consumers can destroy non-empty buckets during testing without manual object deletion.
- **All optional features disabled**: When `enable_website = false`, `versioning_enabled = false`, `lifecycle_glacier_days = 0`, and `cors_allowed_origins = []`, the module must still produce a valid, encrypted, private bucket with mandatory tags.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Bucket Creation and Core Configuration

- **FR-001**: The module MUST create an S3 bucket with a consumer-provided, globally unique name.
- **FR-002**: The module MUST support a `force_destroy` option that defaults to `false`, allowing consumers to override for testing scenarios where non-empty bucket deletion is required.
- **FR-003**: The module MUST apply mandatory tags (Environment, Owner, CostCenter, ManagedBy="terraform") derived from required input variables and module defaults to every resource it creates, in addition to any consumer-provided custom tags.
- **FR-004**: Mandatory tags MUST take precedence over consumer-provided tags when key names conflict, ensuring organizational compliance is not overridden.

#### Encryption

- **FR-005**: The module MUST enable server-side encryption using AES256 by default on all objects stored in the bucket.
- **FR-006**: Encryption MUST be enforced unconditionally -- there must be no variable or mechanism to disable encryption. This is a non-negotiable security requirement.

#### Versioning

- **FR-007**: The module MUST enable object versioning by default to protect against accidental deletion and overwrites.
- **FR-008**: The module MUST allow consumers to disable versioning via the `versioning_enabled` variable.

#### Lifecycle Management

- **FR-009**: The module MUST create a lifecycle rule that transitions objects to the GLACIER storage class after a configurable number of days (default: 90 days).
- **FR-010**: When the lifecycle transition period is set to zero, the module MUST NOT create any lifecycle rules, effectively disabling lifecycle management.

#### Public Access Controls

- **FR-011**: The module MUST block all public access to the bucket by default (block public ACLs, block public bucket policies, ignore public ACLs, restrict public bucket access).
- **FR-012**: The module MUST allow consumers to disable the public access block via the `block_public_access` variable to enable direct public website hosting.
- **FR-013**: When public access is unblocked, the module should provide clear documentation in variable descriptions about the security implications.

#### Bucket Policy for Public Website Hosting

- **FR-013a**: When both `enable_website = true` and `block_public_access = false`, the module MUST automatically create an S3 bucket policy granting public `s3:GetObject` access to all objects, enabling the website endpoint to serve content.
- **FR-013b**: When `block_public_access = true` (default) or `enable_website = false`, the module MUST NOT create a public bucket policy.

#### TLS Enforcement (Security Review Finding)

- **FR-027**: The module MUST include a bucket policy statement that denies all requests made over non-TLS (HTTP) connections by checking `aws:SecureTransport = false`. This applies unconditionally regardless of website hosting or public access settings.

#### Access Logging (Security Review Finding)

- **FR-028**: The module MUST support optional S3 server access logging via a `logging_target_bucket` variable. When provided, the module creates an `aws_s3_bucket_logging` resource pointing to the specified target bucket and optional prefix. When not provided (default: null), no logging configuration is created. *Rationale for opt-in (not opt-out): the module cannot create its own log-destination bucket (circular dependency), so a consumer-provided target is required.*

#### Bucket Ownership Controls (Security Review Finding)

- **FR-029**: The module MUST create an `aws_s3_bucket_ownership_controls` resource with `object_ownership = "BucketOwnerEnforced"` to disable ACLs and ensure the bucket owner has full ownership of all objects.

#### Website Configuration

- **FR-014**: The module MUST support static website hosting configuration with configurable index and error document names.
- **FR-015**: Website hosting MUST default to disabled (`enable_website = false`) for secure-by-default posture, and be toggleable via the `enable_website` variable.
- **FR-016**: When website hosting is disabled, website-related outputs MUST return null or empty values gracefully (no errors).
- **FR-017**: The default index document MUST be "index.html" and the default error document MUST be "error.html".

#### CORS Configuration

- **FR-018**: The module MUST support optional CORS configuration, allowing consumers to specify a list of allowed origins.
- **FR-019**: When no allowed origins are provided (empty list), the module MUST NOT create any CORS configuration.
- **FR-020**: When CORS is configured, the module SHOULD allow GET and HEAD methods at minimum for static website asset serving.

#### Input Validation

- **FR-021**: The module MUST validate that `bucket_name` is non-empty and conforms to S3 bucket naming conventions (lowercase letters, numbers, hyphens, and periods only; 3-63 characters; must start and end with alphanumeric; no consecutive periods; no IP address format; no reserved prefixes or suffixes).
- **FR-022**: The module MUST validate that `environment` is one of the allowed values: dev, staging, or prod.
- **FR-023**: The module MUST validate that `owner` and `cost_center` are non-empty strings.
- **FR-024**: The module MUST validate that `lifecycle_glacier_days` is a non-negative integer.

#### Outputs

- **FR-025**: The module MUST expose the bucket identifier, ARN, domain name, and regional domain name as outputs.
- **FR-026**: The module MUST expose the website endpoint and website domain as outputs when website hosting is enabled, and return null when it is disabled.

### Key Entities

- **Storage Bucket**: The primary storage container. Holds all objects, receives encryption and tagging configuration. Every other entity depends on this.
- **Encryption Configuration**: Attached to the bucket. Defines the server-side encryption algorithm. Always present, not toggleable.
- **Versioning Configuration**: Attached to the bucket. Controls whether object versions are maintained. Enabled by default, can be suspended.
- **Lifecycle Configuration**: Attached to the bucket. Defines rules for automatic storage tier transitions. Present only when lifecycle days > 0.
- **Public Access Block**: Attached to the bucket. Controls all four public access dimensions. Enabled by default, can be disabled for public website hosting.
- **Website Configuration**: Attached to the bucket. Defines the index and error document settings. Present only when website hosting is enabled.
- **CORS Configuration**: Attached to the bucket. Defines cross-origin access rules. Present only when allowed origins are provided.
- **Bucket Policy**: Attached to the bucket. Contains TLS enforcement (always present) and public `s3:GetObject` access grant (only when both website hosting is enabled and public access is unblocked).
- **Ownership Controls**: Attached to the bucket. Enforces BucketOwnerEnforced ownership to disable ACLs. Always present.
- **Logging Configuration**: Attached to the bucket. Directs access logs to a target bucket. Present only when logging_target_bucket is provided.

### Module Interface Summary

- **Input variables**: `bucket_name`, `environment`, `owner`, `cost_center`, `versioning_enabled`, `enable_website`, `index_document`, `error_document`, `lifecycle_glacier_days`, `block_public_access`, `cors_allowed_origins`, `force_destroy`, `tags`, `logging_target_bucket`, `logging_target_prefix`
- **Output values**: `bucket_id`, `bucket_arn`, `bucket_domain_name`, `bucket_regional_domain_name`, `website_endpoint`, `website_domain`
- **Feature flags**: `enable_website`, `versioning_enabled`, `block_public_access`

---

## Non-Functional Requirements

- **NFR-001**: The module MUST follow the standard module structure with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `locals.tf` at the root.
- **NFR-002**: The module MUST NOT contain provider configuration blocks -- consumers provide their own provider setup.
- **NFR-003**: The module MUST include two usage examples: `examples/basic/` (private encrypted bucket with defaults) and `examples/complete/` (public website hosting with CORS, custom lifecycle, and all features enabled).
- **NFR-004**: The module MUST include test files in `tests/` covering default creation, full-featured creation, feature toggles (disabled website, disabled versioning, disabled lifecycle), and input validation.
- **NFR-005**: All variable descriptions MUST be clear enough for `terraform-docs` to generate useful documentation.
- **NFR-006**: The module MUST specify minimum provider version constraints in `versions.tf`: AWS provider `>= 5.0.0` and Terraform `>= 1.3.0`.
- **NFR-007**: The bucket policy resource MUST declare an explicit dependency on the public access block resource to ensure correct ordering during apply (public access block must be relaxed before a public bucket policy can be attached).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `terraform validate` passes with no errors for the root module and all examples.
- **SC-002**: All `.tftest.hcl` test files pass via `terraform test`, covering at minimum: default configuration, website-enabled configuration, all-features-disabled configuration, and input validation rejection.
- **SC-003**: `terraform fmt -check` reports no formatting issues across all module files and examples.
- **SC-004**: Both `examples/basic/` and `examples/complete/` configurations plan successfully and demonstrate clearly distinct use cases (private vs. public website).
- **SC-005**: No CRITICAL or HIGH findings from `trivy config .` security scan of the module root. Encryption is always enabled; public access is blocked by default.
- **SC-006**: README.md (auto-generated via terraform-docs) includes all input variables, all output values, and at least one usage example.
- **SC-007**: All data stored by this module is encrypted at rest by default with no consumer-accessible toggle to disable encryption.
- **SC-008**: When deployed with default inputs (only required variables), the bucket denies all public access, has versioning status "Enabled", has a lifecycle rule with status "Enabled" transitioning to GLACIER after 90 days, website hosting is disabled, and TLS enforcement policy is active.
- **SC-009**: When deployed with website hosting and public access enabled, the module exposes a functional website endpoint in its outputs.
- **SC-010**: Invalid input values (empty bucket name, invalid environment, negative lifecycle days) are rejected at plan time with clear, actionable error messages.
