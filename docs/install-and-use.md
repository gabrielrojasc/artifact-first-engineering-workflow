# Install And Use

This package is designed to be cloned, read, and copied from. It is intentionally light on tooling. The core deliverable is a repeatable artifact-first layout and a set of skills for research, planning, implementation, plan iteration, and PR review-comment triage. Planning follows a QRSPI-style path: Questions, Research when needed, Design, Structure, and Plan before implementation. `PI` (`Plan -> Implement`) and `RPI` (`Research -> Plan -> Implement`) remain useful shorthand for the two common execution paths.

Here, `artifact-first` means the durable file is the source of truth. Active plans, research notes, status artifacts, and decisions should exist as versioned artifacts that agents and humans can reuse; repo-local docs should preserve the durable knowledge worth carrying forward. Chat should support those artifacts, not replace them.

## Installation

1. Clone this repo into a location you control. A git worktree checkout is fine and works well for updates.
2. From inside that checkout or worktree, run:

```bash
scripts/install.sh
```

3. Read [`docs/home-agents-guide.md`](home-agents-guide.md) and replace every placeholder in the installed `~/.codex/AGENTS.md` with your real workstation paths and conventions. For the default layout, run `scripts/render-home-agents-snippet.sh` and merge its output into your home `AGENTS.md`.
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

The installed `~/.codex/AGENTS.md` is a starter file, not a finished workstation config. It still contains placeholders such as `<REPOS_ROOT>`, `<CONTEXT_ROOT>`, `<SCRATCH_ROOT>`, and `<SKILLS_ROOT>`. Replace them explicitly after installation.

For the default workstation layout, run:

```bash
scripts/render-home-agents-snippet.sh
```

The script prints the snippet from [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md) with these defaults:

- `~/git` for repo containers, with initiative worktrees inside each container
- `~/git/engineering-context` for shared engineering context
- `~/tmp/_ai_scratch` for ephemeral scratch work
- `~/.agents/skills` for installed workflow skills

When `~/.claude/CLAUDE.md` is created by the installer, it is intentionally a symlink to `~/.codex/AGENTS.md` so both tools read the same guidance file.

## Bare Repo Setup

The repo-container layout keeps each repository under `<REPOS_ROOT>/<repo>/` with a bare `.git/`, a persistent default-branch worktree, and initiative worktrees as siblings.

This is the current steady-state workspace model. The workflow no longer creates a worktree for every repo up front under a separate worktrees root. Create initiative worktrees only for the repos needed by the current plan, and add another repo later if scope expands.

Use the installed `af-workspace` helpers to manage repo containers:

```bash
# Add or repair one repo
$HOME/.agents/skills/af-workspace/scripts/add-bare-repo.sh --repos-root <REPOS_ROOT> <repo-url>

# Add or repair many repos from a manifest ('<repo-url> [repo-name]' per line)
$HOME/.agents/skills/af-workspace/scripts/add-bare-repo.sh --repos-root <REPOS_ROOT> --from-manifest repos.txt

# List repo containers and their initiative worktrees
$HOME/.agents/skills/af-workspace/scripts/list-workspace.sh --repos-root <REPOS_ROOT> --context-root <CONTEXT_ROOT>

# Fetch and fast-forward every default-branch worktree, then prune stale ones
$HOME/.agents/skills/af-workspace/scripts/sync-workspace.sh --repos-root <REPOS_ROOT> --context-root <CONTEXT_ROOT>
```

The `add-bare-repo.sh` entry point is also available in this repo at [`scripts/add-bare-repo.sh`](../scripts/add-bare-repo.sh) for repository-local setup.

## Installing The Skills

The canonical workflow definitions live in these folders:

- [`skills/af-research/`](../skills/af-research/)
- [`skills/af-workspace/`](../skills/af-workspace/)
- [`skills/af-plan/`](../skills/af-plan/)
- [`skills/af-implement/`](../skills/af-implement/)
- [`skills/af-iterate/`](../skills/af-iterate/)
- [`skills/af-archive/`](../skills/af-archive/)
- [`skills/gh-review-comments/`](../skills/gh-review-comments/)

Each skill contains:

- `SKILL.md` as the canonical workflow definition

Some skills also contain:

