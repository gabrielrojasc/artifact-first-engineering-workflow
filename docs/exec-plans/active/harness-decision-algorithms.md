# Mini-Plan: Add Decision Algorithms and Harness Guidance

## Goal

Transform the af-research, af-plan, and af-implement skills from description-oriented to decision-algorithm-oriented so that any agent -- regardless of underlying model or tool -- can follow the workflow mechanically at critical decision points.

Motivated by ForgeCode's empirical finding that converting judgment calls into sequential YES/NO gates is the single highest-impact harness improvement (25% to 78.4% on Terminal-Bench 2.0).

## Scope

- Add decision algorithms (gates, heuristics, checklists) to all three SKILL.md files
- Add execution-context guidance (autonomous vs interactive) to af-implement
- Add entry-point discovery order to af-research
- Add effort allocation guidance to af-plan and af-implement
- Expand manual verification format in status template
- Edits only -- no new files, no new skills

## Non-goals

- Multi-repo parallel implementation guidance (deferred until real usage surfaces the need)
- Archive rules (low impact, teams develop their own cadence)
- Tool-specific guidance (no prescribing Claude Code, Codex, Cursor, etc.)
- Docs changes (workflow-examples.md, install-and-use.md stay as-is; they already show the patterns)

## Intended edits

`skills/af-implement/SKILL.md`:
1. Drift decision gate (5-question YES/NO sequential check after mismatch policy)
2. Contract vs detail definition (what "contract surface" means concretely)
3. Version drift classification (3-branch: bounded / planning / research)
4. Cumulative drift threshold (3+ deltas = pause and re-evaluate)
5. Execution context section (autonomous vs interactive mode)
6. Effort allocation (phase setup: thorough, code changes: efficient, verification: thorough)

`skills/af-research/SKILL.md`:
1. Mode selection algorithm (sequential test: which question can't you answer?)
2. Sufficiency gate (5 conditions that must all hold for research to be complete)
3. Entry-point discovery order (artifacts before source code, 6-step priority)

`skills/af-plan/SKILL.md`:
1. Size heuristics (mini-plan indicators vs phased plan indicators)
2. Re-planning merge guidance (how to handle I->P and I->R->P transitions)
3. Effort allocation (planning gets disproportionate effort, never skip under pressure)

`skills/af-implement/references/status-template.md`:
1. Manual verification section expanded with structured checklist format

## Implementation references

- ForgeCode's 7 failure modes: https://forgecode.dev/blog/benchmarks-dont-matter/
- Terminal-Bench 2.0 leaderboard: https://www.tbench.ai/leaderboard/terminal-bench/2.0

## Automated verification

- Each modified file parses as valid Markdown (no broken formatting)
- No internal contradictions between new gates and existing rules in the same SKILL.md
- Total line count per SKILL.md stays under ~120 lines (currently ~55-65 each; additions are ~60-70 lines each)

## Manual verification

- Walk through Example 3 in `docs/workflow-examples.md` applying the new drift decision gate; verify it produces correct routing for each scenario
- Simulate an autonomous agent run through the full RPI workflow using only the SKILL.md instructions; every decision point should have an explicit algorithm
- Verify each SKILL.md remains scannable -- no single section exceeds ~25 lines

## Exit criteria

- All four files edited with the content specified above
- Each decision gate is a sequential YES/NO check, not prose
- Each gate includes concrete examples (what qualifies, what does not)
- No tool-specific language (no mention of Claude Code, Codex, Cursor, etc.)
