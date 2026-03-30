# Research: QRSPI Evolution from RPI -- Comparison and Migration Assessment

## Objective

What is Dexter Horthy's QRSPI methodology, how does it compare to the RPI workflow implemented in this repo, and what would migrating to QRSPI require?

## Scope

- In-scope: this repo's three skills (`af-research`, `af-plan`, `af-implement`), Horthy's QRSPI methodology as described publicly and implemented in `humanlayer/humanlayer/.claude/commands/`
- Out-of-scope: Obra plugin internals, other agentic frameworks, HumanLayer's proprietary `humanlayer launch` runtime

## Background

Dexter Horthy (founder of HumanLayer, author of 12-Factor Agents) originally championed the RPI (Research, Plan, Implement) decomposition for agentic coding. After deploying RPI across teams, HumanLayer identified systematic failure modes and evolved the methodology. Horthy presented the result -- QRSPI -- at the Coding Agents 2026 conference in Mountain View, CA.

The name QRSPI is a compressed acronym. The actual pipeline is **seven steps**: Questions, Research, Design, Structure, Plan, Worktree, Implement. The full acronym (QRDSPWI) was unwieldy, so the team picked a subset.

HumanLayer's concrete implementation lives at `github.com/humanlayer/humanlayer` in `.claude/commands/` as 27 Claude Code slash commands.

## Findings

### 1. Why RPI Failed in Practice

HumanLayer identified two specific, diagnosable failures when deploying RPI across engineering teams:

**Bad research.** A skilled engineer would naturally break a ticket into targeted codebase questions. Most users would paste the entire ticket into the research tool and get back opinions instead of facts. Horthy: "If you tell the model what you're building, you get opinions. The model starts making implementation decisions instead of proposing options." A single subagent handled a broad, open-ended prompt while consuming roughly 40% of the context window just for orientation.

**Bad plans.** HumanLayer's planning prompt had 85+ instructions with critical interactive steps ("present design options to the user," "get feedback before writing the plan") buried inside. For about half of users, the agent would skip these steps and deliver a finished plan with all decisions pre-made. Horthy: "When we investigated, we found the difference between good and bad results was a single line" -- the instruction to work back and forth with the user before writing the plan.

**Root cause -- instruction budget.** HumanLayer's co-founder Kyle discovered frontier LLMs can only follow 150-200 instructions consistently. With 85 in the planning prompt alone, plus system prompts, tool definitions, and MCP servers, the model was over budget.

### 2. The QRSPI Pipeline (7 Steps)

Each step operates with **fewer than 40 instructions**. The design front-loads human alignment into two short artifacts rather than reviewing 1,000+ lines of generated code.

| Step | Purpose | Key output |
|------|---------|------------|
| **Questions** | Surface design decisions as explicit options before research starts | Structured questions with options (Q1: A, B, or C?) |
| **Research** | Compression of truth -- distill codebase reality with no opinions | Factual findings, no implementation suggestions |
| **Design** | Capture current state, desired end state, patterns found, resolved decisions, open questions | Design Discussion (~200 lines) |
| **Structure** | Mandatory phased breakdown -- "how we get there" vs Design's "where we're going" | Structure Outline (~2 pages) |
| **Plan** | Detailed implementation plan, interactive with fewer instructions | Phase-level plan |
| **Worktree** | Git worktree isolation for implementation | Isolated branch |
| **Implement** | Code generation using smaller models for writing/testing, larger model for spot-checking | Working code |

### 3. How QRSPI Maps to HumanLayer's Actual Commands

The 7-step conceptual pipeline does not map 1:1 to standalone commands. Some QRSPI phases are **embedded within a single command** rather than split into separate files:

