# Compound Engineering: Principles and Patterns for AI-Driven Development

## 1. What Is Compound Engineering?

Compound engineering is a methodology for AI-assisted software development built on one foundational insight: **each unit of engineering work should make subsequent units easier, not harder**. The term draws from "compound interest" in finance -- small, consistent investments in knowledge capture and process refinement accumulate into exponential productivity gains over time.

The methodology was pioneered by Every, Inc. through their open-source [Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin), a toolkit designed for Claude Code and other AI coding assistants. Rather than treating AI as a one-shot code generator, compound engineering structures AI-assisted development as a cyclical, self-improving system where solved problems become reusable assets.

The core inversion: traditional development accumulates complexity and technical debt with each feature. Compound engineering inverts this by codifying solutions, patterns, and domain knowledge so that the cost of future work decreases over time.

---

## 2. The Core Workflow Cycle

Compound engineering organizes work into a repeating five-phase cycle (Brainstorm is optional):

```
Brainstorm (optional) --> Plan --> Work --> Review --> Compound --> (repeat)
```

Each phase has a dedicated workflow command and specialized agents. The model explicitly prioritizes **planning and review (80% of effort)** over raw execution (20%), reflecting the reality that AI can generate code quickly but correctness and alignment require careful orchestration.

### 2.1 Brainstorm (`/workflows:brainstorm`)

An optional pre-planning phase that answers **what** to build before addressing how. Key characteristics:

- **Clarity gating**: Assesses whether brainstorming is even needed. If requirements are already detailed with acceptance criteria, it skips directly to planning.
- **One question at a time**: Avoids overwhelming users with multi-part interrogations. Dialogue is sequential and focused.
- **YAGNI-first recommendations**: When proposing 2-3 alternative approaches, simpler solutions are always preferred.
- **Artifact capture**: Outputs to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`, creating a durable record that downstream phases can reference.
- **No code during brainstorming**: Strict separation of ideation from implementation prevents premature commitment.

### 2.2 Plan (`/workflows:plan`)

Transforms feature ideas into structured implementation blueprints. The planning workflow demonstrates several compound engineering principles:

- **Context reuse**: Checks for recent brainstorm documents (within 14 days) before asking redundant questions. Prior work compounds.
- **Parallel research agents**: Runs repository analysis, learnings review, and external research concurrently.
- **Risk-calibrated depth**: Offers three detail levels (MINIMAL, MORE, A LOT) based on complexity. Security, payments, and API work automatically triggers deeper analysis.
- **Structured output**: Plans are saved as dated markdown files with cross-references, enabling future plans to build on past ones.

### 2.3 Work (`/workflows:work`)

Executes plans through a four-phase process:

1. **Quick Start**: Read the plan completely, ask clarifying questions before writing code, set up branch/worktree.
2. **Execute**: Work tasks in priority order, follow existing codebase conventions, test after each change, commit incrementally.
3. **Quality Check**: Run full test suite, invoke specialized reviewer agents for complex changes, validate completeness.
4. **Ship**: Create PR with summary, testing notes, and before/after visuals.

Key principle: **test continuously, not at the end**. Each logical unit gets committed and verified independently.

### 2.4 Review (`/workflows:review`)

Multi-agent code review using parallel specialized reviewers:

- Security, performance, and architecture specialists run simultaneously.
- Conditional agents activate based on change type (e.g., database migrations trigger data integrity review).
- **Ultra-thinking deep dive**: Explores edge cases, boundary conditions, and failure modes from multiple stakeholder perspectives (developer, operations, user, security, business).
- Findings are severity-categorized: P1 (critical, blocks merge), P2 (important), P3 (nice-to-have).

### 2.5 Compound (`/workflows:compound`)

The defining phase that closes the loop. This is where knowledge compounds:

- **Seven parallel subagents** process the completed work simultaneously:
  1. Context Analyzer -- extracts problem type, component, and symptoms
  2. Solution Extractor -- identifies root cause and working fixes with code examples
  3. Related Docs Finder -- cross-references existing documentation
  4. Prevention Strategist -- generates test cases and prevention strategies
  5. Category Classifier -- determines optimal folder structure in `docs/solutions/`
  6. Documentation Writer -- assembles complete markdown with YAML frontmatter
  7. Specialized Agents -- auto-triggers domain experts based on problem type

- **The compounding effect**: A 30-minute research problem, once documented, becomes a 2-minute lookup. Over time, the knowledge base becomes the team's most valuable asset.

---

## 3. Architectural Patterns

### 3.1 Multi-Agent Composition

Compound engineering's architecture is built on four component types:

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 27 | Specialized AI personas with focused expertise |
| **Commands** | 20 | Workflow orchestration through slash commands |
| **Skills** | 15 | Reusable expertise modules (patterns, conventions, tools) |
| **MCP Servers** | 1+ | External knowledge integration (e.g., Context7 for framework docs) |

Agents are organized by function:
- **Review agents (14)**: Code quality, security, performance, architecture, data integrity
- **Research agents (4)**: Documentation lookup, best practices, git history analysis
- **Design agents (3)**: UI implementation verification, design iteration
- **Workflow agents (5)**: Bug reproduction, style enforcement, linting
- **Docs agents**: Documentation creation and maintenance

### 3.2 Parallel Execution Pattern

A recurring pattern throughout compound engineering is launching multiple independent agents simultaneously rather than sequentially. The `resolve_parallel` command exemplifies this:

1. **Analyze**: Gather all unresolved items.
2. **Plan**: Identify dependencies, distinguish parallel-eligible work from sequential prerequisites, visualize with a mermaid diagram.
3. **Implement**: Spawn one subagent per item concurrently.
4. **Consolidate**: Merge changes, commit, push.

This pattern appears in planning (parallel research agents), review (parallel specialized reviewers), and compounding (seven simultaneous documentation agents).

### 3.3 Agent-Native Architecture

The plugin implements a "prompt-native agent architecture" where agents are defined as markdown documents rather than code. Each agent is a structured prompt specifying:

- Role and expertise domain
- Input expectations
- Output format
- Quality criteria
- When to activate (conditional triggering)

This makes agents composable, versionable, and reviewable through standard code review processes.

### 3.4 Skill as Reusable Expertise

Skills encode domain knowledge that transcends individual tasks:

- **Convention skills**: DHH Rails style, Andrew Kane gem patterns -- encode opinionated best practices
- **Meta-skills**: `skill-creator` and `create-agent-skills` -- the system can generate new skills from experience
- **Tool skills**: Browser automation, git worktree management -- encode operational knowledge
- **Documentation skills**: Compound docs, style editor -- encode communication patterns

The critical insight is that skills are not just code templates; they are **encoded judgment** about how to approach categories of problems.

---

## 4. Foundational Principles

### 4.1 Knowledge Compounds, Complexity Should Not

Every solved problem should reduce the cost of solving similar problems. This requires active investment in documentation and pattern extraction, not passive accumulation of code.

### 4.2 Planning Over Execution

The 80/20 split (80% planning and review, 20% execution) reflects AI's comparative advantage: generating code is cheap, but generating the *right* code requires careful specification. Compound engineering front-loads the thinking.

### 4.3 Parallel Where Possible, Sequential Where Necessary

Dependency analysis determines execution strategy. Independent work items run concurrently through subagents. Dependent items run sequentially. This is explicitly modeled in task graphs rather than left implicit.

### 4.4 Multi-Perspective Quality

No single reviewer catches everything. Compound engineering applies multiple specialized lenses (security, performance, architecture, business value, team dynamics) simultaneously. Findings are severity-ranked to focus attention.

### 4.5 Convention Over Configuration

Following existing codebase patterns is an explicit instruction in the work phase. AI agents are directed to "look for similar patterns in codebase" before introducing new approaches. This reduces cognitive load and maintains consistency.

### 4.6 Continuous Testing, Not Terminal Testing

Test after each change, not at the end. This catches issues early when context is fresh and the blast radius is small.

### 4.7 Strict Phase Separation

Brainstorming does not produce code. Planning does not execute. Review does not fix. Each phase has a clear boundary and output format. This prevents premature commitment and ensures each phase's output is independently valuable.

---

## 5. Task Decomposition and Delegation Patterns

### 5.1 Hierarchical Decomposition

```
Feature Request
  --> Brainstorm (what to build)
    --> Plan (how to build)
      --> Tasks (ordered work items)
        --> Subtask execution (individual agents)
          --> Review (quality gates)
            --> Compound (knowledge capture)
