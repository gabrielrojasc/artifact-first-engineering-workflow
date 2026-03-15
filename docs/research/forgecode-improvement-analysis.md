# Research: ForgeCode Patterns for Artifact-First Framework Improvement

## Objective

What techniques from ForgeCode's open-source agent harness (`antinomyhq/forge`) could improve reliability and coverage of the artifact-first engineering workflow, and what repo-visible changes most plausibly explain ForgeCode's public Terminal-Bench 2.0 improvement from **78.4% on 2026-03-02** to **81.8% on 2026-03-12**?

## Scope

- In-scope: ForgeCode OSS repo (`antinomyhq/forge`), ForgeCode public site and blog, Terminal-Bench 2.0 leaderboard, all three `af-*` skills and their reference templates in this repo
- Out-of-scope: ForgeCode commercial product specifics, unpublished benchmark harness internals, runtime-only features that require a custom agent runtime rather than prompt-level workflow guidance

## Findings

### ForgeCode's seven failure modes still hold

1. **Same model, very different performance**: harness and scaffolding matter as much as the model itself.
2. **Tool descriptions do not guarantee tool correctness**: tools fail through selection, arguments, and sequencing.
3. **Tool and argument naming is a reliability variable**: naming aligned with model priors reduces avoidable tool-call failures.
4. **Context size is a multiplier on the right entry point**: lightweight entry-point discovery beats broad wandering.
5. **Time limits punish trajectories, not just wrong answers**: bad exploration paths waste the budget even if the final approach would eventually work.
6. **Planning tools only work if you enforce them**: mandatory task tracking was a major step-change.
7. **Terminal-Bench rewards speed and recovery, not just intelligence**: runtime architecture and failure recovery matter directly.

### Public performance progression now has an extra step

| Phase | Technique | Result |
|---|---|---|
| Baseline | Interactive runtime, no planning | ~25% |
| Stabilization | Non-interactive mode + tool naming fixes + micro-evals | ~38% |
| Planning control | `todo_write` enforcement via low-level evals | 66% |
| Speed architecture | Subagent parallelization + progressive thinking | 78.4% |
| Reliability hardening | Loop escape + sync hardening + retry and provider fixes | 81.8% |

### Gap analysis: what ForgeCode has that we do not

#### GAP 1: Stuck-state detection and recovery (HIGH IMPACT)

ForgeCode implements a `DoomLoopDetector` in `crates/forge_app/src/hooks/doom_loop.rs` that detects two stuck patterns:

- Consecutive identical calls: `[A, A, A, A]`
- Repeating sequence cycles: `[A, B, C] [A, B, C] [A, B, C]`

Threshold is 3 repetitions. On trigger, a system reminder forces the agent to reconsider its approach.

**Our gap**: The drift decision gate handles plan-vs-reality divergence but does not address an agent cycling through the same actions without progress.

#### GAP 2: Structured error reflection (HIGH IMPACT)

ForgeCode's `forge-partial-tool-error-reflection.md` forces a three-step reflection after tool failure:

1. Pinpoint exactly what was wrong.
2. Explain why the mistake happened.
3. Make the corrected call.

**Our gap**: When automated verification fails, our framework routes to continue or return, but does not force an intermediate root-cause reflection step before retrying.

#### GAP 3: Retry budget with countdown (MEDIUM-HIGH IMPACT)

ForgeCode's `forge-tool-retry-message.md` provides explicit retry context with remaining attempts and a reminder to adjust approach before retrying.

**Our gap**: No retry budget exists. An agent can retry indefinitely or stop after one failure without structured guidance.

#### GAP 4: Context management guidance (MEDIUM-HIGH IMPACT)

ForgeCode has a more explicit compaction system:

- multiple triggers
- retention windows
- summary pipeline rules
- atomic tool-call preservation

**Our gap**: No explicit guidance tells an agent how to manage long-running context during extended research or implementation phases.

#### GAP 5: Intra-phase progress tracking (MEDIUM IMPACT)

ForgeCode mandates `todo_write` for multi-step tasks and measures compliance in evals.

**Our gap**: We track phase completion in artifacts, but not granular task progress within a phase.

#### GAP 6: Pre-implementation reasoning checkpoint (MEDIUM IMPACT)

ForgeCode explicitly forces reasoning before code changes and pairs that with heavier thinking earlier in a task.

**Our gap**: We have effort guidance, but no hard requirement to articulate approach and likely failure modes before editing.

#### GAP 7: Structured diagnostic for conflicting evidence (LOW-MEDIUM IMPACT)

