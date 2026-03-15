# `$HOME/AGENTS.md` Snippets

Use this file as a starting point for user-level guidance. Replace every placeholder with the actual paths and conventions for the workstation before relying on the installed `AGENTS.md`.

## Generic Top-Level Snippet

Replace these placeholders before use:

| Placeholder | Examples |
|---|---|
| `<REPOS_ROOT>` | `~/git`, `~/src`, `~/code`, `~/work/repos` |
| `<CONTEXT_ROOT>` | `~/git/engineering-context`, `~/src/engineering-context` |
| `<SCRATCH_ROOT>` | `~/tmp/_ai_scratch`, `~/scratch/_ai`, `/tmp/ai-scratch` |

```md
# Default Agent Workflow

## Workspace Conventions

- Code repositories live under `<REPOS_ROOT>`.
- Shared cross-repo engineering context lives under `<CONTEXT_ROOT>`.
- Ephemeral scratch work lives under `<SCRATCH_ROOT>` -- not a second documentation system.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, repo-local `docs/` indexes. Prefer versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs & Planning Layout

- Repo docs live under `docs/`; supporting knowledge under `docs/references/`; `docs/services/` only for multi-component repos.
- Repo-local plans live under `docs/exec-plans/{active,completed}/`.
- Cross-repo plans live under `<CONTEXT_ROOT>/active/<clear-initiative>[_<ticket-key>]/`; decisions in a `decisions/` subfolder when cross-repo tradeoffs need a durable record.
- Stable service reference cards go in `<CONTEXT_ROOT>/service-catalog/`; cross-repo dependency maps in `<CONTEXT_ROOT>/dependency-maps/`.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Plans are first-class artifacts. Compact useful exploration into durable Markdown.
- Distinguish automated verification from manual verification.
- Verify framework/library behavior against repo-detected versions and official docs, not memory.
- When ownership, boundaries, or evidence are unclear, research before guessing.
```
