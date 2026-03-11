# Install And Use

This package is designed to be cloned, read, and copied from. It is intentionally light on tooling. The core deliverable is a repeatable artifact layout and a set of skills that teach branching PI and RPI workflows.

## Installation

1. Clone this repo into a location you control.
2. Read [`docs/home-agents-guide.md`](home-agents-guide.md) and adapt the `$HOME/AGENTS.md` snippet to your workstation.
3. Create or update `$HOME/AGENTS.md` with your chosen repo root, shared `engineering-context` root, and scratch root.
4. Copy the canonical skills from [`skills/`](../skills/) into your agent skill location.

## Installing The Skills

The canonical workflow definitions live in these folders:

- [`skills/distributed-research/`](../skills/distributed-research/)
- [`skills/distributed-plan/`](../skills/distributed-plan/)
- [`skills/distributed-implement/`](../skills/distributed-implement/)

Each skill contains:

- `SKILL.md` as the canonical workflow definition
- local `references/` files so the skill can travel independently

## Repo-Local Docs Setup

For repos where you want this workflow to work well, create or grow a local docs tree like:

```text
repo/
  docs/
    architecture/
    exec-plans/
      active/
      completed/
    references/
    services/
```

Use these directories as follows:

- `docs/architecture/`: durable repo maps, boundaries, and important design notes
- `docs/exec-plans/active/`: current repo-specific plans
- `docs/exec-plans/completed/`: completed plans worth preserving
- `docs/references/`: commands, test flows, pitfalls, glossary, local setup notes, dependency notes
- `docs/services/`: service or component cards only when the repo has multiple deployable or runtime units

Skip `docs/services/` in single-service repos.

When `docs/services/` is used, each service card should cover:

- what the service or component does
- entrypoints
- dependencies
- owned contracts
- run and test commands
- rollout quirks
- common failure modes

## Shared `engineering-context` Setup

Pick one shared repo for cross-repo work and create a shape like:

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

Use it for:

- cross-repo research
- initiative-level plans
- rollout coordination
- service catalog entries
- dependency maps
- architectural decisions

## What Ownership Means

In this workflow, ownership means the most relevant source of truth and responsibility boundary for a behavior, contract, or runtime component.

Examples:

- which repo owns a contract or schema
- which service is responsible for emitting or consuming an event
- which team or component is the authoritative place to change behavior
- whether a document belongs in repo-local docs or shared cross-repo context

If ownership is unclear, planning should stop and request more research instead of guessing where the change belongs.

## Choosing PI vs RPI

Use `PI` when:

- the task is small
- the task is mostly single-repo
- ambiguity is low
- there is no cross-service contract change
- rollout sequencing is simple

Use `RPI` when:

- the task is cross-repo
- contracts may change
- rollout safety matters
- ownership or boundaries matter
- the task is ambiguous

The workflow is conditional, not rigid. Common workflow paths include:

- `PI`
- `RPI`
- `R -> R -> P -> I`
- `P -> R -> P -> I`
- `I -> P`
- `I -> R`

These are recommended patterns, not an exhaustive set of allowed transitions.

## Running The Workflow

### Research

Use research to document the system as it exists today. Good research should leave behind a durable artifact rather than a long chat transcript.

Choose the research mode that fits the task:

- repo discovery
- boundary tracing
- contract validation
- rollout or environment validation

When the work is cross-repo, place the main artifact under the shared `engineering-context` initiative folder. When it is repo-local, keep the artifact in the repo's own docs tree.

### Plan

Use planning to turn a task or research artifact into an actionable implementation path.

- Use a mini-plan for PI work.
- Use a phased plan for RPI work.
- If ownership, repo set, contract dependencies, or rollout dependencies are unclear, stop and produce a research request instead of pretending the plan is ready.

### Implement

Implement phase by phase from an approved plan artifact.

- Keep automated verification separate from manual verification.
- If the codebase differs from plan details, return to planning.
- If ownership, boundaries, or dependency understanding is wrong, return to research.

## When To Use `workflow-state.md`

Default rule:

- simple work: keep state inside the plan
- complex, branching, or multi-repo coordination: use `workflow-state.md`

`workflow-state.md` should stay small. It tracks current mode, phase, active artifacts, open questions, next step, and overall status.

## Scratch Usage

Scratch is for:

- copied logs
- rough notes
- temporary summaries
- discarded research passes
- intermediate outputs

Scratch is not a second documentation system. If something will matter later, compact it into a versioned Markdown artifact in the repo or the shared context repo.

## Why This Layout

This package follows the same broad direction described in OpenAI's [Harness engineering](https://openai.com/index/harness-engineering) article and HumanLayer's [Advanced Context Engineering](https://www.humanlayer.dev/docs/workshop) material:

- use repository-visible artifacts instead of hidden context
- make plans durable
- keep entry points small and navigable
- compact exploration into reusable documents
- treat workflow discipline as part of the engineering system
