# Mini-Plan: Add Reliability Patterns from ForgeCode Research

## Goal

Add prompt-level reliability patterns to `af-implement` and `af-research` that address the top gaps identified in `docs/research/forgecode-improvement-analysis.md`: stuck-state recovery, structured error reflection before retry, retry budget, pre-implementation reasoning, and fast discovery with safe fallback.

Motivated by ForgeCode's empirical evidence that stuck-state detection, structured retry, and fast entry-point discovery with fallback were strong correlates of their 78.4% to 81.8% Terminal-Bench 2.0 improvement.

## Scope

- Add stuck-state gate to `af-implement` and lighter guidance to `af-research`
- Add verification recovery protocol (error reflection + retry budget) to `af-implement`
- Add pre-implementation reasoning checkpoint to `af-implement`
- Add fast-path-with-fallback rule to `af-research`
- Add retry tracking to the status template
- Edits only -- no new files, no new skills

## Non-goals

- Context management / compaction guidance (runtime-level, not prompt-level)
- Structured diagnostic for conflicting evidence (low impact, existing "rank weak evidence" guidance is adequate)
- Intra-phase task-list template changes (decision note: use the plan artifact as the canonical task list, not a new template section)
- Tool-specific language (no prescribing Claude Code, Codex, Cursor, etc.)
- Changes to `af-plan` (no gaps identified for the planning skill in this research pass)

## Intended edits

All edits in `artifact-first-engineering-workflow`.

### `skills/af-implement/SKILL.md`

1. **Stuck-state gate** -- Add after the Cumulative Drift section. A 2-question sequential check: are the last 3+ actions identical or a repeating cycle? YES -> stop, articulate why, choose a materially different approach. NO -> continue. Include concrete examples (re-running the same failing test without changes, cycling between two files without progress).

2. **Verification recovery protocol** -- New section after Rules. Combines structured error reflection and retry budget into one protocol:
   - When automated verification fails, before retrying: (a) state exactly what failed, (b) state the root cause, (c) make the corrected change.
   - Budget: original attempt + up to 2 retries (3 total). Before retry 2, the hypothesis must be materially different from retry 1. If all 3 fail, stop and return to planning.
   - Keep this concise: ~12-15 lines total.

3. **Pre-implementation reasoning checkpoint** -- Add as a new step between current steps 4 and 5 in the Workflow. Before editing code: state the approach and the most likely failure mode. One sentence each, recorded in the status artifact. ~3 lines.

### `skills/af-research/SKILL.md`

4. **Fast-path with safe fallback** -- Enhance existing workflow step 3 (entry-point discovery order) with an explicit broadening-and-stop rule: after the artifact pass, broaden once to targeted source and tests if the question is still unanswered, then stop and declare uncertainty rather than wandering broadly. ~3-4 lines added to the existing step.

5. **Stuck-state reassessment** -- Add to Rules section. If discovery is not converging after two broadening passes through the same source area, reassess the research mode (e.g., switch from boundary tracing to contract validation) rather than continuing the same approach. ~3 lines.

### `skills/af-implement/references/status-template.md`

6. **Retry tracking** -- Add a `Verification retries` field after the Automated verification section to track attempt number and what changed between attempts. ~4 lines.

## Implementation references

- ForgeCode research artifact: `docs/research/forgecode-improvement-analysis.md` (GAPs 1-3, 5-6 and decision notes)
- Prior plan for style reference: `docs/exec-plans/active/harness-decision-algorithms.md`
- ForgeCode source patterns:
  - Doom loop detector: `crates/forge_app/src/hooks/doom_loop.rs` in `antinomyhq/forge`
  - Error reflection template: `templates/forge-partial-tool-error-reflection.md` in `antinomyhq/forge`
  - Retry message template: `templates/forge-tool-retry-message.md` in `antinomyhq/forge`

## Automated verification

- Each modified file parses as valid Markdown (no broken formatting, no orphaned list items)
- No internal contradictions between new sections and existing gates in the same SKILL.md
- `af-implement/SKILL.md` stays under ~145 lines (currently 119; additions are ~20-25 lines)
- `af-research/SKILL.md` stays under ~145 lines (currently 135; additions are ~6-7 lines)
- No single new section exceeds ~15 lines

## Manual verification

- Walk through a scenario where automated verification fails 3 times: verify the retry budget protocol produces correct routing (reflection -> retry 1 -> different reflection -> retry 2 -> return to planning)
- Walk through a scenario where an agent reads the same 3 files repeatedly without progress: verify the stuck-state gate fires and produces a materially different next action
- Walk through a research pass where the first artifact pass is insufficient: verify the fast-path-with-fallback rule guides exactly one broadening pass before declaring uncertainty
- Verify each SKILL.md remains scannable -- no single section exceeds ~25 lines

## Exit criteria

- All 3 files edited with the content specified above
- Stuck-state gate is a sequential YES/NO check with concrete examples
- Verification recovery protocol combines reflection and budget in one place
- Pre-implementation reasoning is lightweight (approach + failure mode, one sentence each)
- Fast-path fallback rule has an explicit stop condition
- No tool-specific language
- No emojis in any markdown file