```

Each level refines the previous level's output into more concrete, actionable units.

### 5.2 Subagent Delegation

When a workflow step requires specialized expertise, it spawns a subagent rather than attempting the work itself. The parent workflow:

1. Identifies the specialization needed
2. Selects the appropriate agent
3. Provides context and constraints
4. Collects and synthesizes results
5. Makes the integration decision

This mirrors how senior engineers delegate: they provide context and review results rather than doing everything themselves.

### 5.3 Conditional Activation

Not all agents run for all tasks. Compound engineering uses conditional triggers:

- Database migrations activate data integrity reviewers
- Security-sensitive changes activate the security sentinel
- Performance-critical paths activate the performance oracle
- UI changes activate design verification agents

This prevents unnecessary overhead while ensuring specialized review when it matters.

---

## 6. Quality Control Mechanisms

### 6.1 Multi-Agent Review

The review workflow runs 10+ specialized agents in parallel, each evaluating code from a different perspective. This produces a comprehensive view that no single reviewer (human or AI) could achieve alone.

### 6.2 Severity-Based Triage

Findings are categorized as:
- **P1 (Critical)**: Security vulnerabilities, data corruption risks, breaking changes. These block merge.
- **P2 (Important)**: Significant issues that should be addressed.
- **P3 (Nice-to-have)**: Style improvements, minor optimizations.

### 6.3 Pre-Submission Checklists

Plans include pre-submission checklists validated before output. Deployments generate Go/No-Go checklists. This ensures completeness without relying on memory.

### 6.4 Stakeholder Perspective Analysis

Review explicitly considers multiple stakeholder viewpoints: developer experience, operations burden, user impact, security exposure, and business value. This prevents tunnel vision on purely technical concerns.

---

## 7. Feedback Loops and Iteration

### 7.1 The Compound Loop

The `/workflows:compound` command is the primary feedback mechanism. After completing work, the system extracts and documents:

- Problem symptoms and investigation steps
- Root cause analysis
- Working solutions with code examples
- Prevention strategies and test cases
- Cross-references to related issues

This documentation feeds back into future planning (brainstorm docs are checked) and review (known patterns are referenced).

### 7.2 Plan Deepening

The `/deepen-plan` command allows iterative refinement of plans before execution begins. Rather than committing to a plan immediately, teams can:

- Request additional research on specific aspects
- Explore alternative approaches
- Add risk analysis
- Expand acceptance criteria

### 7.3 PR Comment Resolution

The `resolve_pr_parallel` command creates a feedback loop between code review and implementation. Review comments spawn parallel resolver agents that address feedback concurrently, then consolidate changes.

### 7.4 Skill Evolution

The meta-skills (`skill-creator`, `create-agent-skills`, `heal-skill`) enable the system to evolve its own capabilities:

- New patterns discovered during work become new skills
- Broken or outdated skills get repaired through `heal-skill`
- The agent population grows and improves based on actual usage

---

## 8. Integration with AI Coding Assistants

### 8.1 Plugin Architecture

Compound engineering integrates with AI assistants through a plugin system:

```
Claude Code:     /plugin install compound-engineering
OpenCode:        bunx @every-env/compound-plugin install compound-engineering --to opencode
Codex:           bunx @every-env/compound-plugin install compound-engineering --to codex
```

The plugin registers agents, commands, skills, and MCP servers with the host assistant.

### 8.2 Prompt-Native Design

All components are defined as markdown files, making them:

- **Versionable**: Track changes through git like any other code
- **Reviewable**: Apply standard code review to agent definitions
- **Composable**: Agents reference skills, commands orchestrate agents
- **Portable**: The same definitions work across different AI assistants (with format conversion)

### 8.3 MCP Server Integration

External knowledge sources integrate through the Model Context Protocol. Context7 provides documentation for 100+ frameworks, eliminating the need for AI assistants to rely on potentially outdated training data.

### 8.4 Tool Orchestration

Commands orchestrate the AI assistant's tool usage, directing it to:

- Use `TodoWrite` for task tracking during work phases
- Use `AskUserQuestion` for clarification during brainstorming
- Use subagent spawning for parallel execution
- Use git worktrees for isolated review environments

---

## 9. Applying Compound Engineering Principles

### 9.1 For Individual Developers

1. **Start with `/compound` after every non-trivial problem**. The knowledge base is the highest-leverage investment.
2. **Use brainstorming to prevent premature implementation**. The cost of thinking is always lower than the cost of rework.
3. **Run parallel reviews on anything touching security, data, or external APIs**. Multiple perspectives catch what single-pass review misses.

### 9.2 For Teams

1. **Share the `docs/solutions/` directory**. One team member's documented solution saves every other member's research time.
2. **Create team-specific skills encoding your conventions**. Convention skills reduce onboarding time and maintain consistency.
3. **Review agent definitions as carefully as production code**. Agents encode judgment; incorrect judgment scales as dangerously as incorrect code.

### 9.3 For AI-Driven Workflows

1. **Decompose before delegating**. AI agents work best on well-scoped, clearly specified tasks. Invest in decomposition.
2. **Use parallel execution for independent work**. Dependency-aware parallelism is the primary scaling mechanism.
3. **Gate on quality, not speed**. P1 findings block merge regardless of deadline pressure.
4. **Close every loop**. Work without compounding is a missed investment. Every completed task should leave the system better than it found it.

---

## 10. Key Takeaways

| Principle | Traditional Development | Compound Engineering |
|-----------|------------------------|---------------------|
| Knowledge management | Ad hoc, tribal | Systematic capture via `/compound` |
| Code review | Single reviewer, sequential | Multi-agent, parallel, severity-ranked |
| Planning depth | Proportional to deadline | Calibrated to risk (80/20 rule) |
| Task execution | Sequential by default | Parallel where dependency-safe |
| Quality gates | End-of-process testing | Continuous testing after each change |
| AI usage | One-shot code generation | Cyclical workflow with feedback loops |
| Problem solving | Solve and move on | Solve, document, and prevent recurrence |
| Process improvement | Periodic retrospectives | Continuous skill and agent evolution |

Compound engineering represents a shift from treating AI as a code generator to treating it as a **knowledge-compounding system**. The methodology's value is not in any single AI interaction but in the accumulated effect of systematic capture, reuse, and refinement of engineering knowledge across every development cycle.

---

## Sources

- [Compound Engineering Plugin (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering)