| QRSPI Phase | HumanLayer Command(s) | How it works |
|-------------|----------------------|--------------|
| **Questions** | Embedded in `create_plan.md` Step 1-2 | Agent reads ticket, spawns parallel research sub-agents, then presents "informed understanding and focused questions" and "design options" **before** writing any plan. Not a separate command. |
| **Research** | `research_codebase.md` (+ `_nt`, `_generic` variants) | Standalone command. Agent decomposes question, spawns parallel sub-agents (codebase-locator, codebase-analyzer, codebase-pattern-finder), synthesizes findings into a dated research document. **CRITICAL rule: "YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN THE CODEBASE AS IT EXISTS TODAY"** -- no opinions, no improvements, no recommendations. |
| **Design** | Embedded in `create_plan.md` Step 2 | After research sub-agents return, agent presents "Design Options" (Option A pros/cons, Option B pros/cons) and open questions. The human picks the direction. |
| **Structure** | Embedded in `create_plan.md` Step 3 | Agent creates a plan outline with phased structure and gets explicit approval: "Does this phasing make sense? Should I adjust the order or granularity?" Only after approval does it write the full plan. |
| **Plan** | `create_plan.md` Step 4, `iterate_plan.md`, `validate_plan.md` | Full plan written to `thoughts/shared/plans/YYYY-MM-DD-ENG-XXXX-description.md`. Separate iterate and validate commands for refinement. |
| **Worktree** | `create_worktree.md` | Creates git worktree via `hack/create_worktree.sh`, then launches an isolated implementation session: `humanlayer launch --model opus -w ~/wt/humanlayer/ENG-XXXX "/implement_plan at $FILEPATH..."` |
| **Implement** | `implement_plan.md` | Reads plan, implements phase by phase, runs automated verification, pauses for manual verification per phase, updates plan checkboxes. |

**Key insight**: The Questioning, Design, and Structure phases that Horthy emphasizes as the "new" parts of QRSPI are all embedded within `create_plan.md` as mandatory interactive steps rather than standalone commands. The decomposition is conceptual (7 steps) but the implementation bundles Q+D+S+P into one interactive command with explicit pause points.

### 4. Concrete Implementation Patterns from HumanLayer

#### 4.1 Research Architecture

HumanLayer's research command (`research_codebase.md`) uses a **hub-and-spoke sub-agent architecture**:

- **Main agent**: orchestrator that decomposes, delegates, and synthesizes
- **codebase-locator**: finds WHERE files and components live
- **codebase-analyzer**: understands HOW specific code works (without critiquing)
- **codebase-pattern-finder**: finds examples of existing patterns (without evaluating)
- **thoughts-locator/analyzer**: discovers and extracts from historical knowledge base
- **web-search-researcher**: external research (only when explicitly requested)
- **linear-ticket-reader/searcher**: ticket management integration

All agents are **documentarians, not critics**. They describe what exists without suggesting improvements.

These agents are defined in `.claude/agents/` (not `.claude/commands/`):

| Agent | Model | Tools | Role |
|-------|-------|-------|------|
| `codebase-locator` | sonnet | Grep, Glob, LS | Find WHERE files and components live. "Creating a map of the existing territory, not redesigning the landscape." Does not read file contents deeply -- just scans for relevance and organizes by purpose. |
| `codebase-analyzer` | (not specified, likely opus) | Read + search tools | Document HOW specific code works. Three-step: read entry points, follow code paths, document key logic. Requires file:line citations. "Surgical precision." |
| `codebase-pattern-finder` | sonnet | Grep, Glob, Read, LS | Find similar implementations, usage examples, and existing patterns. Like codebase-locator but also extracts code details. Shows working code with context and variations. |
| `thoughts-locator` | sonnet | Grep, Glob, LS | Discover relevant documents in `thoughts/` directory. Scans across shared/, personal, and global directories. Categorizes by type (tickets, research, plans, PRs, notes). Does not read deeply. |
| `thoughts-analyzer` | (not specified) | Read + search tools | Extract key insights from specific thoughts documents. Quality-filtered extraction from the most relevant documents only. |
| `web-search-researcher` | sonnet | WebSearch, WebFetch, TodoWrite, Read, Grep, Glob, LS | External web research. Strategic multi-angle searches, fetches full content from promising results, synthesizes with source attribution. Only used when explicitly requested. |

Key design patterns in the agent architecture:
- **Locators use sonnet** (fast, cheap) for breadth-first discovery
- **Analyzers use larger models** for depth-first understanding
- **Strict role separation**: locators find, analyzers understand, pattern-finders show examples
- **"Documentarian, not critic" constraint** is repeated in every agent definition
- **No agent suggests improvements** -- this is enforced at the agent level, not just the command level

