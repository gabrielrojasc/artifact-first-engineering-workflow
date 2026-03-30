# Artifact-First Engineering Workflow

This repo packages a reusable artifact-first engineering workflow for repo-local and cross-repo work. It is primarily a filesystem layout, a set of Markdown manuals, and installable skills that help agents and engineers work from durable artifacts instead of chat history.

`Artifact-first` means the durable artifact comes before the conversation. Active research, plans, status artifacts, and decision records live in the shared context root; repo-local docs capture durable knowledge worth keeping after implementation. Chat is only a way to produce or refine those artifacts, not the long-term system of record.

Planning in this workflow follows a QRSPI-style path: Questions, Research when needed, Design, Structure, and Plan before implementation. `PI` still means `Plan -> Implement` and `RPI` still means `Research -> Plan -> Implement`; those labels are shorthand for the common execution paths, not the full planning method.

This repo has three parts:

1. Guidance for what to add to `$HOME/AGENTS.md`
2. A practical installation and usage manual for the workflow
3. Skill source folders you can install into agent setups

The package uses `artifact-first` as the top-level term:

- `artifact-first` = the workflow family and package
- `repo-local` = work contained within one repo
- `cross-repo` = work that spans more than one repo
- `service` = a repo-owned runtime component

Users should adapt directory roots to their own setup. The docs use examples such as `~/git`, `~/src`, `~/code`, `~/work/repos`, `~/git/engineering-context`, and `~/tmp/_ai_scratch`, but none of those paths are mandatory.

## Inspiration

This workflow is explicitly inspired by:

- OpenAI's [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering)
- HumanLayer's [advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)

The influence shows up in artifact-first working habits, planning discipline, context compaction, and the idea that shared execution artifacts plus versioned durable knowledge should be the main system of record.

## Start Here

- Clone this repo, then run `scripts/install.sh` to install the starter home files and live skill symlinks.
- [$HOME/AGENTS.md guidance](docs/home-agents-guide.md)
- [Install and use manual](docs/install-and-use.md)
- [Workflow examples](docs/workflow-examples.md)
- [Reusable home guidance snippet](templates/HOME.AGENTS.snippets.md)

## Skills

Canonical skill sources live in [`skills/`](skills/):

The `af` prefix stands for `artifact-first`.

- [`af-research`](skills/af-research/SKILL.md): Analyze one or more repositories and produce a compact, evidence-backed research artifact for artifact-first engineering work.
- [`af-plan`](skills/af-plan/SKILL.md): Create mini-plans for `PI` (`Plan -> Implement`) work and phased plans for `RPI` (`Research -> Plan -> Implement`) work using QRSPI-style interactive alignment and inline research when needed.
- [`af-implement`](skills/af-implement/SKILL.md): Execute an approved artifact-first plan phase by phase with explicit exits back to planning or research.
- [`af-iterate`](skills/af-iterate/SKILL.md): Apply targeted revisions to an existing artifact-first plan when the structure still holds but specific sections need updates.
- [`af-handoff`](skills/af-handoff/SKILL.md): Transfer working context between agent sessions with compact handoff documents for create and resume flows.

## What This Workflow Optimizes For

- Shared context execution artifacts as the main source of truth for active work
- Repo-local docs as the durable home for long-lived repo knowledge
- Short, map-like agent guidance instead of giant manuals
- Plans as first-class artifacts
- Compacting useful exploration into durable Markdown
- Version-grounded framework and library references when repo evidence alone is not enough
- Explicit separation of automated verification from manual verification
- Bounded implementation adaptation with explicit status logging instead of brittle plan matching
- Returning to research when ownership, boundaries, or evidence are unclear
