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
- Consistent terminology throughout the artifact. Pick one term for a concept and keep it.
```
