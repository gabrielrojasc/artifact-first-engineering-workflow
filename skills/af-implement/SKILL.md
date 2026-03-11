---
name: af-implement
description: execute an approved artifact-first plan phase by phase with explicit exits back to planning or research. use when an agent must implement from a plan, keep automated and manual verification separate, and stop clearly when code, ownership, boundary, or dependency reality diverges from the plan.
---

# Artifact-First Implement

## Overview

Execute an approved plan one phase at a time. The plan is the control artifact. Implementation should move forward only while the plan still matches reality.

Supported exits:

- continue implementation
- return to planning
- return to research

## Workflow

1. Read the approved plan completely.
2. Read the files and docs named by the current phase.
3. Confirm repo order, ownership, and dependency expectations.
4. Implement one phase at a time.
5. Run automated verification before advancing.
6. Record manual verification separately.
7. Route back to planning or research when reality diverges.

## Mismatch Policy

- Code or detail mismatch -> return to planning and revise the plan.
- Ownership, boundary, or dependency mismatch -> return to research.

Do not silently absorb meaningful mismatches into implementation.

## State Handling

- If the plan already captures enough status, keep state there.
- If the work is complex, branching, or cross-repo, keep coordination state in `workflow-state.md`.

## Rules

- Follow the plan phase by phase.
- Keep changes grouped by phase and repo.
- Separate automated verification from manual verification every time.
- Preserve artifact quality so another agent can resume cleanly.
- Use repo-local docs and shared `engineering-context` layouts consistently.

## Output

- Use `references/status-template.md` for phase updates.
- Use `references/mismatch-template.md` when implementation must route back to planning or research.
