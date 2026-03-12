# Workflow Examples

These examples are intentionally small. The point is to show when to stay in PI, when to escalate to RPI, and when implementation should route back to planning or research.

## Example 1: Small PI Change

Task: add a missing timeout to one HTTP client in a single service repo.

Recommended path:

1. `af-plan` produces a mini-plan in the repo's `docs/exec-plans/active/`.
2. The plan lists the target files, automated checks, and manual verification.
3. `af-implement` executes the change.
4. The completed plan moves to `docs/exec-plans/completed/` if the repo treats even small plans as durable records.

Why PI fits:

- single repo
- low ambiguity
- no cross-service contract change
- rollout is simple

## Example 2: Cross-Repo RPI Change

Task: add a new header requirement between an API gateway repo and two downstream service repos.

Recommended path:

1. `af-research` runs in boundary tracing mode and writes a research artifact under `engineering-context/active/header-rollout_GATE-123/research/`.
2. The research identifies the owning repo for the header contract, the downstream consumers, and the rollout constraints.
3. `af-plan` creates a phased RPI plan under `engineering-context/active/header-rollout_GATE-123/plans/`.
4. The plan separates producer-first and consumer rollout steps and records automated and manual verification.
5. `workflow-state.md` is added because the work spans multiple repos and rollout coordination matters.
6. `af-implement` executes one phase at a time and updates the status artifact.

The important naming rule is that the initiative stays readable at a glance and the ticket key stays secondary.

Why RPI fits:

- cross-repo contract impact
- explicit ownership and rollout questions
- multi-phase deployment order

## Example 3: Implementation Returns To Planning Or Research

Task: implement an event schema extension that was planned as a two-repo change.

What happens:

1. `af-implement` starts phase 1 and discovers the emitting service is not the real schema owner.
2. If the mismatch is only a code-detail mismatch, the workflow returns to planning to revise the phase sequence.
3. If the mismatch shows that ownership or dependency understanding was wrong, the workflow returns to research.
4. A new research pass documents the actual schema owner, lagging consumers, and rollout constraints.
5. Planning resumes only after the ownership gap is closed.

This is the key discipline:

- code or detail mismatch -> back to planning
- ownership, boundary, or dependency mismatch -> back to research

## Pattern Summary

- Use PI for small, low-ambiguity, mostly single-repo work.
- Use RPI for cross-repo work where contracts, rollout order, or ownership matter.
- Add another research pass whenever planning or implementation reveals weak evidence.
