# Implementation Plan: S3 Static Website Hosting Module

**Branch**: `001-s3-static-website` | **Date**: 2026-02-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/s3-static-website/spec.md`

## Summary

This module creates an S3 bucket purpose-built for static website hosting with secure-by-default configuration. The core approach uses standalone AWS S3 resources (provider v4+ pattern) to compose a bucket with unconditional AES256 encryption, configurable versioning, conditional lifecycle tiering to GLACIER, optional website hosting with public access controls, optional CORS, and a conditional public-read bucket policy. The architecture follows the security-first principle: all public access is blocked by default and encryption cannot be disabled. Research confirms all planned resources are stable in the AWS provider and the design aligns with AWS best practices and well-regarded public registry modules.

## Technical Context

**Terraform Version**: `>= 1.3.0` (required for optional object type defaults and improved validation)
**Provider(s)**: `hashicorp/aws >= 5.0` (minimum for stable standalone S3 resources with deprecated inline params removed -- research-naming-validation.md)
**AWS Services**: S3 (bucket, encryption, versioning, lifecycle, public access block, website configuration, CORS, bucket policy)
**Testing**: `terraform test` (native HCL-based tests in `tests/` directory)
**Target Platform**: AWS commercial regions
**Module Type**: Root module (child module for consumers)
**Constraints**: No external provisioners, no local-exec, no provider blocks in root module, registry-compatible
**Scale/Scope**: Manages 7-11 resources depending on feature toggles (bucket, encryption, versioning, public access block, ownership controls, bucket policy, policy document always; lifecycle, website config, CORS, logging conditional)

## Resource Inventory

### Resources Created

| Component | Resource Type | Logical Name | Provider | Conditional | Research Ref |
|-----------|--------------|--------------|----------|-------------|-------------|
| S3 Bucket | `aws_s3_bucket` | `this` | hashicorp/aws | No | research-naming-validation.md -- Core resource, all standalone resources depend on it |
| Encryption | `aws_s3_bucket_server_side_encryption_configuration` | `this` | hashicorp/aws | No (always created) | research-lifecycle-encryption.md -- AES256 unconditional per FR-006 |
| Versioning | `aws_s3_bucket_versioning` | `this` | hashicorp/aws | No (always created, status toggleable) | research-lifecycle-encryption.md -- Status `Enabled` or `Suspended` via `var.versioning_enabled` |
| Public Access Block | `aws_s3_bucket_public_access_block` | `this` | hashicorp/aws | No (always created) | research-public-access-cors.md -- All four settings default `true`, toggled via `var.block_public_access` |
| Lifecycle | `aws_s3_bucket_lifecycle_configuration` | `this` | hashicorp/aws | Yes (`lifecycle_glacier_days > 0`) | research-lifecycle-encryption.md -- GLACIER transition after configurable days |
| Website Config | `aws_s3_bucket_website_configuration` | `this` | hashicorp/aws | Yes (`enable_website`) | research-website-config.md -- Index/error documents, exposes website endpoint |
| CORS Config | `aws_s3_bucket_cors_configuration` | `this` | hashicorp/aws | Yes (`cors_allowed_origins != []`) | research-public-access-cors.md -- GET/HEAD methods, configurable origins |
| Ownership Controls | `aws_s3_bucket_ownership_controls` | `this` | hashicorp/aws | No (always created) | security-review.md -- BucketOwnerEnforced per FR-029 |
| Logging | `aws_s3_bucket_logging` | `this` | hashicorp/aws | Yes (`logging_target_bucket != null`) | security-review.md -- Optional access logging per FR-028 |
| Bucket Policy | `aws_s3_bucket_policy` | `this` | hashicorp/aws | No (always created for TLS enforcement) | research-bucket-policy.md, security-review.md -- DenyInsecureTransport (always) + PublicReadGetObject (conditional dynamic) |
| Policy Document | `data.aws_iam_policy_document` | `this` | hashicorp/aws | No (always created) | research-bucket-policy.md -- Contains DenyInsecureTransport + conditional PublicReadGetObject |

### Data Sources

| Data Source | Logical Name | Purpose | Conditional |
|-------------|-------------|---------|-------------|
| `aws_iam_policy_document` | `this` | Generates IAM policy JSON with DenyInsecureTransport (always) and PublicReadGetObject (conditional dynamic) | No (always created) |

### Submodules

None. This module is flat -- all resources reside in the root module. The resource count (7-11) does not justify submodule decomposition.

## Architectural Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Provider minimum version | `>= 5.0` | v5.0 removed deprecated inline S3 bucket params, enforcing standalone resources. Prevents mixing inline and standalone config. research-naming-validation.md recommends `>= 5.0.0` for new modules. | `>= 4.9.0` (stable but allows deprecated inline params) |
| Encryption algorithm | AES256 (SSE-S3), no toggle | FR-006 mandates unconditional encryption. SSE-S3 avoids KMS key management overhead and cost. Compatible with direct website hosting. | `aws:kms` (requires KMS key, adds cost, incompatible with direct website endpoints) |
| Conditional resource creation | `count` meta-argument | Single-instance resources with binary on/off toggles. Simpler than `for_each` for this pattern. Matches public registry module conventions. | `for_each` (unnecessary complexity for single-instance toggles) |
| Public access control | Single `block_public_access` boolean controlling all four settings | Simpler consumer interface. All four settings move together -- partial relaxation creates confusing security posture. | Four separate boolean variables (overly granular, confusing) |
| Bucket policy approach | `data.aws_iam_policy_document` + `aws_s3_bucket_policy` | Terraform-idiomatic, type-safe, supports interpolation. Preferred over inline JSON. | Inline JSON string (less maintainable), `jsonencode()` (loses declarative structure) |
| Lifecycle storage class | GLACIER (Flexible Retrieval) | Spec explicitly requires GLACIER. Good balance of cost and retrieval time for archived website content. | INTELLIGENT_TIERING (complex), DEEP_ARCHIVE (12+ hr retrieval), GLACIER_IR (higher cost) |
| Bucket policy ordering | Explicit `depends_on` for public access block | AWS API rejects PutBucketPolicy if `block_public_policy = true`. Implicit dependency through bucket ID does not capture this cross-resource ordering. NFR-007. | No depends_on (causes apply-time errors) |
| Versioning resource | Always created, status toggleable | `aws_s3_bucket_versioning` with `Enabled`/`Suspended` status. Always present for state consistency. Lifecycle config depends_on versioning per provider docs. | Conditional creation with count (creates drift if toggled) |
| Tag precedence | Mandatory tags override consumer tags via merge order | FR-004: organizational compliance tags take precedence. `merge(var.tags, local.mandatory_tags)` ensures mandatory tags win conflicts. | Consumer tags override (violates organizational compliance) |
| CORS configuration | Conditional on non-empty origins list with sensible defaults | GET/HEAD methods, configurable origins, 3600s max_age. Created only when origins provided. | Always create CORS (unnecessary resource when not needed) |
| Bucket naming validation | Multiple validation blocks in variable | Catches errors at plan time. Multiple blocks provide clear, specific error messages. Less costly than API-time failures since bucket names are ForceNew. | Single complex regex (poor error messages), no validation (slow API feedback) |
| Module structure | Flat root module, no submodules | 4-8 resources is well within single-module scope. No logical grouping justifies submodule decomposition. | Submodules per feature (unnecessary indirection for this scope) |

## Security Controls Checklist

All security considerations identified in research are addressed:

| Security Concern | Source | Mitigation |
|-----------------|--------|------------|
| Public `s3:GetObject` only with explicit opt-in | research-bucket-policy.md | Bucket policy gated by `enable_website && !block_public_access`; both must be explicitly set |
| `block_public_policy` must be false before attaching public policy | research-bucket-policy.md | `depends_on` ensures public access block is applied first; all four settings controlled by `var.block_public_access` |
| `restrict_public_buckets` blocks anonymous access even with policy | research-public-access-cors.md | Set to `false` when `block_public_access = false`; all four settings move together |
| Encryption must be unconditional | research-lifecycle-encryption.md | No variable to disable encryption; `aws_s3_bucket_server_side_encryption_configuration` always created with AES256 |
| SSE-KMS incompatible with direct website endpoints | research-website-config.md | Module uses AES256 (SSE-S3) which is compatible with direct hosting |
| S3 website endpoints serve HTTP only | research-website-config.md | Documented in variable descriptions; CloudFront recommended for HTTPS (out of scope) |
| Org/account-level public access blocks can override bucket settings | research-public-access-cors.md | Documented in module README; consumer responsibility to ensure account-level settings permit public access if needed |
| Bucket naming validation prevents costly ForceNew errors | research-naming-validation.md | Multiple validation blocks on `bucket_name` variable enforce AWS naming rules at plan time |
| Force destroy default false for safety | constitution 4.3 | `var.force_destroy` defaults to `false`; examples may set `true` for testing |

## Constitution Check

All constitution checks pass. No exceptions.

Verified against constitution sections:

- **1.1 Module-First**: Standard module structure with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf`, `examples/`, `tests/`
- **1.2 Security-First**: Encryption always on, public access blocked by default, no credentials in module
- **3.2 File Organization**: All mandatory files planned (see Project Structure below)
- **3.3 Naming**: `this` for single primary resources, `this` for bucket policy (descriptive since it serves a specific purpose)
- **3.4 Variables**: All variables have type, description, validation where applicable; `sensitive` not needed (no secrets)
- **3.5 Module Patterns**: Conditional creation with `count`, `merge()` for tags, `try()` for conditional outputs
- **4.1 Secrets**: No credentials in module; provider inherited from consumer
- **4.2 Security Best Practices**: Encryption, access controls, logging defaults (logging out of scope per spec but noted)
- **4.3 Least Privilege**: Public access blocked by default; bucket policy grants only `s3:GetObject` when explicitly enabled
- **6.3 Testing**: Tests planned for basic, complete, feature toggles, and input validation
- **7.2 Dependencies**: Provider version `>= 5.0` with `>=` constraint per constitution

