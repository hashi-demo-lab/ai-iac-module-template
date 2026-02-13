# Claude Code Skills: Comprehensive Analysis

## 1. What Are Skills?

Skills are the primary extension mechanism for Claude Code. A skill is a `SKILL.md` file containing YAML frontmatter and markdown instructions that teaches Claude new capabilities. Skills follow the open [Agent Skills](https://agentskills.io) standard, which works across multiple AI tools.

When a skill is registered, two things happen:

1. **Description loading**: The skill's description is loaded into Claude's context so it knows the skill exists and when to use it.
2. **On-demand activation**: The full skill content loads only when the skill is invoked, either automatically by Claude or manually via `/skill-name`.

Skills supersede the older "custom slash commands" system. Files at `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` both create `/review` and work identically. If both exist with the same name, the skill takes precedence. Existing command files continue to work.

## 2. Skill Structure and Anatomy

### Directory Layout

Each skill is a directory with `SKILL.md` as the entrypoint:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

### SKILL.md Format

Every `SKILL.md` has two parts:

1. **YAML frontmatter** (between `---` markers) -- configuration metadata
2. **Markdown body** -- the instructions Claude follows when the skill is active

```yaml
---
name: my-skill
description: What this skill does and when to use it
---

Instructions for Claude when this skill is invoked...
```

### Frontmatter Reference

| Field                      | Required    | Description                                                                 |
|:---------------------------|:------------|:----------------------------------------------------------------------------|
| `name`                     | No (Claude Code) / Yes (Agent Skills spec) | Display name and slash command. In Claude Code, defaults to the directory name if omitted. The [Agent Skills open standard](https://agentskills.io/specification) marks this field as **required**. Lowercase, hyphens, max 64 chars. |
| `description`              | Recommended | What the skill does and when to use it. Claude uses this for auto-invocation decisions. |
| `argument-hint`            | No          | Autocomplete hint, e.g., `[issue-number]` or `[filename] [format]`.        |
| `disable-model-invocation` | No          | `true` prevents Claude from auto-loading. Manual `/name` only. Default: `false`. |
| `user-invocable`           | No          | `false` hides from `/` menu. Background knowledge only. Default: `true`.   |
| `allowed-tools`            | No          | Tools Claude can use without permission prompts when skill is active.       |
| `model`                    | No          | Model override when skill is active.                                        |
| `context`                  | No          | `fork` to run in an isolated subagent context.                              |
| `agent`                    | No          | Which subagent type to use when `context: fork` is set.                     |
| `hooks`                    | No          | Lifecycle hooks scoped to this skill.                                       |

## 3. Skill Storage and Scoping

Where a skill lives determines who can use it:

| Location   | Path                                             | Applies to                     | Priority       |
|:-----------|:-------------------------------------------------|:-------------------------------|:---------------|
| Enterprise | Managed settings                                 | All users in organization      | Highest        |
| Personal   | `~/.claude/skills/<skill-name>/SKILL.md`         | All your projects              | High           |
| Project    | `.claude/skills/<skill-name>/SKILL.md`           | Current project only           | Medium         |
| Plugin     | `<plugin>/skills/<skill-name>/SKILL.md`          | Where plugin is enabled        | Namespaced     |

When skills share the same name, higher-priority locations win: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespacing, so they never conflict.

**Monorepo support**: Claude automatically discovers skills from nested `.claude/skills/` directories. Editing a file in `packages/frontend/` also picks up skills from `packages/frontend/.claude/skills/`.

## 4. Two Fundamental Types of Skill Content

### Reference Skills (Knowledge Injection)

Add domain knowledge Claude applies to ongoing work. These run inline within the conversation context.

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### Task Skills (Procedural Workflows)

Step-by-step instructions for specific actions. Often invoked manually with `disable-model-invocation: true`.

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

The distinction matters because it determines how the skill should be invoked, where it should run, and what frontmatter to use.

## 5. Invocation Patterns

### Automatic Invocation

By default, Claude can invoke any skill whose description matches the current conversation context. Only the description is loaded into context; the full content loads on invocation.

### Manual Invocation

Type `/skill-name` optionally followed by arguments. This always works unless `user-invocable: false` is set.

### Controlling Who Can Invoke

| Frontmatter                      | User can invoke | Claude can invoke | Context behavior                                              |
|:---------------------------------|:----------------|:------------------|:--------------------------------------------------------------|
| (default)                        | Yes             | Yes               | Description always in context; full content loads on invocation |
| `disable-model-invocation: true` | Yes             | No                | Description NOT in context; loads only when user invokes       |
| `user-invocable: false`          | No              | Yes               | Description always in context; loads when Claude invokes       |

### Permission-Based Restriction

Skills can also be controlled through permission rules:

```
# Allow only specific skills
Skill(commit)
Skill(review-pr:*)

# Deny specific skills
Skill(deploy:*)

# Disable all skills
Skill
```

## 6. Arguments and String Substitution

Skills support dynamic values through string substitution:

| Variable               | Description                                                    |
|:-----------------------|:---------------------------------------------------------------|
| `$ARGUMENTS`           | All arguments passed when invoking the skill                   |
| `$ARGUMENTS[N]`        | Specific argument by 0-based index                             |
| `$N`                   | Shorthand for `$ARGUMENTS[N]`                                  |
| `${CLAUDE_SESSION_ID}` | Current session ID for logging or correlation                  |

If `$ARGUMENTS` is not present in the content, arguments are appended as `ARGUMENTS: <value>`.

Example with positional arguments:

```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

Invoked as: `/migrate-component SearchBar React Vue`

## 7. Dynamic Context Injection

The `` !`command` `` syntax runs shell commands as preprocessing before skill content reaches Claude. The command output replaces the placeholder.

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

This is preprocessing, not tool execution. Claude only sees the final rendered prompt with real data.

## 8. Skills and Subagents: The Dual Relationship

Skills and subagents interact in two complementary directions:

### Direction 1: Skill Runs in a Subagent (`context: fork`)

The skill content becomes the task prompt for an isolated subagent. The agent type provides the system prompt and tool configuration.

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

### Direction 2: Subagent Preloads Skills (`skills` field)

The subagent controls the system prompt and loads skill content as reference material at startup.

```yaml
# In .claude/agents/api-developer.md
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---

Implement API endpoints. Follow the conventions from the preloaded skills.
```

### Key Differences

| Approach                   | System prompt source           | Task source          | Also loads  |
|:---------------------------|:-------------------------------|:---------------------|:------------|
| Skill with `context: fork` | From agent type (Explore, etc.)| SKILL.md content     | CLAUDE.md   |
| Subagent with `skills`     | Subagent's markdown body       | Claude's delegation  | Skills + CLAUDE.md |

### Built-in Agent Types

When using `context: fork`, the `agent` field selects the execution environment:

- **Explore**: Fast (Haiku), read-only tools, optimized for search and analysis
- **Plan**: Inherits model, read-only tools, for planning and research
- **general-purpose**: Inherits model, all tools, for complex multi-step operations
- Custom agents from `.claude/agents/`

If `agent` is omitted, `general-purpose` is used.

## 9. Supporting Files and Skill Composition

### Supporting Files Pattern

Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files:

```
my-skill/
├── SKILL.md           # Overview and navigation (< 500 lines)
├── reference.md       # Detailed API docs (loaded when needed)
├── examples.md        # Usage examples (loaded when needed)
└── scripts/
    └── helper.py      # Utility script (executed, not loaded)
```

Reference them from `SKILL.md` so Claude knows what exists and when to load each file:

```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### Skill Chaining

Skills cannot directly invoke other skills. Chaining happens through:

1. **Subagent chaining from the main conversation**: Claude completes one skill, uses results to invoke the next.
2. **Workflow skills**: A single skill with multi-step instructions that reference other resources.
3. **The user orchestrates**: Manually invoking skills in sequence, each building on prior results.

Subagents cannot spawn other subagents. If a workflow requires nested delegation, use skills in the main conversation or chain subagents from the main conversation.

## 10. Context Budget and Discovery

Skill descriptions are loaded into context so Claude knows what is available. With many skills, descriptions may exceed the character budget (default 15,000 characters). Run `/context` to check for warnings about excluded skills.

To increase the limit: set `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable.

## 11. Best Practices for Skill Design

### Naming and Description

- **Write descriptions as if briefing a colleague**: Include what the skill does AND when to use it. Claude uses the description for auto-invocation decisions.
- **Use keywords users would naturally say**: If users ask "how does this work?", the description should contain those phrases.
- **Name with hyphens, lowercase only**: `fix-issue`, `deploy-staging`, `explain-code`.

### Invocation Control

- **Use `disable-model-invocation: true` for side effects**: Deploy, commit, send-message -- anything where timing matters.
- **Use `user-invocable: false` for pure knowledge**: Domain context, legacy system docs, coding conventions that Claude should absorb but users should not invoke as commands.
- **Default (both enabled) for utility skills**: Code explanation, research, formatting.

### Tool Restriction

- **Principle of least privilege**: Grant only the tools a skill needs via `allowed-tools`.
- **Read-only skills are safe skills**: `allowed-tools: Read, Grep, Glob` creates a safe exploration mode.

### Content Design

- **Keep SKILL.md focused and under 500 lines**. Move reference material to supporting files.
- **Start with the task, not background**: Claude already has the description; the body should be actionable.
- **Use numbered steps for procedural skills**: Clear sequence prevents ambiguity.
- **Include expected output format**: Tell Claude what the result should look like.

### Subagent Decisions

- **Use `context: fork` when**: The task produces verbose output, needs isolation, or is self-contained.
- **Stay inline when**: The task needs conversation context, requires iterative refinement, or is a quick operation.
- **Choose agent type deliberately**: `Explore` for read-only research (fast, cheap), `general-purpose` for tasks needing write access.

### Distribution

- **Project skills**: Commit `.claude/skills/` to version control for team sharing.
- **Personal skills**: `~/.claude/skills/` for cross-project personal workflows.
- **Plugins**: Package skills with other extensions for broader distribution.

## 12. Advanced Patterns

### Visual Output Generation

Skills can bundle scripts that generate interactive HTML, dependency graphs, test coverage reports, or any visual output. The skill orchestrates execution; the script does the heavy lifting.

### Extended Thinking

Include the word "ultrathink" anywhere in skill content to enable extended thinking mode for deeper reasoning.

### Hooks Integration

Skills can define lifecycle hooks in frontmatter:

```yaml
---
name: safe-deploy
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-deploy-command.sh"
---
```

### Session-Aware Skills

Use `${CLAUDE_SESSION_ID}` for logging, creating session-specific artifacts, or correlating output across tools.

## 13. Skills vs. Slash Commands vs. Subagents

| Concept        | What it is                                    | Runs where           | Reusable | Has own context |
|:---------------|:----------------------------------------------|:---------------------|:---------|:----------------|
| Slash command   | Legacy `.claude/commands/*.md` file           | Main conversation    | Yes      | No              |
| Skill (inline)  | `.claude/skills/*/SKILL.md`, no `context: fork` | Main conversation  | Yes      | No              |
| Skill (forked)  | Skill with `context: fork`                    | Isolated subagent    | Yes      | Yes             |
| Subagent        | `.claude/agents/*.md` definition              | Isolated context     | Yes      | Yes             |

Slash commands are the predecessor. Skills are the evolution -- same functionality plus: directory for supporting files, frontmatter for invocation control, automatic model-driven invocation, and subagent execution via `context: fork`.

## 14. Foundational Principles for Effective Skill Design

1. **Single Responsibility**: Each skill should excel at one specific task. Combine through chaining, not monolithic skills.

2. **Progressive Disclosure**: Load descriptions always, full content on demand, supporting files only when referenced. Respect the context budget.

3. **Explicit Over Implicit**: Use `disable-model-invocation` and `user-invocable` deliberately. Do not leave invocation behavior to chance for skills with side effects.

4. **Least Privilege**: Restrict tools to what the skill actually needs. A review skill should not have write access.

5. **Context Isolation for Heavy Work**: Use `context: fork` for tasks that produce verbose output or need specialized environments. Return only the summary to the main conversation.

6. **Composability Through Convention**: Since skills cannot directly call other skills, design them with clear inputs and outputs so they can be chained by the orchestrating agent or user.

7. **Description-Driven Discovery**: The description is the skill's API contract with Claude. Write it as precisely as you would write a function signature and docstring.

8. **Ship Skills as Code**: Commit project skills to version control. They are as much a part of the codebase as tests or CI configuration.

---

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