- local `references/` files so the skill can travel independently
- local `scripts/` helpers, with any shared helper library vendored under `scripts/lib/` so the skill has no external dependencies on this repo
- a `scripts/render-artifact.sh` helper and `scripts/lib/artifact-template.html` for the artifact-producing skills (`af-research`, `af-plan`, `af-implement`, `af-iterate`), vendored byte-identically so each skill renders its HTML view independently

The installer links each of these skill folders individually into `~/.agents/skills/` so unrelated skills in that directory are left alone.

## Repo-Local Docs Setup

For repos where you want this workflow to work well, create or grow a local docs tree like:

```text
repo/
  docs/
    architecture/
    references/
    services/
```

Use these directories as follows:

- `docs/architecture/`: durable repo maps, boundaries, and important design notes
- `docs/references/`: commands, test flows, pitfalls, glossary, local setup notes, dependency notes, and durable implementation learnings worth preserving
- `docs/services/`: service or component cards only when the repo has multiple deployable or runtime units

Skip `docs/services/` in single-service repos.

Repo-local docs are not the default home for active research, plans, or status tracking. Use them for durable knowledge distilled from completed work when that knowledge will help future engineers or agents.

When `docs/services/` is used, each service card should cover:

- what the service or component does
- entrypoints
- dependencies
- owned contracts
- run and test commands
- rollout quirks
- common failure modes

## Shared `engineering-context` Setup

The canonical agent-facing layout guidance lives in [`templates/HOME.AGENTS.snippets.md`](../templates/HOME.AGENTS.snippets.md) and [`skills/af-research/SKILL.md`](../skills/af-research/SKILL.md). For human setup, use a shared repo for active execution artifacts with a shape like:

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

`NNNN` is a zero-padded sequence number assigned globally. Scan both `active/` and `archive/` for the highest existing number and increment by one. This gives a chronological view of initiatives across the entire history.

Use it for:

- research artifacts for both single-repo and cross-repo work
- implementation plans for both PI and RPI paths
- implementation status artifacts and close-out records
- rollout coordination
- initiative-local decision records in `decisions/` when cross-repo tradeoffs need a durable record
- stable service or component reference cards in `service-catalog/`
- durable cross-repo dependency or contract maps in `dependency-maps/`

Name active initiative folders for the work at hand, not for the ticket alone. Prepend the next available sequence number.

- Default pattern with a ticket: `NNNN_<clear-initiative>_<ticket-key>`
- Default pattern without a ticket: `NNNN_<clear-initiative>`
- Keep the clear-initiative part short, readable, and understandable at a glance.
- Keep the ticket key as a suffix only when it helps traceability.

Examples:

- `0001_header-rollout_GATE-123`
- `0002_checkout-retry-policy_PAY-204`
- `0003_search-ranking-tuneup`

Avoid ticket-led names such as `GATE-123` or `0001_GATE-123_header-rollout`.

## What Ownership Means

In this workflow, ownership means the most relevant source of truth and responsibility boundary for a behavior, contract, or runtime component.

Examples:

- which repo owns a contract or schema
- which service is responsible for emitting or consuming an event
- which team or component is the authoritative place to change behavior
- whether a document belongs in repo-local durable docs or the shared execution context

If ownership is unclear, planning should route into more research instead of guessing where the change belongs.

## Choosing A PI Or RPI Path

Planning now starts with QRSPI-style alignment inside `af-plan`: ask informed questions, gather research when needed, discuss design, approve the structure, then write the plan. `PI` and `RPI` are still useful labels, but they describe the resulting path shape and risk profile rather than replacing those planning steps.

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

Use research to document the system as it exists today. Good research should leave behind a durable artifact rather than a long chat transcript. Research can be a standalone `af-research` pass or an inline pass delegated by `af-plan` when planning starts without enough truth.

Choose the research mode that fits the task:

- repo discovery
- boundary tracing
- contract validation
- rollout or environment validation

Place the main research artifact under the shared `engineering-context` initiative folder for both single-repo and cross-repo work. Use the same clear initiative phrase for the folder and the artifact title. Distill lasting repo knowledge back into repo-local docs only when the research surfaces something worth preserving there.

