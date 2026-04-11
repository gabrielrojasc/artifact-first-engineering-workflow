# Workflow Examples

These examples are intentionally small. The point is to show when to stay on the lighter PI path, when to take the research-backed RPI path, and how QRSPI-style planning fits before implementation.

## Example 1: Small PI Path

Task: add a missing timeout to one HTTP client in a single service repo.

Recommended path:

1. `af-plan` runs a light Questioning, Design Discussion, and Structure Approval pass, writes a mini-plan proposal under `engineering-context/active/0001_http-client-timeout/plans/`, gets approval, and then writes the final mini-plan.
2. The proposal and final plan include a Mermaid sequence diagram when it helps explain the request flow or responsibility handoff. Both artifacts also list the target files, any version-sensitive library docs the implementer should trust, automated checks, and manual verification.
3. `af-implement` creates worktrees under `<worktrees-root>/0001/` for every repo except the configured context repo, executes the change, and records phase status under `engineering-context/active/0001_http-client-timeout/status/`.
4. If the change surfaced no durable repo knowledge beyond the implementation itself, no repo-local docs update is required at close-out.

Why the PI path fits:

- single repo
- low ambiguity
- no cross-service contract change
- rollout is simple

## Example 2: Cross-Repo RPI Path

Task: add a new header requirement between an API gateway repo and two downstream service repos.

Recommended path:

1. `af-plan` receives the task and sees that repo ownership, contract boundaries, and rollout order are still unclear.
2. `af-plan` delegates bounded `af-research` work, which writes a research artifact under `engineering-context/active/0002_header-rollout_GATE-123/research/`.
3. The research identifies the owning repo for the header contract, the downstream consumers, the rollout constraints, and any version-sensitive framework behavior that needs official docs.
4. `af-plan` then runs Questioning, Design Discussion, and Structure Approval with the human, writes a phased proposal under `engineering-context/active/0002_header-rollout_GATE-123/plans/`, gets approval, and then writes the phased RPI plan.
5. The proposal and final plan include a Mermaid sequence diagram when it clarifies the rollout or interaction flow. The final plan separates producer-first and consumer rollout steps and records automated and manual verification.
6. `workflow-state.md` is added because the work spans multiple repos and rollout coordination matters.
7. `af-implement` creates worktrees under `<worktrees-root>/0002/` for every repo except the configured context repo, executes one phase at a time, and updates the status artifact under `engineering-context/active/0002_header-rollout_GATE-123/status/`.
8. Close-out distills any lasting gateway or service rollout knowledge into the relevant repo docs before the work is considered complete.

The important naming rule is that the initiative stays readable at a glance and the ticket key stays secondary.

Why the RPI path fits:

- cross-repo contract impact
- explicit ownership and rollout questions
- multi-phase deployment order

## Example 3: Implementation Returns To Planning Or Research

Task: implement an event schema extension that was planned as a two-repo change.

What happens:

1. `af-implement` starts phase 1 and notices the repo has changed since planning.
2. If the drift is only local implementation detail, such as a YAML file now having extra entries or code moving nearby, implementation continues and the phase status records the plan delta.
3. If the mismatch changes the intended behavior, scope, or rollout sequence, the workflow returns to planning to revise the plan.
4. If the mismatch shows that ownership or dependency understanding was wrong, the workflow returns to research.
5. A new research pass documents the actual schema owner, lagging consumers, and rollout constraints.
6. Planning resumes only after the ownership gap is closed.

This is the key discipline:

- bounded code or detail drift -> continue and record the delta
- meaningful scope or behavior mismatch -> back to planning
- ownership, boundary, or dependency mismatch -> back to research

## Pattern Summary

- Use the PI path for small, low-ambiguity, mostly single-repo work.
- Use the RPI path for cross-repo work where contracts, rollout order, or ownership matter.
- `af-plan` uses QRSPI-style planning in both cases; the difference is whether the result is a lighter mini-plan or a phased plan.
- Use standalone `af-research` for pure discovery or audit work when you want a research artifact before any planning step.
- Keep active research, plans, and status artifacts under the shared context root by default, and update repo-local docs only when completed work reveals durable knowledge worth preserving.
- Ground framework or library behavior in repo-detected versions and official docs when the repo alone is not enough.
- Add another research pass whenever planning or implementation reveals weak evidence.
