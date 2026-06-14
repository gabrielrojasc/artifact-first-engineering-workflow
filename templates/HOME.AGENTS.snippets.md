# `$HOME/AGENTS.md` Snippets

Use this file as a starting point for user-level guidance. Replace every placeholder with the actual paths and conventions for the workstation before relying on the installed `AGENTS.md`.

## Generic Top-Level Snippet

Replace these placeholders before use:

| Placeholder | Examples |
|---|---|
| `<REPOS_ROOT>` | `~/git`, `~/src`, `~/code`, `~/work/repos` |
| `<CONTEXT_ROOT>` | `~/git/engineering-context`, `~/src/engineering-context` |
| `<WORKTREES_ROOT>` | `~/worktrees`, `~/tmp/worktrees` |
| `<SCRATCH_ROOT>` | `~/tmp/_ai_scratch`, `~/scratch/_ai`, `/tmp/ai-scratch` |
| `<SKILLS_ROOT>` | `~/.agents/skills`, `~/.claude/skills` |

```md
# Default Agent Workflow

## Workspace Conventions

- Code repositories live under `<REPOS_ROOT>`.
- Shared engineering context lives under `<CONTEXT_ROOT>`.
- Implementation worktrees live under `<WORKTREES_ROOT>`.
- Artifact First skills/scripts live under `<SKILLS_ROOT>`.
- Ephemeral scratch work lives under `<SCRATCH_ROOT>`; it is temporary and non-canonical.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, and repo-local `docs/` indexes.
- Prefer versioned artifacts over chat history.
- Treat `AGENTS.md` as a short map, not a full manual.

## Docs And Planning Layout

- Repo docs live under `docs/`; durable supporting knowledge belongs under `docs/references/`.
- Use `docs/services/` only for multi-component repos.
- Active execution artifacts belong under `<CONTEXT_ROOT>/active/NNNN_<clear-initiative>[_<ticket-key>]/`.
- Scan `<CONTEXT_ROOT>/active/` and `<CONTEXT_ROOT>/archive/` for the highest existing `NNNN`, then increment by one.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts.
- Use `decisions/` for initiative-local tradeoffs that need a durable record.
- Use `<CONTEXT_ROOT>/service-catalog/` for stable service cards and `<CONTEXT_ROOT>/dependency-maps/` for durable cross-repo maps.
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
- Lead sections with the conclusion, then supporting evidence.
- Use short concrete prose, structured lists, tables for comparisons, and Mermaid diagrams when visual structure helps.
- Use headings that state findings or decisions.
- Keep terminology consistent.
- Agent-to-agent artifacts like handoffs and status updates prioritize machine-parseable completeness.

## Implementation Workspace

- Do not create branches or edit code directly in `<REPOS_ROOT>`.
- Use git worktrees under `<WORKTREES_ROOT>/NNNN/<repo>/` so each initiative gets an isolated working copy.
- The worktree `NNNN` matches the initiative number under `<CONTEXT_ROOT>/active/`.
- During planning or research, use `<SKILLS_ROOT>/af-plan/scripts/init-initiative-context.sh` to create or reuse the initiative folder.
- During implementation, use `<SKILLS_ROOT>/af-implement/scripts/init-initiative.sh` to create worktrees for the existing initiative.
- Cleanup is destructive. Before running `<SKILLS_ROOT>/af-archive/scripts/archive-initiative.sh`, get explicit user approval and verify no uncommitted or unpushed work would be lost.
- Branch naming follows the repo's branch prefix convention.
```
