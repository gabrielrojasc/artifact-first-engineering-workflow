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
2. Set up the implementation workspace (see below).
3. Read the files and docs named by the current phase.
4. Confirm repo order, ownership, and dependency expectations.
5. Reuse the version-grounded references from the plan when framework or library behavior matters.
6. Before editing code, state in the status artifact: the approach (one sentence) and the most likely failure mode (one sentence).
7. Implement one phase at a time. All edits happen in the worktree copies, not in the repos root.
8. Run automated verification before advancing.
9. Record manual verification separately.
10. Route back to planning or research when reality diverges beyond bounded detail drift.
11. Before closing implementation, decide whether the work surfaced durable knowledge that belongs in repo-local docs; update those docs when the answer is yes.

### Implementation Workspace Setup

Before editing any code, run the installed `af-implement` helper script to create the initiative folder and worktrees. The script is idempotent: if the initiative folder already exists (e.g., created during planning or research), it reuses the existing folder and sequence number and only creates missing worktrees.

The helper processes repo fetch and worktree creation in parallel, so setup time stays reasonable for larger multi-repo checkouts.

```bash
$HOME/.agents/skills/af-implement/scripts/init-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  --worktrees-root <WORKTREES_ROOT> \
  [--branch-prefix feature] \
  <initiative-name> [ticket-key]
```

If worktrees for this initiative already exist (e.g., resuming from a handoff), verify they are up to date with the remote default branch and skip creation.

All implementation happens inside `<worktrees-root>/NNNN/<repo>/`, not in the repos root.

## Mismatch Policy

- Bounded code or detail drift -> continue implementation and record the exact delta in the phase status artifact.
- Meaningful scope or behavior mismatch -> return to planning and revise the plan.
- Ownership, boundary, or dependency mismatch -> return to research.

Bounded detail drift means the approved goal, ownership, contract surface, rollout order, and risk level still hold even if file layout, exact diff shape, or nearby code changed.

Do not silently absorb meaningful mismatches into implementation.

### Drift Decision Gate

When implementation reality differs from the plan, answer these five questions in order. If any answer is NO, stop at that level.

1. **Is the approved goal unchanged?** Same user-visible outcome, same problem being solved. NO -> return to planning.
2. **Is ownership unchanged?** Same repo, same team, same service owns the behavior. NO -> return to research.
3. **Is the contract surface unchanged?** Same API schemas, event shapes, config contracts. NO -> return to planning.
4. **Is the rollout order unchanged?** Same deployment sequence, same dependency direction. NO -> return to planning.
5. **Is the risk level unchanged?** No new failure modes, no broader blast radius. NO -> return to planning.

All YES -> bounded detail drift. Continue implementation and record the exact delta in the phase status artifact.

Examples of bounded drift: file renamed, function moved to a different module, YAML gained extra unrelated entries, nearby code refactored, test helper signature changed.

Examples that are NOT bounded drift: new required field in a shared schema, deployment target changed from canary to full rollout, service ownership transferred to a different team, a dependency was replaced.

### Contract vs Detail

A **contract change** is any modification to a surface consumed by code outside the immediate change scope:

- API request/response schemas
- Event payload shapes
- Database schemas read by other services
- Config formats consumed by other repos
- Public module exports used by other packages

A **detail change** is a modification contained within the implementation boundary:

- Internal function signatures
- Private module structure
- Local variable naming
- Internal data transformations not exposed externally
- Test-only helpers

When unsure whether a change is contract or detail, treat it as contract.

### Version Drift

When a dependency version has changed since planning:

- Version change does not affect the planned contract surface or behavior -> bounded drift. Record the version delta and continue.
- Version change introduces breaking API changes that affect the planned implementation -> return to planning with updated implementation references.
- Version change affects ownership or deployment requirements -> return to research.

### Cumulative Drift

Individual deltas may each pass the drift decision gate, but accumulated drift can make the plan unreliable as a whole. After recording **three or more** plan deltas within a single phase, pause and re-evaluate the phase against the original plan goal. If the accumulated deltas collectively change the approach, return to planning even though each delta was individually bounded.

### Stuck-State Gate

Before each action, check sequentially:

1. **Are the last 3+ actions identical?** (e.g., re-running the same failing test without changes, reading the same file again) YES -> stop, articulate why you are stuck, and choose a materially different approach. NO -> continue to 2.
2. **Are the last actions a repeating cycle?** (e.g., editing file A, then file B, then file A again without progress) YES -> stop, articulate why, and choose a materially different approach. NO -> continue.

## State Handling

- If the plan already captures enough status, keep state there.
- If the work is complex, branching, or cross-repo, keep coordination state in `workflow-state.md`.
- Default status artifacts to `<CONTEXT_ROOT>/active/NNNN_<clear-initiative>[_<ticket-key>]/status/`.
- Use repo-local `docs/` for durable knowledge distilled from the implementation, not as the default home for execution status.

## Close-Out Distillation Gate

Before implementation is considered complete, answer these questions in the status artifact:

1. Did the work surface durable knowledge that will help future engineers or agents?
2. If yes, does that knowledge belong in repo-local `docs/`?
3. If yes, has that knowledge been distilled into the right repo-local doc before close-out?

If question 1 is no, no doc update is required. If question 1 is yes, implementation is not complete until the durable knowledge is captured in the right long-term location.

## Rules

- Follow the plan phase by phase.
- Keep changes grouped by phase and repo.
- Separate automated verification from manual verification every time.
- Preserve artifact quality so another agent can resume cleanly.
- Use shared `engineering-context` layouts for active execution artifacts and repo-local docs for durable knowledge consistently.
- Do not explore alternative approaches during implementation. If the plan does not match reality, use the drift decision gate to route back to planning rather than improvising.

## Verification Recovery Protocol

When automated verification fails, before retrying:

1. State exactly what failed and the observed vs expected behavior.
2. State the root cause -- why the failure happened, not just what failed.
3. Make the corrected change based on that root cause.

**Retry budget**: original attempt + up to 2 retries (3 total). Before retry 2, the hypothesis must be materially different from retry 1. If all 3 attempts fail, stop and return to planning with the failure evidence.

Record each attempt number and what changed in the status artifact.

## Execution Context

When running **autonomously** (no human in the loop):

- Commit to reasonable defaults instead of stopping to ask clarifying questions.
- Use the drift decision gate mechanically. If all five answers are YES, continue without confirmation.
- When a judgment call is genuinely ambiguous, prefer the conservative route (return to planning) over guessing.
- Record every decision and its reasoning in the status artifact so a human reviewer can audit after the fact.

When running **interactively** (human available):

- Use the drift decision gate first. Only escalate to the human if the gate produces a borderline result.
- Prefer a short, specific question over an open-ended one.

## Output

- Use `references/status-template.md` for phase updates.
- Use `references/mismatch-template.md` when implementation must route back to planning or research.
- Close implementation only after recording whether durable knowledge was distilled into repo-local docs.
