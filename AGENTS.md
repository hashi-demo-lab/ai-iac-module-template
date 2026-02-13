# AI-Assisted Terraform Module Development

AI-assisted development of enterprise-ready Terraform modules via spec-driven development (SDD) with compound learning.

## Core Principles

1. **Security-First**: All decisions prioritize security. No workarounds for security requirements. Constitution MUST rules are non-negotiable.
2. **Module-First**: Author well-structured modules using raw resources with secure defaults. Follow standard module structure (`examples/`, `tests/`, `modules/`).
3. **Spec-Driven**: Requirements → Specification → Plan → Implementation → Testing. No code without a plan.
4. **MCP-First**: Use MCP tools for AWS documentation and provider docs before general knowledge. Research resource behavior before writing code.
5. **Parallel Where Safe**: Independent tasks run concurrently. MCP-dependent tasks run sequentially.
6. **Quality Gates**: CRITICAL findings block progression. Reviews use evidence-based findings with citations.

## MCP Tools Priority

1. `search_documentation` → `read_documentation` (AWS best practices and resource behavior)
2. `resolveProviderDocID` → `getProviderDocs` (provider resource docs — attributes, arguments, examples)
3. `search_modules` / `search_private_modules` (study public/private registry for design patterns and conventions)
4. `get_regional_availability` (validate resource/feature availability in target regions)

## Directory Map

| Directory | Purpose |
|-----------|---------|
| `main.tf`, `variables.tf`, `outputs.tf` | Root module — primary resource definitions |
| `examples/basic/` | Minimal usage example with provider config |
| `examples/complete/` | Full-featured usage example |
| `modules/` | Submodules (optional, for complex modules) |
| `tests/` | Terraform test files (`.tftest.hcl`) |
| `.foundations/` | Templates, memory, schemas, and scripts |
| `.foundations/memory/` | constituion |

## Prerequisites

1. GitHub CLI authenticated: `gh auth status`
2. HCP Terraform token: `$TFE_TOKEN` set (for publishing/testing)
3. MCP servers configured: terraform, aws-knowledge-mcp-server
4. Pre-commit hooks installed: `pre-commit install`

## Testing Strategy

Module testing follows a layered approach:

1. **Unit tests** (`terraform test` with mocks): Fast, no cloud access needed. Validate logic, conditional creation, variable validation.
2. **Integration tests** (`terraform test` against real providers): Deploy examples to sandbox workspace, validate real resource behavior.
3. **Pre-commit checks**: `terraform fmt`, `terraform validate`, `tflint`, `trivy`, `terraform-docs`.
```

## Operational Notes

### GitHub Enterprise Authentication

For GHE repositories:
- **Authentication**: `gh auth login --hostname <hostname>` is required. Standard `gh auth login` only authenticates against github.com.
- **Operations**: Most `gh` commands (issue, pr, repo, etc.) do NOT accept `--hostname` flag. Use `GH_HOST` environment variable instead:
  ```bash
  export GH_HOST=github.enterprise.com
  gh issue create --title "Bug report"
  # Or inline:
  GH_HOST=github.enterprise.com gh pr create --title "Feature"
  ```

### Agent Output Persistence

All agents have the Write tool and are responsible for persisting their own output artifacts. The orchestrator verifies that expected output files exist after each agent dispatch.

## Context Management

1. **NEVER call TaskOutput** to read subagent results. All agents write artifacts to disk — reading them back into the orchestrator bloats context and triggers compaction.
2. **Verify file existence with Glob** after each agent completes — do NOT read file contents into the orchestrator.
3. **Downstream agents read their own inputs from disk.** The orchestrator passes only the FEATURE path and a brief scope description via `$ARGUMENTS`.
4. **Research agents: parallel foreground Task calls** (NOT `run_in_background`). Launch ALL research agents in a single message with multiple Task tool calls, then wait for all to complete before proceeding.
5. **Minimal $ARGUMENTS**: Only pass the FEATURE path + a specific question or scope. Never inject file contents.

**Remember**: Always verify with MCP tools. Security is non-negotiable.
