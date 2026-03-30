---
name: af-iterate
description: apply targeted revisions to an existing artifact-first plan based on feedback or changed requirements. use when the plan structure is still valid but specific sections need updating, as opposed to a full re-plan triggered by implementation mismatch.
---

# Artifact-First Iterate

## Overview

Surgically update an existing plan based on feedback or changed requirements. The plan remains the control artifact -- iteration refines it without discarding the structure or completed work.

Distinct from re-planning after implementation (`I -> P`): af-iterate handles cases where the plan is structurally sound but needs targeted revisions before or during implementation. `I -> P` re-planning handles cases where implementation discovered the plan was wrong.

## Workflow

1. Read the existing plan completely.
2. Read the feedback or change request.
3. Identify which sections of the plan are affected by the change.
4. Assess whether the change requires new research:
   - If ownership, boundaries, or contracts are now unclear, delegate inline research to sub-agent(s) following af-research principles.
   - If the change is scoped within already-researched territory, proceed without new research.
5. Update only the affected sections of the plan.
6. Preserve completed phases unless the change invalidates their results.
7. If the change affects phases that are already complete, note what needs re-verification.
8. Record the iteration in the plan's revision history.

## Scope Assessment

Before editing, classify the change:

- **Additive**: New requirement that extends existing phases or adds a new phase. Existing phases are preserved.
- **Corrective**: Feedback that refines approach, constraints, or verification criteria within existing phases.
- **Invalidating**: Change that undermines assumptions of completed phases. Mark affected completed phases for re-verification or re-implementation.

If the change is so broad that most phases need rewriting, recommend a full re-plan with af-plan instead of iterating.

## Rules

- Do not re-plan from scratch. If the plan needs a full rewrite, route to af-plan.
- Do not change completed phases unless the feedback specifically invalidates them.
- Preserve the plan's existing design decisions unless the feedback explicitly overrides them.
- When adding or modifying phases, maintain the same structure (automated verification, manual verification, file lists) as existing phases.
- Record every iteration with a short note: what changed, why, and which phases were affected.
- Keep the plan internally consistent after iteration -- cross-references, phase numbering, and exit criteria must still hold.

## Output

Update the existing plan artifact in place. Add a revision entry at the bottom of the plan or in its revision history section:

```markdown
## Revision history

- <date>: <what changed and why>
```

If the plan does not have a revision history section, add one.
