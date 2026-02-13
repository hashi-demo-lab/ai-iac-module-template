# 07 - Concurrent Subagents: Patterns for Parallel Agent Execution

## Overview

Claude Code's subagent system enables task delegation to specialized, isolated AI agents that run in their own context windows. This document captures the architecture, capabilities, and patterns for maximizing throughput through concurrent subagent execution.

---

## 1. The Task Tool and Subagent Architecture

### How Subagents Work

Subagents are specialized AI assistants that run in **isolated context windows** with:
- A custom system prompt (the markdown body of the agent definition)
- Specific tool access (allowlist or denylist)
- Independent permissions (inherited or overridden)
- Their own model selection (can differ from parent)

When Claude encounters a task matching a subagent's description, it delegates via the **Task tool**. The subagent works independently and returns results to the parent conversation.

### Key Constraint: No Nesting

Subagents **cannot spawn other subagents**. This is a hard architectural constraint. If a workflow requires nested delegation, the parent conversation must orchestrate sequential subagent calls (chaining) or use Skills instead.

### Context Isolation

Each subagent invocation creates a fresh context window. The subagent receives:
- Its system prompt (from the agent definition markdown body)
- Basic environment details (working directory)
- CLAUDE.md files
- Preloaded skills (if configured via `skills` field)
- The delegation message from the parent

It does **not** receive the parent's conversation history.

---

## 2. Built-in Subagent Types

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| **Explore** | Haiku (fast) | Read-only (no Write/Edit) | File discovery, code search, codebase exploration |
| **Plan** | Inherited | Read-only (no Write/Edit) | Codebase research for planning mode |
| **general-purpose** | Inherited | All tools | Complex research, multi-step operations, code modifications |
| **Bash** | Inherited | Terminal commands | Running commands in separate context |
| **Claude Code Guide** | Haiku | - | Questions about Claude Code features |

### Explore Agent Thoroughness Levels

When invoking Explore, Claude specifies a thoroughness level:
- **quick**: Targeted lookups
- **medium**: Balanced exploration
- **very thorough**: Comprehensive analysis

This is the most commonly used subagent for parallel research patterns.

---

## 3. Custom Subagent Configuration

### Definition Format

Subagents are Markdown files with YAML frontmatter stored at:
- `.claude/agents/` (project scope, checked into git)
- `~/.claude/agents/` (user scope, all projects)
- `--agents` CLI flag (session scope, JSON format)
- Plugin `agents/` directory (plugin scope)

### Key Configuration Fields

```yaml
---
name: my-agent              # Unique identifier (lowercase, hyphens)
description: When to use    # Claude uses this to decide delegation
tools: Read, Grep, Glob     # Tool allowlist (inherits all if omitted)
disallowedTools: Write       # Tool denylist
model: opus               # opus for all subagents
permissionMode: default     # default | acceptEdits | dontAsk | bypassPermissions | plan
skills:                     # Skills preloaded into context at startup
  - api-conventions
hooks:                       # Lifecycle hooks scoped to this agent
  PreToolUse: [...]
---

System prompt content here...
```

### Model Selection Strategy

- **Haiku**: Fast, cheap. Use for high-volume read-only tasks (exploration, search).
- **Sonnet**: Balanced. Use for analysis requiring reasoning.
- **Opus**: Most capable. Use for complex tasks requiring deep understanding.
- **inherit**: Match parent conversation model.

---

## 4. Foreground vs Background Execution

### Foreground Subagents
- **Block** the main conversation until complete
- Permission prompts pass through to the user
- Can ask clarifying questions via `AskUserQuestion`
- Full interactive capability

### Background Subagents
- Run **concurrently** while the user continues working
- Inherit parent permissions; auto-deny anything not pre-approved
- Cannot ask clarifying questions (tool call fails, agent continues)
- **MCP tools are NOT available** in background subagents
- Can be resumed in foreground if they fail due to missing permissions

### Controlling Execution Mode

