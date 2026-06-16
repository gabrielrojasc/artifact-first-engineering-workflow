# `~/.codex/AGENTS.md` Snippets

Use this file as a starting point for user-level guidance. Replace workstation placeholders with actual paths before relying on the installed `AGENTS.md`. Rendered snippets intentionally keep metavariables such as `<repo>`, `<repo-url>`, and `<NNNN-or-folder>` for commands and examples.

## Generic Top-Level Snippet

Replace these placeholders before use:

| Placeholder | Examples |
|---|---|
| `<REPOS_ROOT>` | `~/git`, `~/src`, `~/code`, `~/work/repos` |
| `<CONTEXT_ROOT>` | `~/git/engineering-context`, `~/src/engineering-context` |
| `<SCRATCH_ROOT>` | `~/tmp/_ai_scratch`, `~/scratch/_ai`, `/tmp/ai-scratch` |
| `<SKILLS_ROOT>` | `~/.agents/skills`, `~/.claude/skills` |

```md
# Default Agent Workflow

## Workspace Conventions

- Repo containers live under `<REPOS_ROOT>/<repo>/`.
- Browsable default-branch code lives under `<REPOS_ROOT>/<repo>/<default-branch>/`.
- Shared engineering context lives under `<CONTEXT_ROOT>`.
- Artifact-first skills/scripts live under `<SKILLS_ROOT>`.
- Ephemeral scratch work lives under `<SCRATCH_ROOT>`; it is temporary and non-canonical.
- Add or repair repo containers with the `af-workspace` helper before creating initiative worktrees.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, and repo-local `docs/` indexes.
- Prefer versioned artifacts over chat history.
- Treat `AGENTS.md` as a short map, not a full manual.

## Docs And Planning Layout

- Repo docs live under `docs/`; durable supporting knowledge belongs under `docs/references/`.
- Use `docs/services/` only for multi-component repos.
- Active execution artifacts belong under `<CONTEXT_ROOT>/active/NNNN_<clear-initiative>[_<ticket-key>]/`.
- Before creating a new initiative folder, search `<CONTEXT_ROOT>/active/` and `<CONTEXT_ROOT>/archive/` for existing matching work and reuse it when appropriate.
- For new initiatives, scan `<CONTEXT_ROOT>/active/` and `<CONTEXT_ROOT>/archive/` for the highest existing `NNNN`, then increment by one.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Start by identifying the requested outcome, success criteria, constraints, and evidence needed.
- Use the smallest workflow and artifact set that safely satisfies the request.
- Stop research or tool use once the core request can be answered with sufficient evidence.
- Ask only when missing information materially changes outcome, risk, ownership, or side effects.
- Plans are first-class artifacts when the work is complex enough to need them.
- Distinguish automated verification from manual verification.
- Verify framework/library behavior against repo-detected versions and official docs.
- When ownership, boundaries, or evidence are unclear, research before guessing.

## Artifact Readability

- Optimize human-facing artifacts for scanning and comprehension.
- Lead with conclusions, then supporting evidence.
- Use short concrete prose, structured lists, tables, and diagrams when they improve comprehension.
- Agent-to-agent artifacts like handoffs and status updates prioritize machine-parseable completeness.

## Implementation Workspace

- Do not create branches or edit code in the persistent default worktree.
- If you are in the persistent default worktree and need to edit code, stop and create or switch to the initiative worktree first.
- Use git worktrees under `<REPOS_ROOT>/<repo>/NNNN-<initiative>/` so each initiative gets an isolated working copy.
- The worktree `NNNN` matches the initiative number under `<CONTEXT_ROOT>/active/`.
- During planning or research, use the `af-plan` or `af-research` context helper to create or reuse the initiative folder.
- During implementation, use `<SKILLS_ROOT>/af-implement/scripts/init-initiative.sh --repos-root <REPOS_ROOT> --context-root <CONTEXT_ROOT> --repo <repo> <NNNN-or-folder>` to create worktrees only for repos needed by the existing initiative; rerun it with another `--repo` if scope expands.
- Cleanup is destructive. Before running `<SKILLS_ROOT>/af-archive/scripts/archive-initiative.sh`, get explicit user approval and verify no uncommitted or unpushed work would be lost.
- Branch naming follows the repo's branch prefix convention.
```
