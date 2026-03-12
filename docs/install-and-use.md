# Install And Use

This package is designed to be cloned, read, and copied from. It is intentionally light on tooling. The core deliverable is a repeatable artifact-first layout and a set of skills that teach branching `PI` (`Plan -> Implement`) and `RPI` (`Research -> Plan -> Implement`) workflows.

Here, `artifact-first` means the durable file is the source of truth. Plans, research notes, decisions, and reference docs should exist as versioned artifacts that agents and humans can reuse; chat should support those artifacts, not replace them.

## Installation

1. Clone this repo into a location you control. A git worktree checkout is fine and works well for updates.
2. From inside that checkout or worktree, run:

```bash
scripts/install.sh
```

3. Read [`docs/home-agents-guide.md`](home-agents-guide.md) and replace every placeholder in the installed `~/.codex/AGENTS.md` with your real workstation paths and conventions.
4. If the installer reports existing files or skill destinations, review the relevant docs and merge the rules manually instead of overwriting those paths.

## What The Installer Does

The installer is intentionally conservative. It uses the current repo checkout as the live source of truth so future updates to this repo are reflected through symlinks.

It will run these command types:

- `git rev-parse --show-toplevel` to detect the current repo root
- `mkdir -p` to create `~/.agents/skills/`, `~/.codex/`, and `~/.claude/` when missing
- `ln -s` to create per-skill symlinks in `~/.agents/skills/` that point back to this repo's [`skills/`](../skills/) directories
- `cp` to install [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md) as `~/.codex/AGENTS.md` if that file does not already exist
- `ln -s` to create `~/.claude/CLAUDE.md` as a symlink to `~/.codex/AGENTS.md` if it does not already exist

It will not:

- overwrite an existing `~/.codex/AGENTS.md`
- overwrite an existing `~/.claude/CLAUDE.md`
- replace an existing path under `~/.agents/skills/`

When those paths already exist, the installer prints a warning and tells you which doc to review so you can merge the workflow rules yourself.

The installed `~/.codex/AGENTS.md` is a starter file, not a finished workstation config. It still contains placeholders such as `<CHOSEN_REPOS_ROOT>`, `<CHOSEN_ENGINEERING_CONTEXT_ROOT>`, and `<CHOSEN_SCRATCH_ROOT>`. Replace them explicitly after installation.

When `~/.claude/CLAUDE.md` is created by the installer, it is intentionally a symlink to `~/.codex/AGENTS.md` so both tools read the same guidance file.

## Installing The Skills

The canonical workflow definitions live in these folders:

- [`skills/af-research/`](../skills/af-research/)
- [`skills/af-plan/`](../skills/af-plan/)
- [`skills/af-implement/`](../skills/af-implement/)

Each skill contains:

- `SKILL.md` as the canonical workflow definition
- local `references/` files so the skill can travel independently

The installer links each of these skill folders individually into `~/.agents/skills/` so unrelated skills in that directory are left alone.

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

The canonical agent-facing layout guidance lives in [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md) and [`skills/af-research/SKILL.md`](../skills/af-research/SKILL.md). For human setup, use a shared repo for cross-repo work with a shape like:

```text
engineering-context/
  active/
    <clear-initiative>[_<ticket-key>]/
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
- initiative-local decision records in `decisions/` when cross-repo tradeoffs need a durable record
- stable service or component reference cards in `service-catalog/`
- durable cross-repo dependency or contract maps in `dependency-maps/`

Name active initiative folders for the work at hand, not for the ticket alone.

- Default pattern with a ticket: `<clear-initiative>_<ticket-key>`
- Default pattern without a ticket: `<clear-initiative>`
- Keep the clear-initiative part short, readable, and understandable at a glance.
- Keep the ticket key as a suffix only when it helps traceability.

Examples:

- `header-rollout_GATE-123`
- `checkout-retry-policy_PAY-204`
- `search-ranking-tuneup`

Avoid ticket-led names such as `GATE-123` or `GATE-123_header-rollout`.

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

When the work is cross-repo, place the main artifact under the shared `engineering-context` initiative folder. Use the same clear initiative phrase for the folder and the artifact title. When it is repo-local, keep the artifact in the repo's own docs tree.

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

This package follows the same broad direction described in OpenAI's [Harness engineering](https://openai.com/index/harness-engineering) article and HumanLayer's [advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) repo:

- use repository-visible artifacts instead of hidden context
- make plans durable
- keep entry points small and navigable
- compact exploration into reusable documents
- treat workflow discipline as part of the engineering system
