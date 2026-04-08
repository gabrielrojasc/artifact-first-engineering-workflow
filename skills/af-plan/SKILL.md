---
name: af-plan
description: create mini-plans for `PI` (`Plan -> Implement`) work and phased plans for `RPI` (`Research -> Plan -> Implement`) work in an artifact-first engineering workflow, using QRSPI-style interactive alignment and inline research when needed. use when an agent must turn a task or research artifact into an actionable plan while routing into more research if ownership, repo scope, contract dependencies, or rollout dependencies are still unclear.
---

# Artifact-First Plan

## Overview

Turn a task or research artifact into a decision-complete implementation plan. Planning follows a QRSPI-style flow: Questions, Research when needed, Design discussion, Structure approval, and then the written plan. `PI` and `RPI` are still path labels for the resulting plan shape. The workflow is conditional:

- use a mini-plan for `PI` (`Plan -> Implement`) work
- use a phased plan for `RPI` (`Research -> Plan -> Implement`) work

Planning should not paper over unclear ownership or weak evidence.

## Workflow

1. Read the task and any research artifacts fully.
2. If no prior research artifact exists and ownership, boundaries, or contracts are unclear, delegate inline research (see below).
3. Verify the repo set, ownership, contracts, and rollout constraints.
4. Carry forward any version-grounded framework or library references needed for implementation, or gather them directly for PI work when research does not exist.
5. Run Interactive Alignment (see below).
6. Decide whether the work is PI or RPI. Produce the smallest plan shape that fits the risk.
7. Separate automated verification from manual verification.

## Interactive Alignment

Three mandatory steps before writing the plan.

**Questioning**: Present your informed understanding of the task and surface design decisions as explicit options (Q1: A or B? Q2: X or Y?). Do not proceed until the human selects directions.

**Design Discussion**: Present current state, desired end state, discovered patterns, and design options with pros/cons in-chat. The human picks the direction. Resolved decisions get recorded in the plan's Design decisions section.

**Structure Approval**: Present a plan outline with phased breakdown and get explicit approval before writing the full plan. For mini-plans, present the intended edits and verify scope.

## Planning Modes

`PI` and `RPI` are planning path labels, not substitutes for the interactive alignment steps above.

Choose `mini-plan` when:

- the task is small
- the task is mostly single-repo
- ambiguity is low
- there is no cross-service contract change
- rollout sequencing is simple

Choose `full phased plan` when:

- the task is cross-repo
- contracts may change
- rollout safety matters
- ownership or boundaries matter
- the task is ambiguous

### Size Heuristics

When "small" is ambiguous, use these indicators:

Mini-plan indicators (any three suggest mini-plan):

- Fewer than ~5 files changing
- Single repo
- No schema or contract change
- No rollout sequencing beyond "deploy and verify"
- Estimated risk is low (failure is local and recoverable)
- No ownership ambiguity

Phased plan indicators (any one suggests phased plan):

- Multiple repos
- Any shared schema, API, or event contract changes
- Rollout must happen in a specific order
- Multiple teams or ownership boundaries involved
- Failure could cascade beyond the immediate change
- Significant ambiguity in scope or approach

Common workflow paths include `PI`, `RPI`, `R -> R -> P -> I`, `P -> R -> P -> I`, `I -> P`, and `I -> R`.

These are recommended patterns, not an exhaustive set of allowed transitions.

### Re-Planning After Implementation Feedback

When returning from implementation to planning (`I -> P` or `I -> R -> P`):

- Read the mismatch artifact and all phase status artifacts from the prior implementation pass.
- Preserve completed phases as-is unless the mismatch invalidates their results.
- Revise only the affected phases.
- Carry forward deltas recorded during bounded drift into the revised plan so the plan reflects actual state.
- Note in the plan that this is a revision and reference the prior plan artifact.

## Inline Research

When no prior research artifact exists and ownership, boundaries, or contracts are unclear:

- Delegate research to sub-agent(s) using af-research skill. Each delegation should have a clear question and bounded scope.
- The main agent synthesizes findings and proceeds to Interactive Alignment.
- If research surfaces blockers requiring human input (e.g., cannot determine ownership, conflicting evidence), surface those in the Questioning step rather than stopping silently.

Standalone af-research remains the right tool for pure discovery, audits, or when a research artifact is explicitly desired without planning.

## State Placement

- Simple work: keep state inside the plan itself.
- Complex multi-repo or branching work: add `workflow-state.md` in the shared initiative folder.
- Name shared initiative folders with a sequence number and the clear initiative: `NNNN_<clear-initiative>_<ticket-key>` when a ticket exists, otherwise `NNNN_<clear-initiative>`.
- `NNNN` is a zero-padded sequence number. Scan both `active/` and `archive/` for the highest existing number and increment by one.
- Keep any ticket key as a suffix only, and reuse the same clear initiative phrase in the plan title.
- Store plan artifacts under `<CONTEXT_ROOT>/active/NNNN_<clear-initiative>[_<ticket-key>]/plans/` for both single-repo and cross-repo work.
- Treat repo-local `docs/` as durable knowledge storage, not the default location for execution plans.

Keep `workflow-state.md` small and coordination-oriented.

## Output

- Use `references/mini-plan-template.md` for PI work.
- Use `references/phased-plan-template.md` for RPI work.
- Use `references/research-request-template.md` only when inline research still leaves planning-blocking truth gaps.

## Rules

- Plans are first-class artifacts.
- Prefer small, testable phases with explicit pause points.
- Record what is automated verification versus manual verification.
- When implementation depends on framework or library behavior, include the detected version and official docs the implementer should rely on.
- If rollout order matters, say so explicitly.
- Follow repo-local durable-docs and shared-context execution layouts instead of inventing ad hoc locations.