## Module Interface

Full variable and output definitions are in [contracts/module-interfaces.md](./contracts/module-interfaces.md). Variable validation rules and resource dependency wiring are also documented there.

### Input Variables (names only)

**Required**: `bucket_name`, `environment`, `owner`, `cost_center`

**Optional**: `versioning_enabled`, `enable_website`, `index_document`, `error_document`, `lifecycle_glacier_days`, `block_public_access`, `cors_allowed_origins`, `force_destroy`, `tags`, `logging_target_bucket`, `logging_target_prefix`

### Outputs (names only)

`bucket_id`, `bucket_arn`, `bucket_domain_name`, `bucket_regional_domain_name`, `website_endpoint`, `website_domain`

## Project Structure

### Documentation (this feature)

```text
specs/s3-static-website/
├── spec.md                        # Feature specification
├── plan.md                        # This file (implementation plan)
├── research/
│   ├── research-bucket-policy.md
│   ├── research-lifecycle-encryption.md
│   ├── research-naming-validation.md
│   ├── research-public-access-cors.md
│   └── research-website-config.md
├── contracts/
│   ├── data-model.md              # Entity data model
│   └── module-interfaces.md       # Module public interface (single source of truth)
└── tasks.md                       # Task breakdown (generated separately)
```

### Source Code (Terraform Module Layout)

