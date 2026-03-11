---
name: distributed-plan
description: create mini-plans for PI work and phased plans for RPI work in distributed systems. use when an agent must turn a task or research artifact into an actionable plan while stopping for more research if ownership, repo scope, contract dependencies, or rollout dependencies are still unclear.
---

# Distributed Plan

## Overview

Turn a task or research artifact into a decision-complete implementation plan. The workflow is conditional:

- use a mini-plan for PI work
- use a phased plan for RPI work

Planning should not paper over unclear ownership or weak evidence.

## Workflow

1. Read the task and any research artifacts fully.
2. Verify the repo set, ownership, contracts, and rollout constraints.
3. Decide whether the work is PI or RPI.
4. Produce the smallest plan shape that fits the risk.
5. Separate automated verification from manual verification.
6. If key dependencies are unclear, stop and emit a research request.

## Planning Modes

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

Common workflow paths include `PI`, `RPI`, `R -> R -> P -> I`, `P -> R -> P -> I`, `I -> P`, and `I -> R`.

These are recommended patterns, not an exhaustive set of allowed transitions.

## Research Stop Condition

Do not emit a final plan if any of these remain unclear:

- repo set
- ownership boundary
- contract dependencies
- rollout dependencies

In that case, emit a research request using `references/research-request-template.md` and stop.

## State Placement

- Simple work: keep state inside the plan itself.
- Complex multi-repo or branching work: add `workflow-state.md` in the shared initiative folder.

Keep `workflow-state.md` small and coordination-oriented.

## Output

- Use `references/mini-plan-template.md` for PI work.
- Use `references/phased-plan-template.md` for RPI work.
- Use `references/research-request-template.md` when planning is blocked by missing truth.

## Rules

- Plans are first-class artifacts.
- Prefer small, testable phases with explicit pause points.
- Record what is automated verification versus manual verification.
- If rollout order matters, say so explicitly.
- Follow repo-local and shared-context layouts instead of inventing ad hoc locations.
