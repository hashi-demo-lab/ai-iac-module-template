# Module Template Transition - Task Tracker

## Phase 0 - Foundation Layer

| # | Area | File | Status |
|---|------|------|--------|
| 0.1 | Constitution | `.foundations/memory/constitution.md` | DONE |
| 0.2 | AGENTS.md | `AGENTS.md` | DONE |
| 0.3 | CLAUDE.md | `.claude/CLAUDE.md` | DONE |

## Phase 1 - Module Scaffold

| # | Area | File(s) | Status |
|---|------|---------|--------|
| 1.1 | Root TF files | `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `providers.tf`, `terraform.tf` | DONE |
| 1.2 | New directories | `examples/basic/`, `examples/complete/`, `tests/`, `modules/` | DONE |
| 1.3 | Pre-commit | `.pre-commit-config.yaml`, `.tflint.hcl` | BLOCKED (permission denied on dotfiles) |
| 1.4 | Documentation | `README.md`, `quickstart.md` | DONE |

## Phase 2 - Core Skills

| # | Area | File | Status |
|---|------|------|--------|
| 2.1 | Implementation patterns | `.claude/skills/tf-implementation-patterns/SKILL.md` | DONE |
| 2.2 | Architecture patterns | `.claude/skills/tf-architecture-patterns/SKILL.md` | DONE |
| 2.3 | Research heuristics | `.claude/skills/tf-research-heuristics/SKILL.md` | DONE |
| 2.4 | Task patterns | `.claude/skills/tf-task-patterns/SKILL.md` | DONE |
| 2.5 | Judge criteria | `.claude/skills/tf-judge-criteria/SKILL.md` | DONE |
| 2.6 | Spec writing | `.claude/skills/tf-spec-writing/SKILL.md` | DONE |
| 2.7 | Style guide | `.claude/skills/terraform-style-guide/SKILL.md` | DONE |
| 2.8 | Security baselines | `.claude/skills/tf-security-baselines/SKILL.md` | DONE |
| 2.9 | Terraform test | `.claude/skills/terraform-test/SKILL.md` | DONE (already module-aligned) |
| 2.10 | Orchestrators | `tf-plan/`, `tf-implement/`, `tf-e2e-tester/` SKILL.md files | DONE |

## Phase 3 - Core Agents

| # | Area | File | Status |
|---|------|------|--------|
| 3.1 | Task executor | `.claude/agents/tf-task-executor.md` | DONE |
| 3.2 | Deployer → Module tester | `.claude/agents/tf-deployer.md` | DONE |
| 3.3 | Research | `.claude/agents/sdd-research.md` | DONE |
| 3.4 | Plan draft | `.claude/agents/sdd-plan-draft.md` | DONE |
| 3.5 | Specify | `.claude/agents/sdd-specify.md` | DONE |
| 3.6 | Quality judge | `.claude/agents/code-quality-judge.md` | DONE |

## Phase 4 - Supporting Agents

| # | Area | File | Status |
|---|------|------|--------|
| 4.1 | Clarify | `.claude/agents/sdd-clarify.md` | DONE |
| 4.2 | Checklist | `.claude/agents/sdd-checklist.md` | DONE |
| 4.3 | Analyze | `.claude/agents/sdd-analyze.md` | DONE |
| 4.4 | Tasks | `.claude/agents/sdd-tasks.md` | DONE |
| 4.5 | Security advisor | `.claude/agents/aws-security-advisor.md` | DONE |
| 4.6 | Report generator | `.claude/agents/tf-report-generator.md` | DONE |
| 4.7 | Compound agents | `compound-*.md` (5 files) | DONE |

## Phase 5 - Templates & Issue Templates

| # | Area | File(s) | Status |
|---|------|---------|--------|
| 5.1 | Spec template | `.foundations/templates/spec-template.md` | DONE |
| 5.2 | Plan template | `.foundations/templates/plan-template.md` | DONE |
| 5.3 | Tasks template | `.foundations/templates/tasks-template.md` | DONE |
| 5.4 | Contracts template | `.foundations/templates/contracts-template.md` | DONE |
| 5.5 | Report templates | `deployment-report-template.md`, `code-quality-evaluation-report.md` | DONE |
| 5.6 | Meta templates | `agent-definition-template.md`, `skill-definition-template.md`, `checklist-template.md` | DONE (no changes needed) |
| 5.7 | Issue templates | `.github/ISSUE_TEMPLATE/` | DONE |

## Phase 6 - GitHub Agents Sync & CI/CD

| # | Area | File(s) | Status |
|---|------|---------|--------|
| 6.1 | GitHub agents | `.github/agents/` (17 files) | DONE |
| 6.2 | CI workflows | `.github/workflows/` | DONE |

## Phase 7 - Validation & Cleanup

| # | Area | What to Do | Status |
|---|------|------------|--------|
| 7.1 | Consumer pattern grep | Search for consumer patterns - all should be zero | DONE (all references are in appropriate module-authoring context) |
| 7.2 | E2E smoke test | Run `/tf-plan` with module dev prompt | SKIPPED (requires live TFE_TOKEN + AWS creds) |
| 7.3 | File cleanup | Remove/relocate consumer artifacts from root | DONE (removed override.tf, sandbox.auto.tfvars, sandbox.auto.tfvars.example) |
