# Remediation Log

## Iteration 1

| Finding ID | Severity | Files Changed (ALL) | What Changed | Verified In |
|------------|----------|---------------------|--------------|-------------|
| C1 | CRITICAL | contracts/module-interfaces.md | Added `logging_target_bucket` and `logging_target_prefix` to Inputs table, Conditional Creation Logic, and Resource Dependencies | consistency-analysis.md iteration 2 |
| F1 | CRITICAL | plan.md, contracts/module-interfaces.md | Renamed bucket policy/data source from `public_read` to `this` everywhere; updated Conditional Creation Logic to show always-created (no count) for TLS enforcement | consistency-analysis.md iteration 2 |
| D1 | HIGH | spec.md (FR-003), contracts/module-interfaces.md (Locals), tasks.md (T007) | Added `ManagedBy = "terraform"` to mandatory tags per constitution 7.4 | consistency-analysis.md iteration 2 |
| F2 | HIGH | plan.md | Updated resource count from "4-8" to "7-11" reflecting ownership controls, always-present bucket policy, and optional logging | consistency-analysis.md iteration 2 |
| F3/F4 | HIGH | plan.md | Added `logging_target_bucket` and `logging_target_prefix` to optional variables list; updated variable count from 13 to 15; updated file content mapping | consistency-analysis.md iteration 2 |
| E1 | HIGH | tasks.md | Fixed coverage matrix: FR-014 now maps to T020 (website config), not T015/T016 | consistency-analysis.md iteration 2 |
| E2 | MEDIUM | tasks.md | Fixed coverage matrix: FR-009/FR-010 now map to T021 (lifecycle), not T020 | consistency-analysis.md iteration 2 |
| C2 | MEDIUM | contracts/data-model.md | Updated Bucket Policy entity to describe dual-statement structure: DenyInsecureTransport (always) + PublicReadGetObject (conditional dynamic) | consistency-analysis.md iteration 2 |
| C3 | MEDIUM | contracts/data-model.md | Added Ownership Controls, Logging Configuration entities and rows to Entity State Matrix; updated entity diagram | consistency-analysis.md iteration 2 |
| D3 | MEDIUM | contracts/module-interfaces.md | Updated Conditional Creation Logic: bucket policy and policy document show "Always created" with no count expression | consistency-analysis.md iteration 2 |
| B2 | MEDIUM | spec.md (SC-005) | Specified `trivy config .` command for security scan | consistency-analysis.md iteration 2 |
| B3 | MEDIUM | spec.md (SC-008) | Clarified "active" to mean versioning status="Enabled", lifecycle rule status="Enabled" with GLACIER transition | consistency-analysis.md iteration 2 |
| D2 | MEDIUM | spec.md (FR-028) | Documented rationale for opt-in logging: module cannot create log-destination bucket (circular dependency) | consistency-analysis.md iteration 2 |
| G1 | MEDIUM | plan.md (Resource Inventory) | Updated bucket policy and policy document entries to document dual-statement pattern (TLS + conditional public-read) | consistency-analysis.md iteration 2 |