- Claude decides foreground vs background based on task nature
- User can say "run this in the background" to force background
- Press **Ctrl+B** to background a running foreground task
- Set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` to disable background entirely

---

## 5. Concurrent Execution Patterns

### Pattern 1: Fan-Out Research

Spawn multiple subagents to investigate independent areas simultaneously.

```
Research the authentication, database, and API modules
in parallel using separate subagents
```

Each subagent explores independently, then Claude synthesizes findings. **Best when research paths don't depend on each other.**

**Warning**: Each returning subagent's results consume main conversation context. Many detailed results can exhaust context quickly.

### Pattern 2: Fan-Out File Processing

Use headless mode (`claude -p`) for large-scale parallel processing:

```bash
for file in $(cat files.txt); do
  claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit:*)" &
done
wait
```

Each invocation runs in a completely independent process with its own context.

### Pattern 3: Writer/Reviewer Pattern

Two parallel sessions with distinct roles:

| Session A (Writer) | Session B (Reviewer) |
|---|---|
| Implement the feature | Review the implementation |
| Address review feedback | Re-review changes |

Fresh context in the reviewer session prevents bias toward code the same agent wrote.

### Pattern 4: Subagent Chaining

Sequential delegation where each subagent's output feeds the next:

```
Use the code-reviewer subagent to find performance issues,
then use the optimizer subagent to fix them
```

Claude passes relevant context between subagents. The parent orchestrates.

### Pattern 5: Isolate High-Volume Operations

Delegate operations with large output (test suites, log analysis, doc fetching) to subagents. Verbose output stays in the subagent's context; only the summary returns.

```
Use a subagent to run the test suite and report only
the failing tests with their error messages
```

### Pattern 6: Skill-Driven Subagent Execution

Skills with `context: fork` run in an isolated subagent context:

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

The skill content becomes the subagent's task. The `agent` field determines execution environment.

---

## 6. Context Sharing Between Parent and Child

### What the Parent Sends
- The delegation message (task description)
- Implicitly, the working directory and environment

### What the Parent Does NOT Send
- Conversation history
- Previously read file contents
- Prior subagent results (unless explicitly included in the delegation message)

### What the Child Returns
- A summary of its work and findings
- The child's full transcript is stored at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`

### Resuming Subagents

Subagents can be resumed with their full conversation history intact:

```
Continue that code review and now analyze the authorization logic
```

Claude tracks agent IDs from completed subagents. Resumed subagents pick up exactly where they stopped.