```text
.                              # Root module
├── main.tf                    # S3 bucket + all sub-resources (encryption, versioning, lifecycle, public access block, website, CORS, bucket policy)
├── variables.tf               # Input variable declarations with validation
├── outputs.tf                 # Output value declarations with try() for conditionals
├── versions.tf                # Terraform >= 1.3.0, hashicorp/aws >= 5.0
├── locals.tf                  # Mandatory tags computation, merged tags
├── README.md                  # Auto-generated via terraform-docs
├── CHANGELOG.md               # Version history
│
├── examples/
│   ├── basic/                 # Private encrypted bucket with defaults only
│   │   ├── main.tf            # Module call with required vars only
│   │   ├── variables.tf       # bucket_name, environment, owner, cost_center
│   │   ├── outputs.tf         # Pass-through of module outputs
│   │   ├── providers.tf       # AWS provider config (region)
│   │   └── README.md
│   └── complete/              # Public website with CORS, custom lifecycle, all features
│       ├── main.tf            # Module call with all features enabled
│       ├── variables.tf       # All module variables exposed
│       ├── outputs.tf         # Pass-through of all module outputs
│       ├── providers.tf       # AWS provider config (region)
│       └── README.md
│
└── tests/
    ├── basic.tftest.hcl       # Default config: encrypted, versioned, private, no website
    └── complete.tftest.hcl    # Full config: website enabled, public access, CORS, custom lifecycle
```

