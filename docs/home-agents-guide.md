# `$HOME/AGENTS.md` Guide

`$HOME/AGENTS.md` should be a short operating map for the user's default agent behavior across repos. It should not be a giant manual. The goal is to tell the agent where to look, how the user organizes work, and where durable artifacts belong.

## What Belongs In It

- The user's chosen repo root examples
- The user's chosen shared `engineering-context` root
- The user's chosen worktrees root
- The user's chosen scratch root
- A short rule for where active execution artifacts live and where repo-local durable knowledge lives
- Repo discovery expectations
- A reminder that plans are first-class artifacts
- A reminder that scratch is temporary and non-canonical

Keep it map-like. Push long procedures into repo-local docs, shared context docs, or copied skills.

## Path Conventions

Document the user's actual chosen paths, but present them as conventions for that workstation, not universal requirements.

Examples for code repositories:

- `~/git`
- `~/src`
- `~/code`
- `~/work/repos`

Examples for shared engineering context:

- `~/git/engineering-context`
- `~/src/engineering-context`
- `~/work/engineering-context`

Examples for implementation worktrees:

- `~/worktrees`
- `~/tmp/worktrees`

Examples for scratch:

- `~/tmp/_ai_scratch`
- `~/scratch/_ai`
- `/tmp/ai-scratch`

Examples for installed skills:

- `~/.agents/skills`
- `~/.claude/skills`

Do not hardcode one mandatory layout into the workflow design.

## Repo Guidance To Include

Your home agent guidance should tell the agent to find, in each repo:

- repo-local docs under `docs/`
- supporting repo knowledge under `docs/references/`
- service cards under `docs/services/` only when a repo has multiple runtime components

It should also tell the agent to record repo-specific commands, test flows, pitfalls, architecture notes, and durable implementation learnings in repo-local docs instead of relying on memory.

## Shared Execution Artifact Guidance To Include

Your home guidance should tell the agent that active execution artifacts belong in a chosen shared `engineering-context` repo, even when the work only touches one repo. The canonical installed snippet lives in [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md), and that file should stay the single source of truth for the copied home guidance.

The shared context layout should look like:

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

`NNNN` is a zero-padded sequence number assigned globally across `active/` and `archive/`. Scan both for the highest existing number and increment by one.

Use the shared directories as follows:

- `research/`: active research artifacts
- `plans/`: approved implementation plans
- `status/`: implementation status artifacts and close-out records
- `workflow-state.md`: optional coordination state for complex, branching, or multi-repo work
- `decisions/`: initiative-local decision records when cross-repo tradeoffs need to be preserved
- `service-catalog/`: stable service or component reference cards reused across initiatives
- `dependency-maps/`: durable cross-repo dependency or contract maps reused across initiatives

`workflow-state.md` is optional. Use it only when the work is complex enough that coordination state should live outside the plan itself.

Name the initiative folder for the work, not for the ticket alone. Prepend the next available sequence number.

- With a ticket: `NNNN_<clear-initiative>_<ticket-key>`
- Without a ticket: `NNNN_<clear-initiative>`
- Keep the ticket key as a suffix only, never the whole folder name or the prefix.

Examples:

- `0001_header-rollout_GATE-123`
- `0002_checkout-retry-policy_PAY-204`
- `0003_search-ranking-tuneup`

## Implementation Workspace Guidance To Include

Your home guidance should tell the agent to use git worktrees for implementation instead of branching directly in the repos root. This keeps the main checkouts clean and gives each initiative an isolated working copy.

The worktree layout should look like:

```text
<worktrees-root>/
  NNNN/
    <repo-a>/
    <repo-b>/
```

The `NNNN` matches the initiative's sequence number in `engineering-context/active/`. The installed `af-implement` helper at `<SKILLS_ROOT>/af-implement/scripts/init-initiative.sh` handles the full setup: assigns the sequence number, creates the initiative folder, fetches all repos, and creates worktrees. The installed `af-archive` helper at `<SKILLS_ROOT>/af-archive/scripts/archive-initiative.sh` handles cleanup: removes worktrees, deletes branches, and moves the initiative to `archive/`.

## Readability Guidance To Include

Your home guidance should tell the agent to optimize human-facing artifacts for scanning and comprehension. This applies to plans, research, and decision records -- artifacts a human will read to understand the system or make decisions. Agent-to-agent artifacts like handoffs and status updates should prioritize machine-parseable completeness instead.

The key principles to include:

- **Front-load conclusions**: each section starts with the takeaway, then the evidence.
- **Terse prose**: short sentences, no filler phrases, concrete references over vague descriptions.
- **Structured data**: bullet lists for related items, tables for comparisons, Mermaid diagrams for flows and dependency graphs.
- **Scannable headings**: headings that state findings or decisions, not just topics.
- **Consistent terminology**: one term per concept throughout the artifact.

This section belongs in the home agent guidance because readability is a cross-cutting concern that applies to all agent output, not just specific skills. Skills should focus on their domain workflow; the home guidance sets the baseline writing standard.

## Installed Snippet Source

Use [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md) as the single source of truth for the installed home guidance. After installation, replace every placeholder in `~/.codex/AGENTS.md` with real workstation paths and conventions.