Research outputs go to `thoughts/shared/research/YYYY-MM-DD-ENG-XXXX-description.md` with YAML frontmatter (date, researcher, git_commit, branch, repository, topic, tags, status).

#### 4.2 Planning Architecture

`create_plan.md` implements the Questioning, Design, Structure, and Plan phases as sequential interactive steps within a single command:

1. **Context Gathering**: Read ticket/files fully in main context, then spawn parallel research sub-agents
2. **Informed Questioning**: Present understanding with file:line references, ask only questions the agent could not answer through code investigation
3. **Design Options**: Present current state, discovered patterns, and design options (A vs B with pros/cons)
4. **Structure Approval**: Create plan outline with phases, get explicit approval before writing details
5. **Detailed Plan**: Write full plan with automated and manual verification separated per phase

The plan template has these key sections:
- Overview, Current State Analysis, Desired End State
- "What We're NOT Doing" (explicit scope exclusion)
- Phases with: changes required (file + code), automated verification (commands), manual verification (human steps)
- Testing strategy, performance considerations, migration notes, references

**CRITICAL rule**: "No Open Questions in Final Plan" -- if unresolved questions exist, stop and research/ask immediately. The plan must be complete and actionable.

#### 4.3 Implementation Architecture

`implement_plan.md` is notably **simpler** than our `af-implement`:

- Read plan completely, check for existing checkmarks
- Implement each phase fully before moving to the next
- Run automated verification (usually `make check test`)
- Pause for human manual verification per phase with a structured message
- Update checkboxes in the plan file
- On mismatch: STOP, present Expected vs Found vs Why it matters, ask how to proceed
- Resume: trust existing checkmarks, pick up from first unchecked item

No drift decision gate, no stuck-state detection, no retry budget, no contract vs. detail distinction. The mismatch handling is conversational ("How should I proceed?") rather than mechanical.

#### 4.4 Lifecycle Commands (Beyond Core RPI)

HumanLayer has several commands we have no equivalent for:

| Command | Purpose |
|---------|---------|
| `iterate_plan.md` | Surgical updates to existing plans based on feedback. Spawns research only if changes require new technical understanding. |
| `validate_plan.md` | Post-implementation validation: verify all plan phases completed, run automated checks, generate validation report with pass/fail per criterion. |
| `create_handoff.md` | Compact context handoff document for cross-session continuity. Sections: Tasks, Critical References, Recent Changes, Learnings, Artifacts, Action Items. |
| `resume_handoff.md` | Resume work from a handoff document. Reads handoff, spawns verification sub-agents, presents current state analysis, gets confirmation before proceeding. |
| `create_worktree.md` | Git worktree creation + automated `humanlayer launch` of isolated implementation session. |
| `founder_mode.md` | Post-hoc ticketing for experimental features after implementation. |
| `local_review.md` | Set up isolated worktree to review a colleague's branch. |

#### 4.5 Automated Pipeline ("Ralph")

Three `ralph_*` commands form an automated pipeline triggered from Linear tickets:

- `ralph_research.md`: Fetch highest-priority "research needed" ticket, conduct research, output to `thoughts/shared/research/`, move ticket to "research in review"
- `ralph_plan.md`: Fetch highest-priority "ready for spec" ticket, create plan, move to "plan in review"
- `ralph_impl.md`: Fetch highest-priority "ready for dev" ticket, create worktree, launch `humanlayer launch --model opus` with implement_plan, commit, PR, and Linear comment

The `oneshot.md` command chains: `/ralph_research` then spawns a new session with `humanlayer launch` for `/oneshot_plan` (which chains `/ralph_plan` then `/ralph_impl`).

This is a full ticket-to-PR automation pipeline with human review gates at "research in review" and "plan in review" statuses.

#### 4.6 Model Stratification

Concrete evidence of model stratification in the commands:

