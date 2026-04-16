---
name: af-iterate
description: apply targeted revisions to an existing artifact-first plan through conversational alignment. use when the plan structure is still valid but specific sections need updating, as opposed to a full re-plan triggered by implementation mismatch.
---

# Artifact-First Iterate

## Overview

Refine an existing plan through conversation. The human states an intent, the agent and human talk it through until the change is clear and agreed upon, and only then does the agent apply edits to the plan artifact.

Distinct from re-planning after implementation (`I -> P`): af-iterate handles cases where the plan is structurally sound but needs targeted revisions before or during implementation. `I -> P` re-planning handles cases where implementation discovered the plan was wrong.

## Workflow

### 1. Understand the intent

Read the existing plan completely, then listen to the human's change intent. Restate what you understand the intent to be and what parts of the plan it touches. Do not propose edits yet.

### 2. Talk it through

Have a focused conversation to reach alignment on the change. This is the core of the skill -- most of the work happens here, not in the edit step.

- Surface ambiguities, trade-offs, and downstream effects as questions.
- If the intent could be interpreted multiple ways, present the options concisely with pros/cons.
- If the change requires new evidence (ownership, boundaries, contracts), delegate inline research to sub-agent(s) following af-research principles and bring findings back into the conversation.
- Keep each exchange short. State your read, ask a specific question, and wait.
- Do not accumulate a long list of proposed changes silently. Surface each decision point as you reach it.

The conversation continues until both sides agree on what changes to make and why.

### 3. Confirm before editing

Before touching the plan artifact, summarize the agreed changes in a compact list:

- What sections change and how.
- What stays the same.
- Whether any completed phases need re-verification.

Get explicit confirmation to proceed.

### 4. Apply and record

Edit only the agreed sections of the plan. Preserve everything else. Add a revision history entry.

## Scope Assessment

Early in the conversation, classify the change:

- **Additive**: New requirement that extends existing phases or adds a new phase. Existing phases are preserved.
- **Corrective**: Feedback that refines approach, constraints, or verification criteria within existing phases.
- **Invalidating**: Change that undermines assumptions of completed phases. Mark affected completed phases for re-verification or re-implementation.

If the conversation reveals that most phases need rewriting, recommend a full re-plan with af-plan instead of continuing to iterate.

## Rules

- Do not edit the plan until alignment is reached and confirmed.
- Do not re-plan from scratch. If the plan needs a full rewrite, route to af-plan.
- Do not change completed phases unless the feedback specifically invalidates them.
- Preserve the plan's existing design decisions unless the conversation explicitly overrides them.
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
