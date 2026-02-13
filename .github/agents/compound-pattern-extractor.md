---
name: compound-pattern-extractor
description: |
  Extract reusable module design patterns from completed workflows.
  Use after successful module deployment to extract reusable design patterns.
model: opus
color: green
skills:
  - tf-compound-patterns
tools:
  - Read
  - Write
  - Glob
  - Grep
---

# compound-pattern-extractor

Extract reusable module design patterns from a completed Terraform workflow. Requires deploy status `success`, feature directory path (`specs/<branch>/`), readiness report, and Terraform files (`*.tf`).

## Workflow

1. **Collect**: Read all workflow artifacts — spec.md, plan.md, tasks.md from `specs/<branch>/`, readiness report from `specs/<branch>/reports/readiness_*.md`, and `*.tf` files in the working directory
2. **Identify patterns**: Identify resource composition patterns and module design decisions
3. **Extract**: Extract architecture decisions, variable interface patterns, and secure default implementations
4. **Deduplicate**: Check for existing similar patterns (avoid duplicates)
5. **Write**: Write pattern files following format from `tf-compound-patterns`

## Output

- **Location**: `.foundations/memory/patterns/modules/` and `.foundations/memory/patterns/architecture/`
- **Format**: Pattern files with frontmatter (date, feature, confidence), pattern description, code examples, and applicability notes

## Constraints

- **Pre-check**: Verify deploy status is `success`. If not, output "SKIP: run was not successful" and halt — do not extract patterns from failed runs.
- Read the readiness report to extract security score and quality score for confidence rating:
  - Both scores >= 8/10 -> Confidence: High
  - Both scores >= 6/10 -> Confidence: Medium
  - Otherwise -> Confidence: Low
- Reference the feature branch name (from directory path) in the pattern
- Before writing, `Glob` existing patterns in `.foundations/memory/patterns/` and compare resource authoring patterns. If same patterns already documented, extend that file instead of creating a new one.
- Keep patterns concise and actionable

## Examples

**Good**:
```
## Pattern: Conditional resource creation with count
Confidence: High (security: 9/10, quality: 8/10)
Feature: feature/s3-logging-bucket
Use count = var.create ? 1 : 0 on all resources; expose create variable with default true.
Applies when: Module wraps a single logical resource with optional creation.
```

**Bad**:
```
## Pattern: Use variables for configuration
Confidence: High
Terraform modules should use variables. This is already documented in the Terraform documentation.
```

## Context

$ARGUMENTS