- `research_codebase.md` and `research_codebase_nt.md`: `model: opus` (bigger model for research)
- `ralph_impl.md`: `model: sonnet` (smaller model for orchestration/ticket fetching)
- Implementation sessions launched with `--model opus` (bigger model for code writing)
- Horthy's statement: "Our implementer agent uses faster, smaller models for writing the code and running the tests, and then a bigger, smarter model spot checks changes"

#### 4.7 "Thoughts" Knowledge Base

HumanLayer uses a `thoughts/` directory as a persistent, synced knowledge base:

- `thoughts/shared/research/` -- research artifacts
- `thoughts/shared/plans/` -- implementation plans
- `thoughts/shared/handoffs/ENG-XXXX/` -- session handoff documents
- `thoughts/shared/tickets/` -- fetched Linear tickets
- Synced via `humanlayer thoughts sync`
- Searchable via `thoughts/searchable/` (hard links)
- YAML frontmatter on all documents for metadata

This is analogous to our `docs/` tree and `engineering-context/` shared layout, but with automatic sync and session-to-session continuity via handoffs.

### 5. Phase-by-Phase Comparison: Our RPI vs. QRSPI Implementation

#### Phases We Lack

| QRSPI phase | Our equivalent | Gap | HumanLayer implementation |
|-------------|---------------|-----|---------------------------|
| **Questions** | None | We have no pre-research questioning step. Research begins with a restatement of the task as a research question (step 1 in `af-research`), but does not surface design decisions as explicit options for the human before investigating. | Embedded in `create_plan.md` Steps 1-2. Agent reads ticket, spawns research sub-agents, then presents informed understanding and focused questions before proceeding. |
| **Design** | None (partially in plan) | We have no standalone design artifact. Our `af-plan` jumps from research findings directly to plan structure. The design discussion (~200 lines capturing current state, desired end state, patterns, resolved decisions, open questions) has no equivalent. | Embedded in `create_plan.md` Step 2. Agent presents "Design Options" with pros/cons after research. Human picks direction. |
| **Structure** | Implicit in plan modes | Our plan skill distinguishes mini-plan from phased plan and has size heuristics, but the structure outline is not a separate, mandatory approval step. | Embedded in `create_plan.md` Step 3. Agent creates plan outline, gets explicit approval ("Does this phasing make sense?") before writing details. |
| **Worktree** | None in skills | Git worktree isolation is not addressed by any skill. | `create_worktree.md` creates worktree and launches isolated `humanlayer launch` session with full implement+commit+PR pipeline. |
| **Validate** | None | No post-implementation validation command. | `validate_plan.md` checks all phases completed, runs automated verification, generates structured validation report. |
| **Iterate** | Re-planning in `af-plan` | Our re-planning guidance exists but as part of the plan skill, not a standalone operation. | `iterate_plan.md` is a separate command for surgical plan updates with optional research if changes require it. |
| **Handoff** | None | No cross-session continuity mechanism. | `create_handoff.md` + `resume_handoff.md` for structured context transfer between agent sessions. |

#### Phases We Have

| Our phase | QRSPI equivalent | Comparison |
|-----------|-------------------|------------|
| **af-research** | `research_codebase.md` | Similar "document what IS" philosophy. Our mode selection (discovery -> boundary tracing -> contract validation -> rollout validation) adds methodological structure HumanLayer lacks. Our boundary checklist and sufficiency gate are more rigorous. HumanLayer's sub-agent architecture (locator/analyzer/pattern-finder) is more operationally sophisticated for large codebases. |
| **af-plan** | `create_plan.md` | HumanLayer's plan command embeds Q+D+S phases as mandatory interactive steps, which we lack. Our plan skill has richer structural features: mini-plan vs. phased plan distinction, size heuristics, research stop condition, re-planning after implementation feedback, workflow path notation. HumanLayer enforces "No Open Questions in Final Plan" absolutely. |
| **af-implement** | `implement_plan.md` | Our implementation skill is **significantly** more detailed: drift decision gate (5 sequential YES/NO checks), mismatch policy with contract vs. detail distinction, version drift handling, cumulative drift detection, stuck-state gate, verification recovery protocol with 3-attempt retry budget, autonomous vs. interactive execution context. HumanLayer's implementation is deliberately simpler -- mismatch handling is conversational ("How should I proceed?") rather than mechanical. |

