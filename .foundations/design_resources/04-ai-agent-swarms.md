# AI Agent Swarms: Multi-Agent Coordination Patterns

A comprehensive analysis of swarm patterns for AI coding agents, with emphasis on Claude Code's TeammateTool and Task system.

> **⚠️ IMPORTANT**: The TeammateTool features described in this document (teams, inboxes, persistent teammates, shared task queues) are sourced from a [community GitHub Gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea), **not** official Claude Code documentation. These features may be experimental, preview, or unavailable in your Claude Code version. Official Claude Code supports only **subagents** (via the Task tool) with foreground/background execution modes. The swarm orchestration patterns (fan-out/fan-in, pipeline, work queue) remain valid conceptual models, but the TeammateTool primitives (Team, Inbox, Message) should not be assumed available. See `foundations/07-concurrent-subagents.md` for the verified subagent architecture.

---

## 1. What Is the Swarm Pattern?

A swarm is a multi-agent architecture where a **leader agent** decomposes work into discrete units and delegates them to **worker agents** (subagents or teammates) that operate concurrently. Workers self-organize around a shared task queue, communicate through message inboxes, and report results back to the leader for synthesis.

The key insight: instead of one agent holding an enormous context window while performing sequential work, multiple agents each hold focused context and work in parallel. This reduces context pressure, increases throughput, and allows specialization.

### Core Primitives

| Primitive | Purpose |
|-----------|---------|
| **Agent** | A Claude instance with tool access. The atomic unit. |
| **Team** | A named group of agents with a leader and teammates. |
| **Task** | A work item with subject, status, owner, and dependency graph. |
| **Inbox** | JSON file where agents receive messages from teammates. |
| **Message** | Structured JSON communication between agents (text, shutdown requests, idle notifications, plan approvals). |

### Two Levels of Multi-Agent Execution

1. **Subagents (Task tool)** -- Short-lived, synchronous or background. Returns a result directly. No team membership. Best for focused, one-off work.

2. **Teammates (Task + team_name + name)** -- Long-lived, persistent. Joins a team, communicates via inboxes, claims tasks from a shared queue. Best for ongoing parallel collaboration.

| Aspect | Subagent | Teammate |
|--------|----------|----------|
| Lifespan | Until task complete | Until shutdown requested |
| Communication | Return value | Inbox messages |
| Task queue access | None | Shared task list |
| Coordination | One-off | Ongoing |

---

## 2. Orchestration Patterns

### Pattern 1: Fan-Out / Fan-In (Parallel Specialists)

Multiple specialist agents work on the same artifact simultaneously. The leader fans work out, collects results, and synthesizes.

**When to use:** Code review, security audits, multi-dimensional analysis where concerns are independent.

```
Leader
  |---> Security Reviewer   --\
  |---> Performance Reviewer ----> Leader synthesizes
  |---> Architecture Reviewer --/
```

**Implementation:**
- Create a team
- Spawn N specialist teammates in a single message (parallel execution)
- Each teammate works independently and sends findings to the leader's inbox
- Leader reads inbox, synthesizes, shuts down teammates, cleans up

**Key advantage:** Wall-clock time equals the slowest reviewer, not the sum of all reviews.

### Pattern 2: Pipeline (Sequential Dependencies)

Stages execute in order, each building on the previous stage's output.

**When to use:** Workflows with natural ordering -- research before planning, planning before implementation, implementation before testing.

```
Research --> Plan --> Implement --> Test --> Review
```

**Implementation:**
- Create tasks with `addBlockedBy` dependencies
- Spawn workers for each stage
- Tasks auto-unblock as dependencies complete
- Workers poll for unblocked tasks

### Pattern 3: Self-Organizing Swarm (Work Queue)

Workers grab available tasks from a shared pool with no predetermined assignment.

**When to use:** Many independent, similarly-scoped tasks (e.g., reviewing N files, processing N modules).

```
Task Pool: [File1, File2, File3, File4, File5]
Worker 1 grabs File1, File3, File5
Worker 2 grabs File2, File4
(natural load balancing)
```

**Implementation:**
- Create N independent tasks (no dependencies)
- Spawn M workers with identical prompts: "check TaskList, claim pending tasks, complete them, repeat"
- Workers race to claim tasks, naturally load-balancing
- Faster workers complete more tasks

