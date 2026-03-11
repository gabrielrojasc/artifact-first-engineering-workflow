# Distributed Agent Workflow

`distributed-agent-workflow` packages a reusable RPI-style workflow for distributed systems work. It is primarily a filesystem layout, a set of Markdown manuals, and installable skills that help agents and engineers work from durable artifacts instead of chat history.

This repo has three parts:

1. Guidance for what to add to `$HOME/AGENTS.md`
2. A practical installation and usage manual for the workflow
3. Skill source folders you can copy into agent setups

The package uses `distributed` as the top-level term:

- `distributed` = the workflow family and package
- `service` = a repo-owned runtime component
- `cross-repo` = work that spans more than one repo

Users should adapt directory roots to their own setup. The docs use examples such as `~/git`, `~/src`, `~/code`, `~/work/repos`, `~/git/engineering-context`, and `~/tmp/_ai_scratch`, but none of those paths are mandatory.

## Inspiration

This workflow is explicitly inspired by:

- OpenAI's [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering)
- HumanLayer's [Advanced Context Engineering for coding agents workshop](https://www.humanlayer.dev/docs/workshop)
- HumanLayer's [advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)

The influence shows up in artifact-first working habits, planning discipline, context compaction, and the idea that repository-local, versioned knowledge should be the main system of record.

## Start Here

- [$HOME/AGENTS.md guidance](docs/home-agents-guide.md)
- [Install and use manual](docs/install-and-use.md)
- [Workflow examples](docs/workflow-examples.md)
- [Reusable snippets and templates](templates/HOME.AGENTS.snippets.md)

## Skills

Canonical skill sources live in [`skills/`](skills/):

- [`distributed-research`](skills/distributed-research/SKILL.md)
- [`distributed-plan`](skills/distributed-plan/SKILL.md)
- [`distributed-implement`](skills/distributed-implement/SKILL.md)

## What This Workflow Optimizes For

- Repository-local, versioned artifacts as the main source of truth
- Short, map-like agent guidance instead of giant manuals
- Plans as first-class artifacts
- Compacting useful exploration into durable Markdown
- Explicit separation of automated verification from manual verification
- Returning to research when ownership, boundaries, or evidence are unclear
