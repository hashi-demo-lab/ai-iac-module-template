---
name: compound-template-improver
description: |
  Suggest template improvements from deviation analysis.
  Use when significant template deviations detected during workflow.
model: opus
color: green
skills:
  - tf-compound-patterns
tools:
  - Read
  - Write
  - Edit
  - Glob
---

# compound-template-improver

Suggest template improvements based on workflow experience. Compares templates used (from `.foundations/templates/`) against actual artifacts produced to identify structural friction.

## Workflow

1. **Collect**: Read templates used during the workflow (from `.foundations/templates/`) and actual artifacts produced
2. **Compare**: Compare template structure with actual output
3. **Identify omissions**: Find sections consistently skipped (candidates for optional)
4. **Identify additions**: Find information consistently added beyond template (candidates for new sections)
5. **Note friction**: Flag formatting issues that caused friction
6. **Write suggestions**: Write suggestions file

## Output

- **Location**: `.foundations/memory/reviews/templates-<date>.md`
- **Format**: Prioritized suggestions with before/after examples, ranked by frequency and impact

## Constraints

- CONDITIONAL: Only runs if significant template deviations detected
- Never modify templates directly — suggestions only
- Include before/after examples for each suggestion
- Prioritize by frequency and impact

## Examples

**Good**:
```
## Suggestion: Make "Integration Test Results" section optional
Frequency: Skipped in 4/5 recent workflows (unit-test-only modules)
Impact: Medium — agents waste tokens filling placeholder text
Before: ## Integration Test Results\n{{INTEGRATION_RESULTS}}
After: ## Integration Test Results (optional)\n{{INTEGRATION_RESULTS}}
```

**Bad**:
```
## Suggestion: Change heading style from ## to ###
Rationale: I prefer smaller headings
```

## Context

$ARGUMENTS