### Pattern 4: Research + Implementation

Synchronous research phase feeds into implementation. A two-stage fan-out.

```
Research (sync, returns result)
  |
  v
Implementation (uses research as context)
```

### Pattern 5: Plan Approval Workflow

An architect agent produces a plan that requires leader approval before any worker proceeds with implementation.

**When to use:** High-stakes changes where human-in-the-loop or leader review is essential before execution.

### Pattern 6: Coordinated Multi-File Refactoring

Workers own non-overlapping file boundaries. A final worker handles integration tasks that depend on all refactors completing.

```
Worker A: Refactor Model (files: model/*.rb)
Worker B: Refactor Controller (files: controller/*.rb)
Worker C: Update Tests (blocked by A AND B)
```

---

## 3. How Agents Coordinate

### Communication Mechanisms

1. **Inbox messages** -- JSON files on disk. Each agent has an inbox file. Supports text messages and structured types (shutdown_request, idle_notification, task_completed, plan_approval_request, join_request, permission_request).

2. **Shared task list** -- JSON files per task with status, owner, blockedBy, and blocks fields. Automatic unblocking when dependencies complete.

3. **Return values** -- For subagent (non-teammate) Tasks, the result is returned directly to the caller.

### Handoff Patterns

- **Leader-to-worker:** Spawn with a detailed prompt containing all necessary context. The prompt IS the handoff.
- **Worker-to-leader:** Send findings via `Teammate({ operation: "write", target_agent_id: "team-lead", value: "..." })`.
- **Worker-to-worker:** Indirect via task dependencies (completing a task unblocks the next) or direct messaging.
- **Broadcast:** Send to all teammates at once. Use sparingly -- sends N separate messages.

### Lifecycle

```
1. Create Team
2. Create Tasks (with dependency graph)
3. Spawn Teammates
4. Work (claim tasks, execute, complete)
5. Coordinate (messages, dependency unblocking)
6. Shutdown (requestShutdown -> approveShutdown)
7. Cleanup (remove team resources)
```

---

## 4. Context Window Pressure Reduction

Swarms address the fundamental constraint of LLM context windows:

1. **Divide context by concern.** A security reviewer only needs security-relevant files in context, not the entire codebase architecture.

2. **Parallel exploration.** Instead of one agent sequentially reading 50 files, 5 agents each read 10 files simultaneously.

3. **Specialized prompts.** Each worker receives only the instructions relevant to its task, not the full system prompt for all possible tasks.

4. **Result compression.** Workers send back summaries/findings, not raw context. The leader synthesizes compressed outputs rather than holding all raw data.

5. **Disposable agents.** When a worker finishes, its context is discarded. Only the result persists via inbox messages.

---

## 5. Task Decomposition Strategies

### Decompose by Concern (Fan-Out)
Split work along domain boundaries: security, performance, architecture, style.

### Decompose by File/Module (Swarm)
Split work by file, directory, or module boundary. Each unit is independent.

### Decompose by Phase (Pipeline)
Split work into sequential phases: research, plan, implement, test, review.

### Decompose by Dependency Graph (DAG)
Create a directed acyclic graph of tasks. Some run in parallel (no shared dependencies), others wait.

### Principles for Good Decomposition

- Each task should be **completable independently** or have explicit dependencies.
- Tasks should have **clear boundaries** -- no two workers editing the same file.
- Tasks should be **right-sized** -- small enough for focused context, large enough to avoid coordination overhead.
- Include **explicit output expectations** in every task description.

---

## 6. Agent Types and Specialization

Match agent type to task requirements:

| Agent Type | Tools Available | Best For |
|------------|----------------|----------|
| **Explore** | Read-only tools | Codebase search, file discovery, analysis |
| **Plan** | Read-only tools | Architecture design, implementation planning |
| **Bash** | Bash only | Git operations, CLI commands, system tasks |
| **general-purpose** | All tools | Implementation, multi-step work |
| **Specialized reviewers** | Domain-specific | Security audit, performance analysis, style review |

Use the lightest agent type that can accomplish the task. `Explore` with `model: "opus"` for searches. `general-purpose` only when write access is needed.

---

## 7. Error Handling and Recovery

### Crashed Workers
- Workers have a 5-minute heartbeat timeout
- After timeout, the worker is marked inactive
- Their uncompleted tasks remain in the task list and can be reclaimed by other workers