#### Instruction Budget Comparison

The <40 instruction budget applies **per step within a command**, not per command file. Each step in a multi-step command has different rules that are not all active simultaneously -- the agent only needs to follow the instructions for the step it is currently executing. This makes the budget feasible even for long command files like `create_plan.md` (5 steps, each under 40 instructions, even though the total file is 100+).

This reframing changes the comparison:

| | HumanLayer approach | Our approach |
|---|---|---|
| **Unit of instruction budget** | Per step within a command (e.g., Step 3 of `create_plan.md`) | Per skill file (entire `af-plan` SKILL.md) |
| **How phases decompose** | Multiple steps in one command file, agent moves through sequentially | One skill file per phase, agent invoked per skill |
| **Budget pressure** | Distributed across steps -- each step is small | Concentrated in one file -- entire skill must fit |

Our `af-implement` at ~55-65 instructions is the most over-budget because all its guidance (drift gate, stuck-state, verification recovery) is in a single file with no step decomposition.

### 6. What Our RPI Does Better

- **Structured research modes.** Our mode selection (discovery -> boundary tracing -> contract validation -> rollout validation) with progressive escalation is more systematic than HumanLayer's open-ended "provide your research question" approach.
- **Sufficiency gate.** Explicit boundary checklist with verified/unknown annotations before declaring readiness. HumanLayer has no equivalent gate.
- **Drift management.** Our 5-question drift decision gate, contract vs. detail distinction, version drift handling, and cumulative drift detection are substantially more detailed. HumanLayer's implement command uses conversational mismatch handling ("How should I proceed?").
- **Stuck-state detection.** Explicit doom-loop detection (identical actions, repeating cycles) with forced approach change. HumanLayer has no equivalent.
- **Verification recovery.** Structured 3-attempt protocol with root cause analysis and material hypothesis change requirement. HumanLayer's approach: "fix any issues before proceeding."
- **Plan-level workflow notation.** Explicit workflow paths (`PI`, `RPI`, `I -> P`, `I -> R -> P`) with re-planning guidance.
- **Artifact placement discipline.** Detailed repo-local and cross-repo layout conventions.
- **Single-file skill simplicity.** Each of our skills is one file with one concern. HumanLayer's multi-step commands are longer files, though the per-step instruction counts within each are comparable to our per-skill counts.

### 7. What QRSPI / HumanLayer Does Better

- **Pre-research questioning.** Surfacing design decisions as explicit options before burning context on research. This prevents the "paste the whole ticket and get opinions" failure mode.
- **Design artifact.** A standalone, human-reviewable artifact that forces the agent to externalize its understanding before planning. This is the "brain surgery" step.
- **Structure as a mandatory approval gate.** Making the phased breakdown a mandatory checkpoint ("Does this phasing make sense?") before writing the full plan.
- **Sub-agent architecture for research.** Specialized agents (locator, analyzer, pattern-finder) running in parallel keep the main agent's context focused on synthesis.
- **Lifecycle commands.** `validate_plan`, `iterate_plan`, `create_handoff`, `resume_handoff` address real workflow needs our skills don't cover.
- **Automated pipeline.** The `ralph_*` commands + `oneshot` create a ticket-to-PR automation with human review gates at status transitions.
- **Cross-session continuity.** Handoff documents and the `thoughts/` knowledge base provide structured context transfer between agent sessions.
- **Worktree isolation.** Formalizing when and how to use git worktrees for implementation keeps the main repo clean.
- **"What We're NOT Doing" section.** Explicit scope exclusion in plans prevents scope creep.
- **Model stratification.** Using Sonnet for orchestration, Opus for research and implementation.

## Ownership and Boundaries

- This repo owns the skill definitions and templates. Changes are self-contained.
- No external service dependencies.
- No contract or runtime boundaries involved.
- The comparison is against HumanLayer's public repo at `github.com/humanlayer/humanlayer/.claude/commands/`.

## Evidence

