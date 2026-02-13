# Quickstart: AI-Assisted Terraform Module Development

This repo uses **Claude Code** (an AI coding assistant that runs in your terminal) to plan, write, test, and publish Terraform modules through a structured, multi-phase workflow. You describe the module you want to build; the AI does the rest.

## Key Concepts

**Skills** are reusable instruction sets that tell Claude Code _how_ to do something. Think of them as playbooks. You invoke them with a `/` prefix (like `/tf-plan`).

**Agents** are specialized AI workers that each handle one job (e.g., "write the spec", "review security", "generate code"). Skills orchestrate agents — dispatching them in sequence, collecting their outputs, and deciding what to do next.

**MCP Servers** give agents access to live external data: AWS documentation, provider docs, and the Terraform registry. Agents query these in real-time rather than relying on stale knowledge.

## How the Workflow Fits Together

```
  YOU                          CLAUDE CODE                         OUTPUTS
  ───                          ──────────                          ───────

  "I need a module that   ┌─────────────────────────────────┐
   creates a VPC with     │         /tf-plan                 │
   public/private subnets │                                  │
   and flow logs"         │  1. Validate env + gather reqs   │
         │               │  2. Write spec (module interface)│──▶ spec.md
         ▼               │  3. Generate quality checklist    │──▶ checklists/
  Answer clarifying      │  4. Clarify ambiguities with you │
  questions              │  5. Research resources & patterns │──▶ research/
         │               │  6. Draft implementation plan     │──▶ plan.md
         │               │  7. Security review               │──▶ security-review.md
         │               │  8. Break plan into tasks         │──▶ tasks.md
         │               │  9. Cross-check + fix artifacts   │──▶ evaluations/
         │               └─────────────────────────────────┘
         │
         │  Review plan artifacts, then:
         │
         ▼               ┌─────────────────────────────────┐
  "/tf-implement"        │        /tf-implement             │
         │               │                                  │
         │               │  1. Validate plan artifacts exist │
         │               │  2. Execute tasks (parallel)      │──▶ *.tf, tests/, examples/
         │               │  3. terraform fmt/validate/test   │
         │               │  4. Quality review                │──▶ quality-report.md
         │               │  5. Generate readiness report     │──▶ readiness-report.md
         │               │  6. Push + create PR              │
         │               └─────────────────────────────────┘
         │
         │  Want to test the whole pipeline non-interactively?
         │
         ▼               ┌─────────────────────────────────┐
  "/tf-e2e-tester"       │        /tf-e2e-tester            │
         │               │                                  │
         │               │  Runs /tf-plan → /tf-implement   │
         │               │  with test defaults (no prompts) │
         │               │  Validates artifact generation   │
         │               │  and cross-phase consistency     │
         │               └─────────────────────────────────┘
```

## Prerequisites

You need the following environment variables set on your **host machine** before opening the devcontainer:

| Variable                | Purpose                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `GITHUB_TOKEN`          | GitHub CLI authentication                                      |
| `TEAM_TFE_TOKEN`        | HCP Terraform API token (maps to `TFE_TOKEN` inside container) |
| `AWS_ACCESS_KEY_ID`     | AWS credentials for provider access (integration testing)      |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials                                                |
| `AWS_SESSION_TOKEN`     | AWS session token (if using STS)                               |

Optional (for enterprise/internal setups):

- `GH_ENTERPRISE_TOKEN` — for GitHub Enterprise authentication
- `INTERNAL_CA_HOST`, `INTERNAL_CA_IP`, `INTERNAL_CA_CERT_NAME` — for internal certificate authorities (see `.devcontainer/scripts/setup-internal-certs.sh`)
- `CLAUDE_CODE_TEAM_NAME` — team identifier for Claude Code telemetry

## Running in the Devcontainer

### 1. Open the devcontainer

In VS Code, open the repo and select **"Reopen in Container"** (or use the command palette: `Dev Containers: Reopen in Container`). Choose the **"Claude Code"** configuration.

The devcontainer comes pre-installed with:

- Claude Code CLI (`claude`)
- Terraform, tflint, terraform-docs
- GitHub CLI (`gh`)
- AWS CLI
- Node.js toolchain
- Pre-configured Terraform credentials (from your `TEAM_TFE_TOKEN`)

### 2. Authenticate Claude Code

Open a terminal inside the devcontainer and run:

```bash
claude
```

Follow the one-time authentication prompts. Your config persists in the `claude-code-config` Docker volume across rebuilds.

## The Three Entry Points

### `/tf-plan` — Plan module features (no code written)

Start Claude Code and type:

```
/tf-plan
```

You will be asked about the module you want to build (what resources, what features, what provider). The skill then runs sequential phases:

