# Tasks: S3 Static Website Hosting Module

**Input**: Design documents from `/specs/s3-static-website/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), contracts/module-interfaces.md, contracts/data-model.md, reports/security-review.md
**Tests**: Tests are MANDATORY for all module features. Every user story must have corresponding `.tftest.hcl` test files that validate the module's behavior.
**Organization**: Tasks are grouped into phases: Setup, Foundational, User Stories (priority order P1-P5), Testing, and Polish. Each phase is an independently testable increment.

## Format: `[ID] [Story] Description`

- **[Story]**: Which user story this task belongs to (e.g., US1, US2). Only present in user story phases.
- All tasks execute **sequentially** in ID order (Terraform state prevents safe parallel execution)
- Include exact file paths in descriptions
- Variable names, types, defaults, and output definitions reference `contracts/module-interfaces.md` as the authoritative source

## Path Conventions

- **Root module**: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf` at repository root
- **Examples**: `examples/basic/`, `examples/complete/`
- **Tests**: `tests/*.tftest.hcl`
- Paths shown below assume standard Terraform module layout per plan.md

---

## Requirements Coverage Matrix

| Requirement | Task(s) | Description |
|-------------|---------|-------------|
| FR-001 (Bucket creation) | T005, T008 | S3 bucket with consumer-provided name |
| FR-002 (Force destroy) | T006, T008 | Configurable force_destroy defaulting to false |
| FR-003 (Mandatory tags) | T007, T009 | Environment, Owner, CostCenter tags on all resources |
| FR-004 (Tag precedence) | T007, T009 | Mandatory tags override consumer tags via merge order |
| FR-005 (AES256 encryption) | T010 | SSE-S3 encryption configuration always created |
| FR-006 (Unconditional encryption) | T010 | No variable to disable encryption |
| FR-007 (Versioning default on) | T011 | Versioning enabled by default |
| FR-008 (Versioning toggle) | T011 | var.versioning_enabled controls Enabled/Suspended |
| FR-009 (Lifecycle GLACIER) | T021 | Transition to GLACIER after configurable days |
| FR-010 (Lifecycle zero disables) | T021 | count = 0 when lifecycle_glacier_days = 0 |
| FR-011 (Block public access default) | T012 | All four public access block settings default true |
| FR-012 (Unblock public access) | T012 | var.block_public_access toggle |
| FR-013 (Public access documentation) | T015 | Security warning in variable descriptions |
| FR-013a (Public bucket policy) | T016, T017 | Auto-create public-read policy when website + public |
| FR-013b (No policy when blocked) | T016, T017 | Conditional creation gated by dual opt-in |
| FR-014 (Website config) | T020 | Index and error document configuration via aws_s3_bucket_website_configuration |
| FR-015 (Website default off) | T015 | enable_website defaults to false |
| FR-016 (Null website outputs) | T018 | try() for conditional website outputs |
| FR-017 (Default documents) | T015 | index.html and error.html defaults |
| FR-018 (CORS support) | T022 | Optional CORS configuration |
| FR-019 (Empty CORS = no resource) | T022 | count = 0 when cors_allowed_origins is empty |
| FR-020 (CORS GET/HEAD) | T022 | GET and HEAD methods for static content |
| FR-021 (Bucket name validation) | T006 | Multiple validation blocks per module-interfaces.md |
| FR-022 (Environment validation) | T006 | contains(["dev", "staging", "prod"]) |
| FR-023 (Owner/cost_center validation) | T006 | Non-empty string validation |
| FR-024 (Lifecycle days validation) | T006 | Non-negative integer validation |
| FR-025 (Core outputs) | T009 | bucket_id, bucket_arn, domain names |
| FR-026 (Website outputs) | T018 | website_endpoint, website_domain with try() |
| FR-027 (TLS enforcement) | T013 | Deny non-TLS requests via bucket policy always |
| FR-028 (Access logging) | T014 | Optional aws_s3_bucket_logging resource |
| FR-029 (Ownership controls) | T010 | BucketOwnerEnforced ownership controls |
| NFR-001 (Standard structure) | T001-T004 | main.tf, variables.tf, outputs.tf, versions.tf, locals.tf |
| NFR-002 (No provider blocks) | T003 | Provider config only in examples |
| NFR-003 (Two examples) | T019, T026 | examples/basic/ and examples/complete/ |
| NFR-004 (Test files) | T028-T033 | Tests covering defaults, full features, toggles, validation |
| NFR-005 (Clear descriptions) | T006, T015, T022 | terraform-docs-ready descriptions |
| NFR-006 (Version constraints) | T003 | Terraform >= 1.3.0, AWS >= 5.0 |
| NFR-007 (Policy depends_on) | T017 | Explicit depends_on for public access block ordering |
| SC-001 through SC-010 | T028-T036 | Success criteria validated via test suite |