ForgeCode leans on structured diagnostics rather than flat troubleshooting.

**Our gap**: `af-research` says to rank weak or conflicting evidence, but the template does not give a stronger structure for that.

### Patterns we already cover well

- **Decision algorithms as YES/NO gates**
- **Artifact-first working**
- **Automated vs manual verification separation**
- **Mismatch routing**
- **Entry-point discovery order**
- **Execution context guidance**
- **Cumulative drift tracking**

### Patterns that are runtime-level, not prompt-level

- **Policy engine for operation permissions**
- **Tool argument renaming**
- **Exponential backoff with jitter**
- **Token counting and automatic compaction triggers**
- **Subagent parallelization**

### New March 2026 correlation pass: public numbers moved faster than public writeups

- As of **2026-03-15**, the Terminal-Bench 2.0 leaderboard shows ForgeCode at **81.8%** on **2026-03-12** for both `GPT-5.4` and `Claude Opus 4.6`.
- ForgeCode's public benchmark post from **2026-03-03** still describes the earlier progression through **78.4%**.
- ForgeCode's public blog index did not show a later March benchmark writeup explaining the jump to **81.8%**.
- Conclusion: the most useful explanation for the March improvement is now the public repo history, not a later blog post.

### High-confidence repo-visible correlates for the 81.8 run

These are date-aligned inferences, not exact-causality claims, because the leaderboard does not publish the evaluated commit SHA.

#### 1. Doom-loop detection became a runtime hook

- **2026-03-11** `d1e0547500ac` `feat(app): add doom loop detector to prevent repetitive tool calls`
- Added `crates/forge_app/src/hooks/doom_loop.rs` and `templates/forge-doom-loop-reminder.md`
- Likely effect: fewer dead-end repeated tool trajectories under time pressure

#### 2. File discovery got faster, then safer

- **2026-03-04** `eafdac7065ab` `refactor(context-engine): use git ls-files instead of walker for file discovery`
- **2026-03-11** `e6dd682aadb7` and `7b3c74b849af` added fallback behavior when `git ls-files` fails or returns no files
- **2026-03-11** `1b114a439739` `fix(sync): handle error conditions in sync gracefully`
- Likely effect: faster indexing on normal repos without turning odd repos into hard failures

#### 3. Anthropic tool-call IDs were normalized before submission

- **2026-03-11** `23096dad33ad` `fix(vertex-anthropic): sanitize tool call IDs to match required pattern`
- Added `crates/forge_app/src/dto/anthropic/transforms/sanitize_tool_ids.rs`
- Likely effect: fewer provider-side `400` failures on valid tool trajectories

#### 4. `todo_write` became not just mandatory, but more deterministic

- **2026-03-05** `4f1ad6b33ffd` `feat(todo): add todo_write tool for task tracking`
- **2026-03-11** `970a75f8b172` `fix(todo): render todo diffs in strict id order with status-aware removed states`
- Likely effect: better task-tracking clarity and less context churn during long tasks

#### 5. Retry classification widened for request-level failures

- **2026-03-12** `3ce465e8189b` `fix(retry): treat request-level errors as retryable`
- Changed `crates/forge_repo/src/provider/retry.rs`
- Likely effect: fewer benchmark losses caused by transient provider or request-layer failures

### Secondary same-window candidates

- **2026-03-07** `340a75272340` `fix(codex): stop forcing low text verbosity`
  - Likely effect: better output quality for Codex/OpenAI Responses runs
- **2026-03-12** `c003c4b52b8c` `fix(tracker): add FORGE_TRACKER env var to disable enrichment`
  - Likely effect: cleaner, lower-overhead benchmark runs
- **2026-03-12** `70cba43c767b` `fix(attachment): use raw content hash to prevent false external-change warnings`
  - Likely effect: fewer false-positive recovery branches
- **2026-03-06 to 2026-03-08** model catalog updates (`a5eab212`, `85773b4c`)
  - Likely effect: correct `GPT-5.4` model selection and context metadata

### What the March 81.8 pass changes in the original interpretation

The earlier write-up correctly identified the big conceptual gaps, but the March repo history sharpens the priority order:

1. **Stuck-state recovery** moved from plausible idea to direct evidence.
2. **Task tracking** still matters, but deterministic rendering appears to matter too, not just tool availability.
3. **Fast entry-point discovery with safe fallback** looks more important than generic context advice.
4. **Retry classification and provider compatibility** can change benchmark outcomes even when the planning model is already good.

### Implications for the artifact-first workflow

Prompt-level patterns we can reuse directly:

- explicit stuck-state detection and recovery prompts
- mandatory and deterministic task tracking
- fast entry-point discovery before broad exploration
- structured reflection before retries

Runtime-only patterns we can imitate only partially:

- provider-specific request sanitization
- transport-level retry classification
- file-indexing implementation choices like `git ls-files`
- tracker and telemetry controls

## Ownership and boundaries

- Owning repo for the benchmarked runtime behavior: `antinomyhq/forge`
- Owning repo for the workflow changes we would make: `artifact-first-engineering-workflow`
- Relevant contract boundary: the leaderboard exposes score, model, and date, but not the exact evaluated commit SHA
- Relevant runtime boundary: ForgeCode's runtime behavior lives in Rust code; our workflow can only adopt the prompt-level analogues

## Evidence

- Terminal-Bench 2.0 leaderboard: `https://www.tbench.ai/leaderboard/terminal-bench/2.0`
- ForgeCode public homepage: `https://forgecode.dev/`
- ForgeCode benchmark post: `https://forgecode.dev/blog/benchmarks-dont-matter/`
- ForgeCode blog index: `https://forgecode.dev/blog/`
- ForgeCode repo: `https://github.com/antinomyhq/forge`
- Repo evidence from Forge:
  - `crates/forge_app/src/hooks/doom_loop.rs`
  - `templates/forge-doom-loop-reminder.md`
  - `templates/forge-partial-tool-error-reflection.md`
  - `templates/forge-tool-retry-message.md`
  - `templates/forge-partial-summary-frame.md`
  - `benchmarks/evals/todo_write_usage/task.yml`
  - `crates/forge_app/src/fmt/todo_fmt.rs`
  - `crates/forge_services/src/context_engine.rs`
  - `crates/forge_repo/src/provider/retry.rs`
  - `crates/forge_app/src/dto/anthropic/transforms/sanitize_tool_ids.rs`
- Local verification artifact:
  - clone inspected at `/tmp/forge-research-20260315`
- Prior local context:
  - `docs/exec-plans/active/harness-decision-algorithms.md`

## Technology versions and docs

- ForgeCode runtime:
  - Version evidence: `Cargo.toml` in `antinomyhq/forge` declares a Rust workspace at package version `0.1.0` with `rust-version = "1.92"`
  - Release-window evidence: tags `v1.30.0` on **2026-03-03**, `v1.32.0` on **2026-03-11**, `v1.32.1` on **2026-03-12**
  - Official docs consulted: ForgeCode homepage, blog index, benchmark post
  - Why the version match is credible: the inspected commit window aligns directly with the public score jump
- Our framework:
  - Version evidence: Markdown skills and templates in this repo
  - Official docs consulted: repo-local README, `af-research` references
  - Why the version match is credible: this task is about prompt-level workflow guidance, not a runtime library version

## Unknowns

- The leaderboard does not expose the exact Forge commit SHA, runtime config, or release tag used for the **2026-03-12** run
- ForgeCode's eval suite structure and exact `todo_write` compliance measurement are only partially visible in the OSS repo
- Exact per-technique impact is not published; the correlations here are date-based and mechanism-based
- Whether ForgeCode's progressive thinking budget works at the prompt level, or only because of runtime controls, remains unclear

## Planning readiness

Planning readiness: ready

The original gap analysis remains valid, and the March 2026 repo correlation pass adds stronger priority evidence rather than introducing planning blockers.

## Open questions

- No planning-blocking open questions remain from this pass.

## Decision notes

- Use the **plan artifact** as the canonical intra-phase task list. Use the status artifact as a checkpoint log for deltas, verification, and routing. For larger or branching work, use both, but keep the plan authoritative.
- Use a **3-attempt prompt-level retry budget**: original attempt plus up to 2 retries, with explicit root-cause reflection before retrying and a materially changed hypothesis before the final retry.
- Add stuck-state recovery guidance to **both** `af-implement` and `af-research`, with stricter routing in implementation and lighter mode-reassessment guidance in research.
- Add a lightweight prompt-level **fast path with safe fallback** rule: start with the highest-signal artifacts, broaden once to targeted source and tests if needed, then stop and declare uncertainty rather than wander.

## Recommended next step

Run `af-plan` using this merged artifact and the decision notes above. Prioritize the top prompt-level analogues of ForgeCode's strongest evidence:

1. Stuck-state detection and recovery
2. Structured error reflection before retry
3. Retry budget with countdown
4. Deterministic intra-phase task tracking
5. Pre-implementation reasoning checkpoint
6. Fast entry-point discovery with explicit fallback guidance