### File Content Mapping

| File | Contents |
|------|----------|
| `main.tf` | `aws_s3_bucket.this`, `aws_s3_bucket_server_side_encryption_configuration.this`, `aws_s3_bucket_versioning.this`, `aws_s3_bucket_public_access_block.this`, `aws_s3_bucket_ownership_controls.this`, `aws_s3_bucket_lifecycle_configuration.this`, `aws_s3_bucket_website_configuration.this`, `aws_s3_bucket_cors_configuration.this`, `aws_s3_bucket_logging.this`, `data.aws_iam_policy_document.this`, `aws_s3_bucket_policy.this` |
| `variables.tf` | All 15 input variables with types, descriptions, defaults, and validation blocks |
| `outputs.tf` | 6 outputs with `try()` for conditional resources |
| `versions.tf` | `required_version >= 1.3.0`, `required_providers { aws >= 5.0 }` |
| `locals.tf` | `mandatory_tags` map, `all_tags` merged map |

## Testing Strategy

### Unit Tests (terraform test with mocks)

| Test File | Scope | What It Validates |
|-----------|-------|-------------------|
| `tests/basic.tftest.hcl` | Default configuration | Bucket created with encryption, versioning enabled, public access blocked, no website, lifecycle at 90 days, mandatory tags applied |
| `tests/complete.tftest.hcl` | Full-featured configuration | Website enabled, public access unblocked, bucket policy created, CORS configured, custom lifecycle days, custom tags merged |

### Specific Test Cases

**Default configuration (basic.tftest.hcl)**:
- Bucket is created with provided name
- Encryption is AES256 (always)
- Versioning status is `Enabled`
- All four public access block settings are `true`
- Lifecycle transitions to GLACIER after 90 days
- Website configuration is not created
- Website outputs are `null`
- Mandatory tags (Environment, Owner, CostCenter) are present

**Full-featured configuration (complete.tftest.hcl)**:
- Website configuration is created with custom index/error documents
- Public access block settings are all `false`
- Bucket policy grants public `s3:GetObject`
- CORS rule is configured with specified origins
- Custom lifecycle days are applied
- Website endpoint output is non-null
- Custom tags are merged with mandatory tags (mandatory wins on conflict)

**Feature toggle tests**:
- `enable_website = false`: No website config, no bucket policy, website outputs are null
- `versioning_enabled = false`: Versioning status is `Suspended`
- `lifecycle_glacier_days = 0`: No lifecycle configuration created
- `cors_allowed_origins = []`: No CORS configuration created
- `block_public_access = true` with `enable_website = true`: Website config created but no bucket policy (CloudFront OAC pattern)

