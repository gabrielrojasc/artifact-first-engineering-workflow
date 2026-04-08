---
name: af-research
description: analyze one or more repositories and produce a compact, evidence-backed research artifact for artifact-first engineering work. use when an agent needs repo discovery, boundary tracing, contract validation, or rollout and environment validation without guessing about current system behavior.
---

# Artifact-First Research

## Overview

Produce a durable research artifact that documents the system as it exists today. Research is for truth gathering, not for proposing fixes too early.

Use this skill when the task involves one or more of these modes:

- repo discovery
- boundary tracing
- contract validation
- rollout or environment validation

### Mode Selection

Choose the starting mode based on the first question you cannot answer:

- Cannot name the repos involved -> start with **repo discovery**.
- Can name the repos but cannot trace data flow or responsibility across them -> start with **boundary tracing**.
- Can trace boundaries but need to verify a specific API, schema, or protocol -> start with **contract validation**.
- Understand the contracts but need to verify environment, deployment, or rollout constraints -> start with **rollout or environment validation**.

Combine modes when one pass reveals gaps. A repo discovery pass that uncovers unclear boundaries should continue into boundary tracing in the same research artifact rather than producing a separate pass.

## Workflow

1. Restate the task as a research question.
2. Identify the relevant repo set, services, contracts, and environments.
3. Read the smallest stable source-of-truth artifacts first, in this order:
   - `AGENTS.md` or `CODEOWNERS` for ownership and navigation
   - `README.md` for repo purpose and setup
   - Manifest files (`package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`) for dependency versions
   - Schema or contract files (OpenAPI specs, protobuf definitions, event schemas) for contract surface
   - Test files for behavior verification
   - Source code only after the above have established context
   Avoid reading source files broadly before narrowing scope through artifacts.
   If the question remains unanswered after the artifact pass, broaden once to targeted source files and tests. If still unanswered after that single broadening pass, reassess the research question or approach before broadening further.
4. Detect technology and dependency versions from repo-local manifests, lockfiles, images, and config when framework or library behavior matters.
5. Trace the behavior across repo and service boundaries.
6. Confirm external framework or library behavior against official version-matched docs when repo evidence alone is not enough.
7. Compact the findings into a durable Markdown artifact.
8. End with a clear readiness call and next step.

## Sub-Agent Delegation

When research scope is broad -- multiple repos, large codebase surface, or several disjoint questions -- delegate bounded discovery tasks to sub-agents rather than consuming the main agent's context on raw exploration.

### When to delegate

- The research question spans more than two repos or services.
- A single discovery pass would require reading more source files than the artifact-level pass (step 3) already covered.
- Multiple independent questions can be investigated in parallel.

### Delegation requirements

- Each delegation must have a clear question and a bounded scope (specific repo, specific contract, specific boundary).
- Sub-agents return compact findings, not raw file contents or broad code dumps.
- Sub-agents follow the same rules as the main research pass: document what IS, not opinions or proposals.

### Synthesis

The main agent synthesizes sub-agent findings into the research artifact. Sub-agent outputs are working material, not final artifacts. Conflicting findings across sub-agents must be reconciled or flagged as open questions before the sufficiency gate.

## Rules

- Document current reality, not desired architecture.
- Prefer repository-local, versioned artifacts over chat transcripts or assumptions.
- Prefer repo-local evidence first, then official version-matched docs for external technology behavior.
- Treat `AGENTS.md` as a map, not a long manual.
- When repo boundaries or ownership are unclear, keep tracing until the uncertainty is explicit.
- When evidence is weak or conflicting, say so and rank the most reliable sources.
- When an API or framework behavior is in question, record the detected version and the exact docs consulted instead of relying on memory.
- Keep the output compact enough for a later planning pass to reuse directly.
- If discovery is not converging after two passes through the same source area, reassess the research mode (e.g., switch from boundary tracing to contract validation) rather than continuing the same approach.

## Sufficiency Gate

A research pass is complete when **all** of the following hold:

- Every item in `references/boundary-checklist.md` has either a verified answer or an explicit "unknown -- does not block planning" note.
- The repo set is named and confirmed from direct evidence (manifests, imports, deployments), not from assumption.
- Ownership for every changed contract or behavior is attributed to a specific repo or service.
- Technology versions relevant to the task are detected from repo-local artifacts, not assumed.
- Open questions are listed, and none of them block the planning readiness call.

If any boundary checklist item is both unresolved and planning-relevant, set `Planning readiness: not ready` and list the specific gap.

## Artifact Placement

- Place final research artifacts in the shared `engineering-context` repo under the active initiative, even when the question is contained to one repo.
- Use repo-local docs as supporting evidence during research and as a destination for durable knowledge distilled from the findings when that knowledge has lasting repo value.
- Scratch can hold temporary notes, but final findings belong in versioned Markdown under the shared context root.

Name the active initiative folder with a sequence number and the clear initiative, not for the ticket alone.

- With a ticket: `NNNN_<clear-initiative>_<ticket-key>`
- Without a ticket: `NNNN_<clear-initiative>`
- `NNNN` is a zero-padded sequence number. Scan both `active/` and `archive/` for the highest existing number and increment by one.
- Keep the ticket key as a suffix only.
- Reuse the same clear initiative phrase in the research title.

Use repo-local docs for durable knowledge such as architecture notes, commands, pitfalls, and service cards:

```text
docs/
  architecture/
  references/
  services/
```

Use `docs/services/` only when a repo has multiple runtime or deployable components.

Use the shared context layout:

```text
engineering-context/
  active/
    NNNN_<clear-initiative>[_<ticket-key>]/
      workflow-state.md
      research/
      plans/
      status/
      decisions/
  archive/
  service-catalog/
  dependency-maps/
```

Use the shared-context directories as follows:

- `research/`: durable research artifacts for the active initiative
- `plans/`: approved implementation plans for the active initiative
- `status/`: implementation status artifacts and close-out records for the active initiative
- `decisions/`: initiative-local decision records when cross-repo tradeoffs need a durable record
- `service-catalog/`: stable service or component reference cards reused across initiatives
- `dependency-maps/`: durable cross-repo dependency or contract maps reused across initiatives

## Output

Write the result using `references/research-template.md`.

Every final artifact must end with these exact fields:

- `Planning readiness: ready | not ready`
- `Open questions`
- `Recommended next step`

If ownership, contracts, or rollout boundaries remain unclear, set `Planning readiness: not ready`.

## Resources

- Use `references/research-template.md` for the write-up shape.
- Use `references/boundary-checklist.md` to avoid missing ownership or dependency gaps.