- Primary source: [The Necessary Evolution of "Research, Plan, Implement" as an Agentic Practice in 2026](https://betterquestions.ai/the-necessary-evolution-of-research-plan-implement-as-an-agentic-practice-in-2026/)
- Deep dive: [Making AI Agents Mainstream with Dexter Horthy](https://thehumansintheloop.substack.com/p/making-agents-mainstream-for-dev-with-dexter-horthy) (The Humans in the Loop)
- Context engineering background: [Advanced Context Engineering for Coding Agents](https://dev.to/ametel01/advanced-context-engineering-for-coding-agents-11p7)
- **Implementation source**: [HumanLayer .claude/commands/](https://github.com/humanlayer/humanlayer/tree/main/.claude/commands) -- 27 Claude Code slash commands
- **Sub-agent definitions**: [HumanLayer .claude/agents/](https://github.com/humanlayer/humanlayer/tree/main/.claude/agents) -- 6 specialized agents (codebase-locator, codebase-analyzer, codebase-pattern-finder, thoughts-locator, thoughts-analyzer, web-search-researcher)
- Key commands read in full: `research_codebase.md`, `create_plan.md`, `implement_plan.md`, `iterate_plan.md`, `validate_plan.md`, `create_worktree.md`, `create_handoff.md`, `resume_handoff.md`, `ralph_research.md`, `ralph_plan.md`, `ralph_impl.md`, `oneshot.md`, `oneshot_plan.md`, `founder_mode.md`, `local_review.md`, `research_codebase_nt.md`, `research_codebase_generic.md`, `create_plan_generic.md`
- Repo skills: `skills/af-research/SKILL.md`, `skills/af-plan/SKILL.md`, `skills/af-implement/SKILL.md`

## Technology Versions and Docs

- Not applicable -- this is a pure Markdown methodology framework with no runtime dependencies.
- HumanLayer uses `humanlayer launch` (their CLI tool) and `humanlayer thoughts sync` for runtime orchestration, which we would not adopt.

## Unknowns

- **"thoughts" sync mechanism.** How `humanlayer thoughts sync` works under the hood -- whether it's git-based, uses a separate service, or something else.
- **Ralph pipeline reliability.** No public data on how well the automated ticket-to-PR pipeline works in practice.
- **codebase-analyzer model.** The agent definition does not specify a model (unlike locator/pattern-finder which specify sonnet). It likely uses opus or inherits from the parent session.

None of these unknowns block planning.

## Planning Readiness

Planning readiness: ready

## Open Questions (Resolved)

All open questions have been resolved through discussion:

- **Q+D+S phases**: Embed as mandatory interactive steps within `af-plan`, not standalone skills. Invoking separate skills for each phase adds friction without benefit.
- **Lifecycle commands**: Yes, add as new harness-agnostic skills. All skills should remain harness-agnostic.
- **Sub-agent architecture**: Do not define specific agent types (locator/analyzer/pattern-finder) -- from experience, defining different agents does not provide meaningful benefit. However, adopt the principle of using sub-agents for context window management. Consider providing pre-defined prompt templates that guide the agent when delegating to sub-agents.
- **"What We're NOT Doing"**: Already covered by our existing `## Non-goals` section in plan templates. No change needed.
- **Worktree formalization**: Skip for now. Multi-repo worktree management adds too much complexity.
- **Instruction budget**: Treat as a soft guideline, not a hard rule. If a skill goes over ~40 instructions, stop and reconsider whether the approach needs restructuring -- but don't force compliance mechanically.

## Recommended Next Step

Move to planning with incremental adoption:

1. **Modify `af-plan`**: Add Questioning + Design + Structure as mandatory interactive steps in the planning workflow (matching HumanLayer's bundled approach).
2. **Add sub-agent delegation guidance**: Add context-window-aware sub-agent usage guidance to `af-research` with optional pre-defined prompt templates for delegation.
3. **Add lifecycle skills**: Create new harness-agnostic skills for plan validation, plan iteration, and session handoff.
4. **Apply instruction budget guideline**: Review `af-implement` (~55-65 instructions) for possible step decomposition.
5. **Preserve existing strengths**: Keep drift management, stuck-state detection, verification recovery, structured research modes, and sufficiency gate.