When behavior depends on a framework or library API, detect the version from repo-local manifests, lockfiles, images, or config first. If repo evidence does not fully prove the behavior, cite the matching official docs in the research artifact instead of relying on memory.

Before writing the first research or plan artifact for a new initiative, create or reuse the shared initiative folder:

```bash
skills/af-research/scripts/init-initiative-context.sh \
  --context-root <CONTEXT_ROOT> \
  <initiative-name> [ticket-key]
```

### Plan

Use planning to turn a task or research artifact into an actionable implementation path.

- `af-plan` performs QRSPI-style alignment before writing the plan: Questioning, Design Discussion, and Structure Approval.
- The structure-approval proposal is itself a Markdown artifact under `plans/`, not just an in-chat outline.
- Use a mini-plan for the PI path.
- Use a phased plan for the RPI path.
- Store plan artifacts under the shared initiative folder's `plans/` directory.
- Proposal and final plan artifacts should both include a Mermaid sequence diagram when a diagram makes the flow, rollout, or responsibilities clearer. Skip it only when a diagram would be artificial or useless.
- Carry forward the version-sensitive docs and technology references the implementer will need when framework or library behavior matters.
- If no prior research artifact exists and ownership, repo set, contract dependencies, or rollout dependencies are unclear, delegate inline research instead of pretending the plan is ready.
- Use standalone `af-research` when the task is pure discovery, audit, or boundary mapping without immediate planning.

### Implement

Implement phase by phase from an approved plan artifact.

- Keep automated verification separate from manual verification.
- Record implementation status under the shared initiative folder's `status/` directory by default.
- If the codebase differs only in bounded implementation detail, continue and record the delta in the status artifact.
- If the codebase differs in goal, behavior, scope, or rollout assumptions, return to planning.
- If ownership, boundaries, or dependency understanding is wrong, return to research.
- Before closing implementation, decide whether the work produced durable repo knowledge. Update repo-local docs only when the answer is yes.

### Implementation Workspace

Do not create branches or edit code in the persistent default worktree. Use git worktrees so each initiative gets an isolated working copy and default-branch browsing stays clean.

Initialize or reuse the shared initiative folder during research or planning:

```bash
skills/af-plan/scripts/init-initiative-context.sh \
  --context-root <CONTEXT_ROOT> \
  <initiative-name> [ticket-key]
```

Then run the `af-implement` helper script to create worktrees for that initiative:

```bash
skills/af-implement/scripts/init-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  --repo <repo-name> [--repo <repo-name> ...] \
  [--branch-prefix feature] \
  <NNNN or folder-name or initiative-name> [ticket-key]
```

The script:

1. Resolves the existing initiative folder and sequence number from the shared context root.
2. Ensures the implementation `status/` directory exists.
3. Processes only the requested repo containers.
4. Fetches and creates requested worktrees in parallel so multi-repo setup stays fast.
5. Creates a worktree per repo under `<repos-root>/<repo>/NNNN-<initiative>/` with a properly named branch.

If implementation later needs another repo, rerun the helper with another `--repo <repo-name>`.

All implementation happens inside the worktrees. Branch naming follows the repo's branch prefix convention (`feature/`, `bugfix/`, `hotfix/`, etc.).

Cleanup: run the `af-archive` helper script to remove worktrees, delete local branches, and move the initiative folder to `archive/`:

```bash
skills/af-archive/scripts/archive-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  <NNNN>
```

### Rendering A Readable HTML View

Markdown stays the source of truth for every artifact. The HTML render is a generated, human-friendly view -- it is never hand-edited and never replaces the Markdown. The artifact-producing skills (`af-research`, `af-plan`, `af-implement`, `af-iterate`) each ship a `render-artifact.sh` helper that produces an `<artifact>.html` sibling next to the Markdown:

```bash
$HOME/.agents/skills/<skill>/scripts/render-artifact.sh <artifact.md>
```

The generated view is dark-mode-first with a light toggle and includes:

- an auto-generated table of contents with scroll tracking
- rendered Mermaid diagrams
- syntax-highlighted code blocks
- auto-colored status pills for status-style tables

The render is self-contained: the Markdown is inlined into the HTML and rendered client-side, so the file opens directly in a browser. Re-run the helper after every edit to keep the HTML view current. Never hand-edit the generated HTML.

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
