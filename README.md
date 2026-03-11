# Artifact-First Engineering Workflow

This repo packages a reusable artifact-first engineering workflow for repo-local and cross-repo work. It is primarily a filesystem layout, a set of Markdown manuals, and installable skills that help agents and engineers work from durable artifacts instead of chat history.

This repo has three parts:

1. Guidance for what to add to `$HOME/AGENTS.md`
2. A practical installation and usage manual for the workflow
3. Skill source folders you can copy into agent setups

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

The influence shows up in artifact-first working habits, planning discipline, context compaction, and the idea that repository-local, versioned knowledge should be the main system of record.

## Start Here

- [$HOME/AGENTS.md guidance](docs/home-agents-guide.md)
- [Install and use manual](docs/install-and-use.md)
- [Workflow examples](docs/workflow-examples.md)
- [Reusable snippets and templates](templates/HOME.AGENTS.snippets.md)

## Skills

Canonical skill sources live in [`skills/`](skills/):

The `af` prefix stands for `artifact-first`.

- [`af-research`](skills/af-research/SKILL.md)
- [`af-plan`](skills/af-plan/SKILL.md)
- [`af-implement`](skills/af-implement/SKILL.md)

## What This Workflow Optimizes For

- Repository-local, versioned artifacts as the main source of truth
- Short, map-like agent guidance instead of giant manuals
- Plans as first-class artifacts
- Compacting useful exploration into durable Markdown
- Explicit separation of automated verification from manual verification
- Returning to research when ownership, boundaries, or evidence are unclear
