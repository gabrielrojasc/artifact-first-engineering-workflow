# `$HOME/AGENTS.md` Guide

`$HOME/AGENTS.md` should be a short operating map for the user's default agent behavior across repos. It should not be a giant manual. The goal is to tell the agent where to look, how the user organizes work, and where durable artifacts belong.

## What Belongs In It

- The user's chosen repo root examples
- The user's chosen shared `engineering-context` root
- The user's chosen scratch root
- A short rule for where repo-local docs live
- A short rule for where cross-repo research and plans live
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

Examples for scratch:

- `~/tmp/_ai_scratch`
- `~/scratch/_ai`
- `/tmp/ai-scratch`

Do not hardcode one mandatory layout into the workflow design.

## Repo Guidance To Include

Your home agent guidance should tell the agent to find, in each repo:

- repo-local docs under `docs/`
- execution plans under `docs/exec-plans/active/` and `docs/exec-plans/completed/`
- supporting repo knowledge under `docs/references/`
- service cards under `docs/services/` only when a repo has multiple runtime components

It should also tell the agent to record repo-specific commands, test flows, pitfalls, and architecture notes in repo-local docs instead of relying on memory.

## Shared Cross-Repo Guidance To Include

Your home guidance should tell the agent that cross-repo work belongs in a chosen shared `engineering-context` repo, with a shape like:

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

`workflow-state.md` is optional. Use it only when the work is complex enough that coordination state should live outside the plan itself.

## Copy-Paste Snippet

Adapt this snippet to your workstation:

```md
# Default Agent Workflow

## Workspace Conventions

- Code repositories usually live under `<CHOSEN_REPOS_ROOT>` such as `~/git` or `~/work/repos`.
- Shared cross-repo engineering context lives under `<CHOSEN_ENGINEERING_CONTEXT_ROOT>`.
- Ephemeral scratch work lives under `<CHOSEN_SCRATCH_ROOT>`.

## Artifact Rules

- Treat repository-local, versioned artifacts as the main system of record.
- Keep `AGENTS.md` files short and map-like. Put long procedures in repo-local docs.
- Plans are first-class artifacts. Prefer durable plan files over chat history.
- Compact useful exploration into Markdown artifacts that future agents can reuse.
- Distinguish automated verification from manual verification.
- If ownership, boundaries, or evidence are unclear, do more research instead of guessing.

## Repo Discovery

- Start with `AGENTS.md`, `README.md`, and `docs/` indexes.
- Look for repo-local docs under `docs/architecture/`, `docs/references/`, `docs/exec-plans/`, and `docs/services/` when present.
- For single-service repos, `docs/services/` is usually unnecessary.
- For multi-component repos, `docs/services/` should describe each owned runtime component.

## Planning Locations

- Repo-specific plans live in `docs/exec-plans/active/` and move to `docs/exec-plans/completed/` when finished.
- Cross-repo initiatives live under `<CHOSEN_ENGINEERING_CONTEXT_ROOT>/active/<initiative>/`.
- Use `workflow-state.md` only when the work has branching coordination that does not fit cleanly inside the plan.

## Scratch Guidance

- Use scratch only for temporary logs, rough notes, copied output, and disposable summaries.
- Scratch is not a second documentation system.
```

The same snippet also appears in [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md).