---

## Phase 1: Setup (Module Scaffold)

**Goal**: Create the standard Terraform module file structure with all required files

**Independent Test**: All files exist; `terraform fmt -check` passes on empty files

- [x] T001 Create root module files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf` at `/`
- [x] T002 Create example directory structures: `/examples/basic/` and `/examples/complete/` with `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf` in each
- [x] T003 Configure `/versions.tf` with `required_version = ">= 1.3.0"` and `required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }` per NFR-006
- [x] T004 Create test file scaffolds: `/tests/basic.tftest.hcl` and `/tests/complete.tftest.hcl`

**Checkpoint**: Module scaffold complete -- all files exist, `terraform fmt -check` passes

---

## Phase 2: Foundational (Core Infrastructure)

**Goal**: Establish the core S3 bucket, mandatory variables, locals for tag computation, and core outputs that all user stories depend on

**Independent Test**: `terraform validate` passes; `terraform plan` shows `aws_s3_bucket.this` resource

**CRITICAL**: No user story work can begin until these foundational resources are in place

- [x] T005 Implement `aws_s3_bucket.this` resource in `/main.tf` with `bucket = var.bucket_name`, `force_destroy = var.force_destroy`, and `tags = local.all_tags`
- [x] T006 Define all input variables with types, descriptions, defaults, and validation blocks in `/variables.tf` per contracts/module-interfaces.md (bucket_name, environment, owner, cost_center, versioning_enabled, enable_website, index_document, error_document, lifecycle_glacier_days, block_public_access, cors_allowed_origins, force_destroy, tags, logging_target_bucket, logging_target_prefix)
- [x] T007 Create `/locals.tf` with `mandatory_tags` (Environment, Owner, CostCenter, ManagedBy="terraform") and `all_tags` using `merge(var.tags, local.mandatory_tags)` to ensure mandatory tags take precedence per FR-004 and constitution 7.4
- [x] T008 Wire `aws_s3_bucket.this` resource to reference `var.bucket_name`, `var.force_destroy`, and `local.all_tags` in `/main.tf`
- [x] T009 Define core outputs in `/outputs.tf`: `bucket_id`, `bucket_arn`, `bucket_domain_name`, `bucket_regional_domain_name` sourced from `aws_s3_bucket.this` per contracts/module-interfaces.md Resource-to-Output Mapping

**Checkpoint**: Core bucket resource defined -- `terraform validate` passes, plan shows 1 resource

---

## Phase 3: User Story 1 - Secure Private S3 Bucket with Encryption and Versioning (Priority: P1)

**Goal**: Deliver a private S3 bucket with unconditional AES256 encryption, configurable versioning, public access block, ownership controls, TLS enforcement policy, and optional access logging

**Independent Test**: Run `terraform test -filter=tests/basic.tftest.hcl` to validate encrypted, versioned, private bucket with mandatory tags

**Dependency**: Requires Phase 2 foundational bucket resource

### Implementation for User Story 1

- [x] T010 [US1] Implement `aws_s3_bucket_server_side_encryption_configuration.this` (always created, AES256 hardcoded per FR-006) and `aws_s3_bucket_ownership_controls.this` (always created, BucketOwnerEnforced per FR-029) in `/main.tf`
- [x] T011 [US1] Implement `aws_s3_bucket_versioning.this` (always created, status = `var.versioning_enabled ? "Enabled" : "Suspended"` per FR-007/FR-008) in `/main.tf`
- [x] T012 [US1] Implement `aws_s3_bucket_public_access_block.this` (always created, all four settings = `var.block_public_access` per FR-011/FR-012) in `/main.tf`
- [x] T013 [US1] Implement `data.aws_iam_policy_document.this` with unconditional DenyInsecureTransport statement (`aws:SecureTransport = false` deny per FR-027) and conditional PublicReadGetObject dynamic statement (gated by `var.enable_website && !var.block_public_access`) in `/main.tf`
- [x] T014 [US1] Implement `aws_s3_bucket_logging.this` with `count = var.logging_target_bucket != null ? 1 : 0` referencing var.logging_target_bucket and var.logging_target_prefix per FR-028 in `/main.tf`
- [x] T015 [US1] Add HTTP-only security warnings to `enable_website` and `block_public_access` variable descriptions in `/variables.tf` per security review finding #5
- [x] T016 [US1] Implement `aws_s3_bucket_policy.this` (always created since TLS enforcement is unconditional) referencing `data.aws_iam_policy_document.this.json` with `depends_on = [aws_s3_bucket_public_access_block.this]` per NFR-007 in `/main.tf`
- [x] T017 [US1] Wire bucket policy dependency: ensure `aws_s3_bucket_policy.this` has explicit `depends_on` on `aws_s3_bucket_public_access_block.this` to enforce correct apply ordering in `/main.tf`
- [x] T018 [US1] Add conditional website outputs in `/outputs.tf`: `website_endpoint` and `website_domain` using `try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null)` per FR-016/FR-026
- [x] T019 [US1] Create `/examples/basic/main.tf` with module invocation using only required variables (bucket_name, environment, owner, cost_center), `/examples/basic/variables.tf` with those variables, `/examples/basic/outputs.tf` passing through module outputs, and `/examples/basic/providers.tf` with AWS provider configuration

**Checkpoint**: Private encrypted bucket with versioning, TLS enforcement, ownership controls -- `terraform validate` passes, plan shows 6-7 resources (bucket, encryption, versioning, public access block, ownership controls, bucket policy, optionally logging)

---

## Phase 4: User Story 2 - Static Website Hosting with Public Access (Priority: P2)

**Goal**: Enable static website hosting with configurable index/error documents and conditional public-read bucket policy

**Independent Test**: Run `terraform test -filter=tests/complete.tftest.hcl` to validate website endpoint exposed, documents configured, public access unblocked

**Dependency**: Requires Phase 3 (bucket policy and public access block must exist; TLS policy document already has dynamic PublicReadGetObject statement from T013)

### Implementation for User Story 2

- [x] T020 [US2] Implement `aws_s3_bucket_website_configuration.this` with `count = var.enable_website ? 1 : 0`, `index_document { suffix = var.index_document }`, `error_document { key = var.error_document }` per FR-014/FR-015 in `/main.tf`

**Checkpoint**: Website hosting functional -- when enable_website=true, website endpoint output is non-null; when enable_website=true and block_public_access=false, public read policy statement is included in bucket policy

---

## Phase 5: User Story 3 - Lifecycle Management for Cost Optimization (Priority: P3)

**Goal**: Add conditional lifecycle rule that transitions objects to GLACIER storage class after a configurable number of days

**Independent Test**: Verify lifecycle configuration exists on bucket with expected transition period; verify count=0 when days=0

**Dependency**: Requires Phase 2 (bucket resource) and versioning resource (lifecycle depends_on versioning per provider docs)

### Implementation for User Story 3

- [x] T021 [US3] Implement `aws_s3_bucket_lifecycle_configuration.this` with `count = var.lifecycle_glacier_days > 0 ? 1 : 0`, rule id "glacier-transition", GLACIER transition after `var.lifecycle_glacier_days` days, `depends_on = [aws_s3_bucket_versioning.this]` per contracts/data-model.md in `/main.tf`

**Checkpoint**: Lifecycle management functional -- default 90-day GLACIER transition; disabled when days=0

---

## Phase 6: User Story 4 - CORS Configuration for Web Applications (Priority: P4)

**Goal**: Add optional CORS configuration with configurable allowed origins for cross-origin requests to bucket assets

**Independent Test**: Verify CORS rule created when origins provided; verify no CORS resource when origins empty

**Dependency**: Requires Phase 2 (bucket resource)

### Implementation for User Story 4

- [x] T022 [US4] Implement `aws_s3_bucket_cors_configuration.this` with `count = length(var.cors_allowed_origins) > 0 ? 1 : 0`, allowed_methods ["GET", "HEAD"], allowed_origins from var.cors_allowed_origins, allowed_headers ["*"], expose_headers ["ETag"], max_age_seconds 3600 per contracts/data-model.md in `/main.tf`

**Checkpoint**: CORS functional -- configured when origins provided, absent when empty list

---

## Phase 7: User Story 5 - Custom Tagging and Organizational Compliance (Priority: P5)

**Goal**: Ensure consumer-provided tags merge with mandatory tags, with mandatory tags taking precedence on key conflicts

**Independent Test**: Verify resources have both mandatory and custom tags; verify mandatory tag wins on conflict

**Dependency**: Already implemented in Phase 2 (T007 locals.tf) and Phase 3 (T005/T008 bucket tags). This phase validates and updates examples.

### Implementation for User Story 5

- [x] T023 [US5] Verify tag merge logic in `/locals.tf` ensures `merge(var.tags, local.mandatory_tags)` applies mandatory tags last (precedence) per FR-003/FR-004
- [x] T024 [US5] Ensure all resources in `/main.tf` that support tags reference `local.all_tags` (currently only `aws_s3_bucket.this`)

**Checkpoint**: Tagging compliance verified -- mandatory tags always present and take precedence

---

## Phase 8: Testing

**Goal**: Validate module behavior with unit and integration tests using terraform test

**Independent Test**: Run `terraform test` and confirm all assertions pass

**Dependency**: Requires all user story phases (3-7) to be complete

### Unit Tests

- [x] T025 [TEST] Write unit test for default configuration (required vars only) in `/tests/basic.tftest.hcl`: assert bucket created, encryption AES256, versioning Enabled, all public access block settings true, lifecycle at 90 days, no website config, website outputs null, mandatory tags present, ownership controls BucketOwnerEnforced, bucket policy contains DenyInsecureTransport
- [x] T026 [TEST] Write unit test for full-featured configuration in `/tests/complete.tftest.hcl`: assert website config created with custom documents, public access block all false, bucket policy contains PublicReadGetObject and DenyInsecureTransport, CORS configured with specified origins, custom lifecycle days applied, website endpoint not null, custom tags merged with mandatory tags (mandatory wins)
- [x] T027 [TEST] Write feature toggle tests in `/tests/basic.tftest.hcl`: versioning_enabled=false yields Suspended; lifecycle_glacier_days=0 yields no lifecycle config; enable_website=true with block_public_access=true yields website config but no PublicReadGetObject statement (CloudFront OAC pattern); cors_allowed_origins=[] yields no CORS config
- [x] T028 [TEST] Write input validation tests in `/tests/basic.tftest.hcl`: empty bucket_name rejected, uppercase bucket_name rejected, consecutive periods rejected, IP-address-format rejected, reserved prefix rejected, reserved suffix rejected, invalid environment rejected, empty owner rejected, empty cost_center rejected, negative lifecycle_glacier_days rejected

### Example Validation

- [x] T029 [TEST] Update `/examples/basic/main.tf` to demonstrate private encrypted bucket with defaults only (required vars: bucket_name, environment, owner, cost_center) and ensure `terraform validate` passes in examples/basic/
- [x] T030 [TEST] Update `/examples/complete/main.tf` to demonstrate all features: enable_website=true, block_public_access=false, custom index/error documents, cors_allowed_origins with sample origins, lifecycle_glacier_days=30, custom tags, force_destroy=true; update `/examples/complete/variables.tf` and `/examples/complete/outputs.tf`; ensure `terraform validate` passes in examples/complete/

**Checkpoint**: `terraform test` passes all assertions, both examples validate successfully

---

## Phase 9: Polish

**Goal**: Final quality checks, documentation, and cross-cutting concerns

**Independent Test**: `terraform fmt -check -recursive`, `terraform validate`, `trivy config .` all pass

**Dependency**: Requires Phase 8 testing to pass

- [ ] T031 [POLISH] Run `terraform fmt -recursive` across all module files and examples to ensure consistent formatting
- [ ] T032 [POLISH] Run `terraform validate` in root module, `/examples/basic/`, and `/examples/complete/`
- [ ] T033 [POLISH] Run `trivy config .` and resolve any CRITICAL or HIGH findings per SC-005
- [ ] T034 [POLISH] Generate `/README.md` via terraform-docs with all inputs, outputs, and usage examples per SC-006
- [ ] T035 [POLISH] Create `/CHANGELOG.md` with initial v0.1.0 entry documenting all features

**Checkpoint**: Module is publication-ready -- all quality gates pass, documentation complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies -- can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 -- BLOCKS all user stories
- **Phase 3 (US1 - P1)**: Depends on Phase 2 -- core encryption, versioning, public access, TLS policy, ownership controls
- **Phase 4 (US2 - P2)**: Depends on Phase 3 -- website config uses bucket and references policy document from T013
- **Phase 5 (US3 - P3)**: Depends on Phase 2 and Phase 3 T011 (versioning resource must exist for depends_on)
- **Phase 6 (US4 - P4)**: Depends on Phase 2 -- CORS only needs bucket
- **Phase 7 (US5 - P5)**: Depends on Phase 2 -- tag logic already in locals.tf; validation phase
- **Phase 8 (Testing)**: Depends on all user story phases (3-7) complete
- **Phase 9 (Polish)**: Depends on Phase 8 testing passing

### User Story Dependencies

- **US1 (P1)**: Foundation -- no dependencies on other stories
- **US2 (P2)**: Depends on US1 (bucket policy document from T013 contains the dynamic PublicReadGetObject statement)
- **US3 (P3)**: Depends on US1 T011 (lifecycle configuration has `depends_on` on versioning resource)
- **US4 (P4)**: Independent of other stories (only needs bucket from Phase 2)
- **US5 (P5)**: Independent -- validates tag logic established in Phase 2

### Cross-Resource Data Flow

| Source Resource | Output Attribute | Target Resource | Input Reference |
|----------------|-----------------|-----------------|-----------------|
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_server_side_encryption_configuration.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_versioning.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_public_access_block.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_ownership_controls.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_lifecycle_configuration.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_website_configuration.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_cors_configuration.this` | `bucket` |
| `aws_s3_bucket.this` | `id` | `aws_s3_bucket_logging.this` | `bucket` |
| `aws_s3_bucket.this` | `id`, `arn` | `data.aws_iam_policy_document.this` | `resources` (arn, arn/*) |
| `data.aws_iam_policy_document.this` | `json` | `aws_s3_bucket_policy.this` | `policy` |
| `aws_s3_bucket_public_access_block.this` | (ordering) | `aws_s3_bucket_policy.this` | `depends_on` (NFR-007) |
| `aws_s3_bucket_versioning.this` | (ordering) | `aws_s3_bucket_lifecycle_configuration.this` | `depends_on` (provider requirement) |

---

## Implementation Notes

MVP-first approach: Phase 3 (US1) delivers a fully functional, secure private bucket. Each subsequent phase adds capability without breaking previous functionality. The bucket policy is always created (TLS enforcement is unconditional per FR-027); the public-read statement is conditionally included via a dynamic block when website hosting with public access is enabled.

---

**Total Tasks**: 35
