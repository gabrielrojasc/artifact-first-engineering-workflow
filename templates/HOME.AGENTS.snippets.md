# `$HOME/AGENTS.md` Snippets

Use this file as a starting point for user-level guidance. Replace the placeholders with the actual paths and conventions for the workstation.

## Generic Top-Level Snippet

```md
# Default Agent Workflow

## Workspace Conventions

- Code repositories usually live under `<CHOSEN_REPOS_ROOT>`.
- Shared cross-repo engineering context lives under `<CHOSEN_ENGINEERING_CONTEXT_ROOT>`.
- Ephemeral scratch work lives under `<CHOSEN_SCRATCH_ROOT>`.

Examples for repo roots include `~/git`, `~/src`, `~/code`, and `~/work/repos`.
Examples for shared context roots include `~/git/engineering-context`, `~/src/engineering-context`, and `~/work/engineering-context`.
Examples for scratch roots include `~/tmp/_ai_scratch`, `~/scratch/_ai`, and `/tmp/ai-scratch`.

## Repo Discovery Conventions

- Treat `AGENTS.md`, `README.md`, and repo-local `docs/` indexes as the first stop.
- Prefer repository-local, versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs Map Expectations

- Repo-local docs live under `docs/`.
- Repo-specific plans live under `docs/exec-plans/active/` and `docs/exec-plans/completed/`.
- Supporting knowledge lives under `docs/references/`.
- `docs/services/` is used only when the repo has multiple runtime components.

## Planning Locations

- Repo-local work keeps plans in the repo.
- Cross-repo work keeps research and plans under `<CHOSEN_ENGINEERING_CONTEXT_ROOT>/active/<initiative>/`.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Plans are first-class artifacts.
- Compact useful exploration into durable Markdown.
- Distinguish automated verification from manual verification.
- If ownership, boundaries, or evidence are unclear, do more research instead of guessing.

## Scratch Guidance

- Use scratch for copied logs, rough notes, temporary summaries, and intermediate output.
- Scratch is not a second documentation system.
```

## Optional Compatibility Note

If a tool expects `CLAUDE.md`, users may create:

```text
$HOME/.claude/CLAUDE.md -> $HOME/AGENTS.md
```
