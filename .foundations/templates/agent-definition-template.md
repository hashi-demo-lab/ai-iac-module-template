---
# =============================================================================
# AGENT DEFINITION TEMPLATE
# =============================================================================
# Place in: .claude/agents/{agent-name}.md
#
# YAML Frontmatter Rules:
#   - name: lowercase letters, numbers, hyphens only (max 64 chars)
#   - description: WHAT it does + WHEN to use it (max 1024 chars)
#   - model: opus | sonnet | haiku (choose based on task complexity)
#   - skills: reference external skills for detailed patterns (progressive disclosure)
#   - tools: only list tools the agent actually needs
# =============================================================================

name: agent-name
description: |
  [One sentence: WHAT this agent does].
  [One sentence: WHEN to use it / trigger conditions].
model: opus
color: blue
skills:
  - skill-name-here
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Agent Title

[1-2 sentence summary explaining the agent's purpose and value. Focus on the transformation: what input does it take, what output does it produce?]

## Workflow

1. **[Phase Name]**: [What happens in this step]
2. **[Phase Name]**: [What happens in this step]
3. **[Phase Name]**: [What happens in this step]

## Output

- **Location**: `path/to/output/file.md`
- **Format**: [Brief description of output structure]
- **Template**: [Reference to template file if applicable]

## Constraints

<!--
IMPORTANT: Consolidate ALL rules here. Do not duplicate constraints
across multiple sections (e.g., avoid separate "Critical Requirements"
and "Constraints" sections with overlapping content).
-->

- [Constraint 1: What the agent must NOT do]
- [Constraint 2: Boundaries and limitations]
- [Constraint 3: Quality requirements]

## Examples

**Good**:
```
[Example of correct agent behavior or output]
```

**Bad**:
```
[Example of incorrect behavior to avoid]
```

## Context

$ARGUMENTS