1. **Setup** — validates environment (tools, credentials, TFE_TOKEN) and gathers requirements
2. **Specification** — writes `spec.md`, generates quality checklists, then asks you up to 5 clarifying questions
3. **Research + Planning** — runs parallel research agents against AWS/provider docs, back-propagates findings into `spec.md`, then drafts `plan.md`
4. **Security review** — `aws-security-advisor` evaluates the plan; flags Critical findings before proceeding
5. **Task generation** — breaks the plan into ordered tasks in `tasks.md`
6. **Analysis + Remediation** — cross-checks spec, plan, and tasks for consistency; iterates up to 3 times to fix Critical/High/Medium findings
7. **Summary + Approval** — posts results to the GitHub issue and awaits your review

All artifacts land in `specs/<feature-name>/`.

### `/tf-implement` — Execute the plan

After reviewing the plan artifacts:

```
/tf-implement
```

This picks up from where `/tf-plan` left off:

1. **Prerequisites** — verifies `spec.md`, `plan.md`, and `tasks.md` exist; resolves the feature branch and GitHub issue
2. **Implementation** — launches parallel task executors that write module code, tests, and examples concurrently
3. **Testing** — runs `terraform fmt -check`, `terraform validate`, `terraform test`, and verifies examples plan successfully
4. **Quality review** — `code-quality-judge` evaluates the implementation; flags Critical findings
5. **Report** — generates a module readiness report
6. **Cleanup + PR** — pushes the branch and creates a pull request linked to the GitHub issue

### `/tf-e2e-tester` — Validate the full pipeline

For testing the workflow itself (after making changes to skills/agents):

```
/tf-e2e-tester
```

Runs the complete `/tf-plan` then `/tf-implement` cycle non-interactively with pre-set test inputs. Useful for CI or regression testing the pipeline.

## Example: Planning a VPC Module

Here is a full `/tf-plan` invocation you can use to test the planning workflow end-to-end:

```
/tf-plan Build a Terraform module that creates:
  - VPC with configurable CIDR
  - Public and private subnets across configurable AZs
  - NAT Gateway (optional, toggleable)
  - VPC Flow Logs to CloudWatch (enabled by default)
  - AWS Region: configurable via examples
  - Secure defaults throughout

  ## HCP Terraform Configuration

  - **Organization**: `<your-org-name>`
  - **Project**: `<your-project>`
  - **Workspace**: `<your-workspace-name>`
```

This prompt gives the orchestrator enough detail to proceed through all planning phases. It produces:

- A GitHub issue as audit trail (with progress updates posted after each phase)
- `spec.md` covering the module's interface (inputs, outputs, resources)
- `plan.md` identifying resources, patterns, and architecture
- `tasks.md` with phased implementation and testing tasks
- Research files, security review, and consistency analysis

After reviewing the artifacts in `specs/<feature-branch>/`, run `/tf-implement` to execute the plan.

## Typical Session

```bash
# Open terminal in devcontainer
claude

# Plan a module
> /tf-plan "VPC module with public/private subnets, NAT gateway, flow logs"

# ... answer clarification questions (if any) ...
# ... review generated spec.md, plan.md, tasks.md ...

# Implement it
> /tf-implement

# ... watch agents write Terraform, tests, examples ...

# Run tests
> terraform test
```

## Directory Structure

### Module structure (what you develop)

```
/
├── main.tf              # Primary resources
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── locals.tf            # Local computations
├── providers.tf         # Provider requirements (required_providers only)
├── terraform.tf         # Version constraints
├── README.md            # Module documentation
├── examples/
│   ├── basic/           # Minimal usage example
│   └── complete/        # Full-featured example
├── modules/             # Submodules (optional)
└── tests/               # Terraform test files
    ├── basic.tftest.hcl
    └── complete.tftest.hcl
```

### Planning artifacts (generated by /tf-plan)

```
specs/<feature-name>/
  spec.md              # What to build (module interface specification)
  plan.md              # How to build it (resources, patterns, architecture)
  tasks.md             # Ordered task breakdown for implementation
  checklists/          # Quality validation criteria
  research/            # AWS docs and provider research findings
  contracts/
    module-interfaces.md  # Module interface contracts
    data-model.md         # Data flows and resource relationships
  evaluations/
    consistency-analysis.md  # Cross-artifact consistency checks
    remediation-log.md      # Fixes applied during analysis iterations
  reports/
    security-review.md   # Security review (from /tf-plan)
    quality-*.md         # Quality review (from /tf-implement)
    readiness_*.md       # Module readiness report (from /tf-implement)
```

## Troubleshooting

**"MCP server not responding"** — Restart the devcontainer. MCP servers are configured in `.claude/settings.local.json` and start automatically.

**"GitHub CLI not authenticated"** — Run `gh auth login` inside the container, or ensure `GITHUB_TOKEN` is set on your host before opening the devcontainer.

**"Terraform credentials missing"** — The post-create script writes `~/.terraform.d/credentials.tfrc.json` from `TFE_TOKEN`. If the token wasn't set at container creation time, re-run: `bash /workspace/.devcontainer/claude-code/scripts/post-create.sh`

**Agent fails mid-workflow** — Re-run the same skill (`/tf-plan` or `/tf-implement`). The orchestrator detects existing artifacts and resumes from the failed phase rather than restarting.