### Context Lifecycle
- Main conversation compaction does NOT affect subagent transcripts
- Subagent transcripts persist within sessions
- Auto-compaction triggers at ~95% capacity (configurable via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`)
- Transcripts cleaned up after `cleanupPeriodDays` (default: 30)

---

## 7. Preloading Skills into Subagents

Skills can be injected into a subagent's context at startup via the `skills` field:

```yaml
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---
Implement API endpoints. Follow the conventions from the preloaded skills.
```

Key behaviors:
- **Full skill content** is injected, not just made available for invocation
- Subagents do **not** inherit skills from the parent conversation
- Skills must be listed explicitly
- This is the inverse of `context: fork` in a skill (where the skill drives the subagent)

---

## 8. Maximizing Throughput

### Principles

1. **Parallelize independent work**: Any tasks without data dependencies should fan out to concurrent subagents.
2. **Use the cheapest capable model**: Haiku for exploration, Sonnet for analysis, Opus only for complex reasoning.
3. **Minimize return payload**: Instruct subagents to return summaries, not raw data. Large returns consume parent context.
4. **Scope investigations narrowly**: Unbounded exploration fills context and wastes tokens.
5. **Use headless mode for batch processing**: `claude -p` enables true process-level parallelism with no shared state.
6. **Background for independence, foreground for interaction**: Background subagents cannot ask questions or request permissions.

### Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Too many concurrent subagents returning detailed results | Exhausts parent context | Instruct subagents to return concise summaries |
| Attempting nested subagents | Architectural limitation | Chain from parent or use Skills |
| Background subagent needing MCP tools | MCP unavailable in background | Run in foreground or pre-fetch data |
| Unbounded exploration subagent | Reads hundreds of files, fills context | Scope narrowly: specific files, directories, or patterns |
| Reusing subagent context across unrelated tasks | Stale context degrades quality | Fresh invocations for unrelated work |

---

## 9. Clean Handoff Patterns

### Delegation Handoff

When delegating to a subagent, provide:
1. **Clear task description**: What to accomplish
2. **Scope boundaries**: Which files, directories, or domains to focus on
3. **Expected output format**: What information to return
4. **Success criteria**: How to know the task is done

### Result Aggregation

When multiple subagents return results:
1. Claude synthesizes findings in the parent conversation
2. Conflicting findings are reconciled by the parent
3. The parent decides next steps based on aggregated results
4. Follow-up subagents can be spawned with synthesized context

### Session-to-Session Handoff

For multi-session workflows:
```bash
# Capture session ID for later resumption
session_id=$(claude -p "Start analysis" --output-format json | jq -r '.session_id')

# Resume specific session
claude -p "Continue analysis" --resume "$session_id"
```

---

## 10. Practical Configuration Examples

### Read-Only Research Agent
```yaml
---
name: researcher
description: Deep codebase research without modifications
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: opus
---
Research the topic thoroughly. Return findings with file references.
```

### Security Review Agent
```yaml
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: Read, Grep, Glob, Bash
model: opus
---
Review code for injection vulnerabilities, auth flaws,
exposed secrets, and insecure data handling.
Provide specific line references and suggested fixes.
```

### Test Runner Agent (Isolate Verbose Output)
```yaml
---
name: test-runner
description: Run tests and report failures concisely
tools: Bash, Read, Grep
model: opus
---
Run the test suite. Report ONLY:
- Number of tests passed/failed
- For each failure: test name, error message, relevant file:line
Do not include passing test output.
```

### Constrained Database Agent (Hook-Based Validation)
```yaml
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
Execute SELECT queries to answer data questions.
```

---

## 11. Decision Framework

### When to Use Subagents vs Main Conversation

| Use Subagents When | Use Main Conversation When |
|---|---|
| Task produces verbose output | Task needs frequent back-and-forth |
| Need to enforce tool restrictions | Multiple phases share context |
| Work is self-contained | Making quick targeted changes |
| Exploration would pollute main context | Latency matters (subagents start fresh) |
| Parallel investigation is possible | Iterative refinement needed |

### When to Use Skills vs Subagents

| Skills | Subagents |
|---|---|
| Reusable prompts/workflows | Isolated execution context |
| Run in main conversation context | Own context window |
| Can be invoked by user or Claude | Delegated by Claude |
| Reference knowledge (conventions, patterns) | Task execution (research, review, build) |
| `context: fork` bridges to subagent execution | `skills` field bridges to skill knowledge |

### When to Use Headless Mode vs Interactive Subagents

| Headless (`claude -p`) | Interactive Subagents |
|---|---|
| True process-level parallelism | In-conversation parallelism |
| No shared state between invocations | Parent orchestrates and synthesizes |
| Batch processing (file migrations) | Research and analysis |
| CI/CD pipelines | Conversational workflows |
| Can use `--allowedTools` for scoping | Inherits or overrides parent permissions |

---

## Summary of Key Principles

1. **Subagents run in isolated contexts** -- they do not share the parent's conversation history.
2. **No nesting** -- subagents cannot spawn subagents; the parent must orchestrate chains.
3. **Background subagents auto-deny** unpermitted operations and cannot use MCP tools.
4. **Context is the fundamental constraint** -- subagents exist primarily to protect the parent's context budget.
5. **Fan-out for independence, chain for dependence** -- parallelize when tasks are independent; sequence when outputs feed inputs.
6. **Right-size the model** -- Haiku for fast read-only work, Sonnet for balanced analysis, Opus for complex reasoning.
7. **Instruct for concise returns** -- subagent results consume parent context; demand summaries, not raw data.
8. **Preload skills for domain knowledge** -- use the `skills` field to inject conventions without runtime discovery overhead.
9. **Resume, don't restart** -- subagents can be resumed with full history for iterative work.
10. **Scope narrowly** -- unbounded exploration is the most common subagent anti-pattern.

---

## Sources

- [Claude Code Sub-Agents Documentation](https://code.claude.com/docs/en/sub-agents)