**Input validation tests**:
- Empty `bucket_name` is rejected
- Bucket name with uppercase letters is rejected
- Bucket name with consecutive periods is rejected
- Bucket name formatted as IP address is rejected
- Bucket name with reserved prefix/suffix is rejected
- Invalid `environment` value is rejected
- Empty `owner` is rejected
- Empty `cost_center` is rejected
- Negative `lifecycle_glacier_days` is rejected

### Integration Tests

- Deploy `examples/basic/` to sandbox workspace -- validate bucket exists, encryption enabled, public access blocked
- Deploy `examples/complete/` to sandbox workspace -- validate website endpoint accessible, CORS headers present
- Destroy both examples and verify clean teardown (no orphaned resources)

### Pre-commit Checks

| Check | Command | When |
|-------|---------|------|
| Format | `terraform fmt -check -recursive` | Pre-commit, CI |
| Validate | `terraform validate` | Pre-commit, CI |
| Lint | `tflint` | Pre-commit, CI |
| Security | `trivy config .` | Pre-commit, CI |
| Docs | `terraform-docs` | Pre-commit, CI |
| Tests | `terraform test` | CI, pre-merge |

## Implementation Phases

### Phase 1: Core Bucket with Encryption and Versioning (P1)

**Goal**: Deliver a secure, private S3 bucket with unconditional encryption and configurable versioning.

**Resources**:
- `aws_s3_bucket.this`
- `aws_s3_bucket_server_side_encryption_configuration.this`
- `aws_s3_bucket_versioning.this`
- `aws_s3_bucket_public_access_block.this`

**Files**: `versions.tf`, `variables.tf` (required vars + `versioning_enabled`, `block_public_access`, `force_destroy`, `tags`), `locals.tf`, `main.tf` (core resources), `outputs.tf` (bucket outputs), `examples/basic/`

**Tests**: `tests/basic.tftest.hcl` -- default config, versioning toggle, mandatory tags

**Dependency**: None -- this is the foundation.

**Validates**: User Story 1 (all acceptance scenarios), User Story 5 (tagging)

### Phase 2: Website Hosting and Bucket Policy (P2)

**Goal**: Add static website configuration and conditional public-read bucket policy.

**Resources**:
- `aws_s3_bucket_website_configuration.this`
- `data.aws_iam_policy_document.this`
- `aws_s3_bucket_policy.this`

**Files**: `main.tf` (add website, policy resources), `variables.tf` (add `enable_website`, `index_document`, `error_document`), `outputs.tf` (add `website_endpoint`, `website_domain`), `examples/complete/`

**Tests**: `tests/complete.tftest.hcl` -- website enabled, public access, CloudFront OAC pattern

**Dependency**: Phase 1 (bucket and public access block must exist)

**Validates**: User Story 2 (all acceptance scenarios)

### Phase 3: Lifecycle and CORS (P3-P4)

**Goal**: Add conditional lifecycle management and optional CORS configuration.

**Resources**:
- `aws_s3_bucket_lifecycle_configuration.this`
- `aws_s3_bucket_cors_configuration.this`

**Files**: `main.tf` (add lifecycle, CORS resources), `variables.tf` (add `lifecycle_glacier_days`, `cors_allowed_origins`)

**Tests**: Add lifecycle and CORS test cases to both test files. Input validation tests for negative lifecycle days.

**Dependency**: Phase 1 (bucket must exist). Phase 2 for complete example updates.

**Validates**: User Story 3 (lifecycle), User Story 4 (CORS)

### Phase 4: Documentation and Polish

**Goal**: Generate README, verify all edge cases, finalize examples.

**Files**: `README.md` (terraform-docs), `CHANGELOG.md`, example READMEs

**Tests**: Full test suite run, pre-commit checks, trivy scan

**Dependency**: Phases 1-3 complete

**Validates**: All success criteria (SC-001 through SC-010)

## Complexity Tracking

No constitution violations to justify. The module is a flat root module with 7-11 resources, well within complexity guidelines.