### Graceful Shutdown
Always follow the sequence: requestShutdown -> wait for approveShutdown -> cleanup. Cleanup will fail if active members exist.

### Retry Logic
Build retry into worker prompts: "If a task fails, re-attempt once before marking as failed and notifying the leader."

### Task Reclamation
When a worker crashes, its claimed tasks retain their status. The leader or another worker can reassign them.

### Debugging
- Read team config: `~/.claude/teams/{team}/config.json`
- Read inboxes: `~/.claude/teams/{team}/inboxes/{agent}.json`
- Check task states: `~/.claude/tasks/{team}/*.json`

---

## 8. When to Use Swarms vs Single Agent

### Use a Single Agent When:
- The task is small and focused (under 10 minutes of work)
- Sequential reasoning is required throughout (each step depends on all prior steps)
- The context fits comfortably in one window
- Coordination overhead would exceed time saved
- The task involves editing a single file

### Use a Swarm When:
- Multiple independent concerns can be addressed in parallel
- The codebase is large enough that context window pressure is a factor
- You need specialist perspectives (security + performance + architecture)
- The work naturally decomposes into independent units
- Wall-clock time matters and parallelism provides speedup
- A pipeline of phases (research -> plan -> implement -> test) maps cleanly to separate agents

### Use Subagents (No Team) When:
- You need a quick, focused result (file search, single analysis)
- The work is fire-and-forget with a return value
- No inter-agent communication is needed

### Use Teammates (Full Team) When:
- Multiple agents need to coordinate over time
- A shared task queue with dependencies is needed
- Workers need to communicate findings to each other or the leader
- The workflow has a defined lifecycle (setup, work, teardown)

---

## 9. Execution Backends

| Backend | Visibility | Speed | Persistence | Environment |
|---------|------------|-------|-------------|-------------|
| **in-process** | Hidden | Fastest | Dies with leader | Default (non-tmux) |
| **tmux** | Visible panes | Medium | Survives leader exit | tmux session |
| **iterm2** | Side-by-side panes | Medium | Dies with window | macOS + iTerm2 |

Auto-detection: tmux env var -> iTerm2 detection -> tmux available -> fallback to in-process.

For CI/headless environments, `in-process` is the default and works without additional setup.

---

## 10. Best Practices Summary

1. **Always clean up teams.** Orphaned teams waste resources and cause conflicts.
2. **Use meaningful agent names.** `security-reviewer` not `worker-1`.
3. **Write detailed prompts.** The prompt is the only context the worker receives. Be explicit about what to do, what to output, and how to communicate results.
4. **Use task dependencies over manual polling.** Let the system manage unblocking.
5. **Prefer `write` over `broadcast`.** Broadcast is O(N) messages. Target communication.
6. **Match agent type to task.** Use Explore for read-only work, general-purpose only when writes are needed.
7. **Build retry logic into worker prompts.** Workers can crash; make them resilient.
8. **Keep tasks right-sized.** Too small = coordination overhead. Too large = context pressure returns.
9. **Avoid file conflicts.** Never have two workers editing the same file simultaneously.
10. **Synthesize at the leader level.** Workers report findings; the leader integrates them into a coherent result.

---

## 11. Applying Swarms to This Repository

This repository already uses swarm-adjacent patterns:

- **`/review-tf-design`** runs parallel subagent reviews (security advisor + code quality judge) in a fan-out pattern.
- **`tf-e2e-tester`** orchestrates a sequential pipeline (specify -> clarify -> plan -> review -> tasks -> analyze -> implement -> deploy -> report) as a single-agent workflow that could be decomposed into a pipeline swarm.

### Potential Swarm Applications

1. **Parallel module validation:** When implementing infrastructure, spawn subagents to simultaneously search private/public registries for all required modules.
2. **Multi-reviewer design review:** Extend `/review-tf-design` to use full TeammateTool teams with shared task lists instead of simple parallel subagents.
3. **Parallel Terraform validation:** Fan out `terraform validate`, security scanning, and style checking across separate agents.
4. **Implementation decomposition:** For multi-resource deployments, assign each resource module to a separate worker with file-boundary isolation.

---

---

## Sources

- [Claude Code TeammateTool and Task System Documentation (Gist)](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
