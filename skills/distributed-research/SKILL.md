---
name: distributed-research
description: analyze one or more repositories in a distributed system and produce a compact, evidence-backed research artifact before planning or implementation. use when an agent needs repo discovery, boundary tracing, contract validation, or rollout and environment validation without guessing about current system behavior.
---

# Distributed Research

## Overview

Produce a durable research artifact that documents the system as it exists today. Research is for truth gathering, not for proposing fixes too early.

Use this skill when the task involves one or more of these modes:

- repo discovery
- boundary tracing
- contract validation
- rollout or environment validation

## Workflow

1. Restate the task as a research question.
2. Identify the relevant repo set, services, contracts, and environments.
3. Read the smallest stable source-of-truth artifacts first.
4. Trace the behavior across repo and service boundaries.
5. Compact the findings into a durable Markdown artifact.
6. End with a clear readiness call and next step.

## Rules

- Document current reality, not desired architecture.
- Prefer repository-local, versioned artifacts over chat transcripts or assumptions.
- Treat `AGENTS.md` as a map, not a long manual.
- When repo boundaries or ownership are unclear, keep tracing until the uncertainty is explicit.
- When evidence is weak or conflicting, say so and rank the most reliable sources.
- Keep the output compact enough for a later planning pass to reuse directly.

## Artifact Placement

- Repo-local question: place the artifact in that repo's docs tree.
- Cross-repo question: place the artifact in the shared `engineering-context` repo under the active initiative.
- Scratch can hold temporary notes, but final findings belong in versioned Markdown.

Use the repo-local docs layout:

```text
docs/
  architecture/
  exec-plans/
    active/
    completed/
  references/
  services/
```

Use `docs/services/` only when a repo has multiple runtime or deployable components.

Use the shared cross-repo layout:

```text
engineering-context/
  active/
    <initiative>/
      workflow-state.md
      research/
      plans/
      decisions/
  archive/
  service-catalog/
  dependency-maps/
```

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
