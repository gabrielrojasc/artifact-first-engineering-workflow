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
- Ephemeral scratch work lives under `<SCRATCH_ROOT>` -- not a second documentation system.

## Repo Discovery

- First stops: `AGENTS.md`, `README.md`, repo-local `docs/` indexes. Prefer versioned artifacts over chat history.
- Keep `AGENTS.md` short and map-like.

## Docs & Planning Layout

- Repo docs live under `docs/`; supporting knowledge under `docs/references/`; `docs/services/` only for multi-component repos.
- Execution artifacts default to `<CONTEXT_ROOT>/active/NNNN_<clear-initiative>[_<ticket-key>]/` for both single-repo and cross-repo work.
- `NNNN` is a zero-padded sequence number assigned globally across `active/` and `archive/`. Scan both directories for the highest existing number and increment by one.
- Use repo-local docs for durable knowledge worth preserving from completed work: architecture notes, commands, pitfalls, service cards, and implementation learnings with ongoing value.
- Use `research/`, `plans/`, and `status/` under the initiative folder for active execution artifacts; keep `decisions/` for tradeoffs that need a durable record.
- Stable service reference cards go in `<CONTEXT_ROOT>/service-catalog/`; cross-repo dependency maps in `<CONTEXT_ROOT>/dependency-maps/`.
- Use `workflow-state.md` only for complex, branching, or multi-repo coordination.

## Workflow Rules

- Plans are first-class artifacts. Compact useful exploration into durable Markdown.
- The structure-approval proposal is also a first-class Markdown artifact, not just a chat message.
- Distinguish automated verification from manual verification.
- Verify framework/library behavior against repo-detected versions and official docs, not memory.
- When ownership, boundaries, or evidence are unclear, research before guessing.

## Artifact Readability

Human-facing artifacts -- plans, research, decision records -- must optimize for scanning and comprehension. Agent-to-agent artifacts like handoffs and status updates prioritize machine-parseable completeness instead.

- Lead each section with the conclusion or key takeaway, then supporting detail.
- Short declarative sentences. Cut filler phrases ("it should be noted", "in order to", "it is important that").
- Concrete over abstract: specific file paths, function names, and version numbers over vague references.
- Use bullet lists for three or more related items. Use tables for comparisons or structured attribute sets.
- One idea per paragraph. No wall-of-text blocks.
- Write headings that state the finding or decision, not just the topic (prefer "Auth middleware stores tokens in plaintext" over "Auth middleware analysis").
- Use **bold** for key terms on first mention and for emphasis.
- Use Mermaid diagrams for flows, dependency graphs, and architecture when visual structure aids comprehension over prose.
- For planning artifacts, include Mermaid sequence diagrams in both the proposal and the final plan when they clarify flow, rollout, or ownership; skip them only when they would add no value.
- Consistent terminology throughout the artifact. Pick one term for a concept and keep it.

## Implementation Workspace

Do not create branches or edit code directly in `<REPOS_ROOT>`. Use git worktrees so each initiative gets an isolated working copy and the main checkouts stay clean.

Setup: run the installed `af-implement` helper script. It assigns the next sequence number, creates the initiative folder structure, fetches all repos, and creates worktrees under `<WORKTREES_ROOT>/NNNN/<repo>/`.

```bash
<SKILLS_ROOT>/af-implement/scripts/init-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  --worktrees-root <WORKTREES_ROOT> \
  [--branch-prefix feature] \
  <initiative-name> [ticket-key]
```

All implementation happens inside `<WORKTREES_ROOT>/NNNN/<repo>/`. Branch naming follows the repo's branch prefix convention (e.g., `feature/`, `bugfix/`, `hotfix/`).

Cleanup: run the installed `af-archive` helper script to remove worktrees, delete local branches, and move the initiative to `<CONTEXT_ROOT>/archive/`.

```bash
<SKILLS_ROOT>/af-archive/scripts/archive-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  --worktrees-root <WORKTREES_ROOT> \
  [--delete-remote] <NNNN>
```
```
