# Phased Plan: QRSPI Adoption -- Incremental Evolution of Artifact-First Skills

## Goal

Adopt the highest-value patterns from HumanLayer's QRSPI methodology into the existing artifact-first skills, while preserving the strengths already in place (drift management, stuck-state detection, verification recovery, structured research modes, sufficiency gate).

## Design decisions

- **Q+D+S phases**: Embed as mandatory interactive steps within af-plan, not standalone skills. Invoking separate skills for each phase adds friction without benefit.
- **Inline research from af-plan**: When af-plan is invoked without a prior research artifact, delegate research to sub-agent(s) following af-research principles rather than stopping with a research request. af-plan becomes the single entry point for both PI and RPI work. Standalone af-research remains for pure discovery/audit use cases.
- **Lifecycle commands**: Add as new harness-agnostic skills (af-iterate, af-handoff). af-validate is not needed -- af-implement already handles per-phase verification with status artifacts, recovery protocol, and retry budget.
- **Handoff includes resume**: af-handoff has two modes (create and resume) in one skill rather than two separate skills, similar to how af-research has multiple modes.
- **Sub-agent architecture**: Adopt the principle of sub-agent delegation for context window management without defining specific agent types (locator/analyzer/pattern-finder).
- **Instruction budget**: Treat as a soft guideline (~40 instructions per step). If a skill goes over, reconsider structure -- but do not force compliance mechanically.
- **Worktree formalization**: Skip. Too much complexity for now.

## Scope

- Modify `skills/af-plan/SKILL.md` to embed Questioning, Design, and Structure as mandatory interactive steps, and add inline research delegation when no prior research artifact exists
- Add sub-agent delegation guidance to `skills/af-research/SKILL.md`
- Create two new lifecycle skills: `af-iterate`, `af-handoff` (with create and resume modes)
- Review `skills/af-implement/SKILL.md` for instruction budget (~138 lines, soft guideline of ~40 instructions per step)

## Non-goals

- Ralph-style automated ticket-to-PR pipelines
- Worktree formalization or multi-repo worktree management
- Defining specific agent types (locator/analyzer/pattern-finder) -- adopt the principle, not the taxonomy
- HumanLayer's `thoughts/` sync mechanism or `humanlayer launch` runtime
- Hard instruction-count enforcement -- treat as a soft guideline

## Phase status

- Phase 1: complete
- Phase 2: complete
- Phase 3: complete
- Phase 4: complete (reviewed, no changes needed)

## Implementation references

- Research artifact: `docs/research/qrspi-evolution-comparison.md`
- HumanLayer's bundled Q+D+S approach: research sections 4.2, 3 (Key insight)
- Instruction budget finding: research section 5 (Instruction Budget Comparison)
- Existing skill line counts: af-plan 114, af-research 136, af-implement 138

## Phases

### Phase 1: Embed inline research + Questioning + Design + Structure in af-plan

**Rationale**: This is the highest-value change. The research identified "bad research" (opinions instead of facts) and "bad plans" (skipped interactive steps) as the two RPI failure modes QRSPI fixes. The fix is front-loading human alignment into the planning workflow. Additionally, making af-plan the single entry point for both PI and RPI work (by delegating research inline when no prior artifact exists) matches HumanLayer's `create_plan.md` approach and removes the friction of requiring a separate research invocation.

**Changes**:

- `skills/af-plan/SKILL.md`:
  1. **Replace the Research Stop Condition** with an **Inline Research** section. Current behavior: if repo set, ownership, contracts, or rollout dependencies are unclear, emit a research request and stop. New behavior: if no prior research artifact is provided, delegate research to sub-agent(s) following af-research principles (document what IS, no opinions, bounded scope per delegation). The main agent waits for findings, then proceeds. If the research itself surfaces blockers that require human input (e.g., cannot determine ownership, conflicting evidence), surface those in the Questioning step rather than stopping silently.
  2. **Add an Interactive Alignment section** between the current Workflow and Planning Modes sections. This section defines three mandatory steps before writing the plan:
    - **Questioning**: After reading the task and research (whether from a prior artifact or inline delegation), present informed understanding and surface design decisions as explicit options (Q1: A or B? Q2: X or Y?). Do not proceed until the human selects directions.
    - **Design Discussion**: Present current state, desired end state, discovered patterns, and design options (Option A vs B with pros/cons) in-chat. This is a conversation, not a separate artifact. The human picks the direction. Resolved decisions get recorded in the plan's `## Design decisions` section.
    - **Structure Approval**: Create a plan outline with phased breakdown and get explicit approval ("Does this phasing make sense?") before writing the full plan.
  3. **Update the Workflow numbered list** to reflect the new flow: read task -> inline research if needed -> Questioning -> Design Discussion -> Structure Approval -> write plan.
- `skills/af-plan/references/phased-plan-template.md`: Add a `## Design decisions` section after Goal to record resolved Q+D outputs so they survive into the plan artifact.
- `skills/af-plan/references/mini-plan-template.md`: Add a lighter `## Key decisions` section (for PI work, the questioning step may resolve in one exchange).

**How the workflows change**:


| Scenario                         | Current behavior               | New behavior                                                           |
| -------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| RPI with prior research artifact | Read artifact, write plan      | Read artifact, Q+D+S interactive steps, write plan                     |
| RPI without prior research       | Emit research request and stop | Delegate research to sub-agent(s), Q+D+S interactive steps, write plan |
| PI (no research needed)          | Write plan directly            | Lighter Q+D+S (may resolve in one exchange), write plan                |


**Standalone af-research remains unchanged** -- it is still the right tool for pure discovery, audits, or when the user explicitly wants a research artifact without planning.

**Constraint**: af-plan is currently 114 lines. The inline research section replaces the existing Research Stop Condition (~8 lines), and the interactive alignment section adds ~20-25 lines. Target staying under ~150 lines total.

- Repo: `artifact-first-engineering-workflow`
- Files: `skills/af-plan/SKILL.md`, `skills/af-plan/references/phased-plan-template.md`, `skills/af-plan/references/mini-plan-template.md`

#### Automated verification

- `wc -l skills/af-plan/SKILL.md` stays under 150 lines
- All three mandatory interactive steps (Questioning, Design Discussion, Structure Approval) are present
- Inline research delegation guidance is present and references af-research principles
- Template changes are syntactically valid Markdown

#### Manual verification

- Read the modified af-plan and confirm the flow is: read task -> inline research if needed -> Q -> D -> S -> write plan
- Confirm the interactive alignment steps are clear, sequenced correctly, and do not duplicate existing workflow steps
- Confirm the steps apply differently for mini-plan vs phased plan (lighter touch for PI work)
- Confirm standalone af-research is not made redundant -- af-plan delegates research, it does not replace af-research

---

### Phase 2: Add sub-agent delegation guidance to af-research

**Rationale**: The research found HumanLayer's hub-and-spoke sub-agent architecture keeps the main agent's context focused on synthesis. The resolved decision: adopt the principle of sub-agent delegation for context window management without defining specific agent types.

**Changes**:

- `skills/af-research/SKILL.md`: Add a **Sub-Agent Delegation** section after the Workflow section (~15-20 lines). Content:
  - When research scope is broad (multiple repos, large codebase surface), delegate bounded discovery and analysis questions to sub-agents rather than consuming main context on raw exploration.
  - Each delegation should have a clear question, a bounded scope, and return compact findings (not raw file dumps).
  - The main agent synthesizes sub-agent findings into the research artifact.
  - Sub-agents must follow the same "document what IS, no opinions" rule as the main research pass.
  **Constraint**: af-research is currently 136 lines. Target staying under ~160 lines.
- Repo: `artifact-first-engineering-workflow`
- Files: `skills/af-research/SKILL.md`

#### Automated verification

- `wc -l skills/af-research/SKILL.md` stays under 160 lines

#### Manual verification

- Read the sub-agent delegation section and confirm it is principle-based (not prescribing specific agent types or providing fill-in-the-blank templates)
- Confirm the guidance is additive and does not conflict with existing workflow steps or the sufficiency gate

---

### Phase 3: Create lifecycle skills (af-iterate, af-handoff)

**Rationale**: The research identified workflow gaps in plan iteration and cross-session continuity. These address real workflow needs the current skills do not cover.

**Why not af-validate**: Our af-implement already runs automated verification per phase, records results in status artifacts, has a verification recovery protocol with retry budget, and the plan templates have explicit exit criteria. HumanLayer needs a separate validate command because their implement is deliberately simpler. Ours already covers this ground.

**Changes**:

**3a. `skills/af-iterate/SKILL.md`** (new skill):

- Purpose: Surgical updates to existing plans based on feedback. Not a full re-plan.
- Workflow: Read the existing plan and the feedback/change request. Assess whether changes require new research (if so, delegate research inline following af-research principles, same as af-plan does). Otherwise, update only the affected sections of the plan. Preserve completed phases unless the change invalidates them.
- Distinct from af-plan's re-planning guidance: af-iterate is for updating a plan that is still valid in structure but needs targeted revisions, while `I -> P` re-planning handles cases where implementation discovered the plan was wrong.

**3b. `skills/af-handoff/SKILL.md`** (new skill):

- Purpose: Structured context transfer between agent sessions.
- Two modes, similar to how af-research has multiple modes:
  - **Create**: Produce a compact handoff document capturing: current task state, critical file references, recent changes (with commit refs), key decisions made, open items, and next actions.
  - **Resume**: Read a handoff document, verify current state against what the handoff describes, and present a status assessment before proceeding.
- Output: `references/handoff-template.md`.

Each new skill gets a `SKILL.md` with frontmatter, a `references/` directory, and relevant templates. The install script (`scripts/install.sh`) auto-discovers `skills/*` directories, so no install script changes are needed.

**Constraint**: Each new skill should be under ~80 lines to start. Keep them minimal and let usage reveal what needs to be added.

- Repo: `artifact-first-engineering-workflow`
- Files (all new):
  - `skills/af-iterate/SKILL.md`
  - `skills/af-handoff/SKILL.md`, `skills/af-handoff/references/handoff-template.md`

#### Automated verification

- Each new `SKILL.md` has valid YAML frontmatter (name, description fields)
- Each new skill directory has the expected structure (`SKILL.md` + `references/`)
- `wc -l` on each new `SKILL.md` is under 80 lines

#### Manual verification

- Read each new skill and confirm it is harness-agnostic (no Claude Code-specific language, no tool-specific references)
- Confirm af-iterate and af-handoff do not overlap with each other or with existing skills
- Confirm the handoff template is compact enough to be useful across sessions (not a context dump)
- Confirm af-handoff's create and resume modes are clearly distinguished

---

### Phase 4: Review af-implement for instruction budget

**Rationale**: af-implement at 138 lines has the most instruction density. The research suggests ~40 instructions per step as a soft guideline. The goal is not mechanical compliance but reconsidering whether any sections could be clearer through restructuring.

**Changes**:

- Review `skills/af-implement/SKILL.md` for opportunities to:
  - Extract the Drift Decision Gate examples into a reference file (e.g., `references/drift-examples.md`) to reduce SKILL.md line count without losing the guidance
  - Tighten wording where possible without losing precision
  - Add section headers or step markers that help the agent focus on the currently relevant instructions rather than processing the whole file at once
- Do NOT remove any existing guidance (drift gate, stuck-state, verification recovery, contract vs detail). These are identified strengths.
- Do NOT force compliance with a hard line count. If the skill reads clearly after light editing, leave it.

**Constraint**: This phase is editorial, not structural. If review finds the skill is already well-structured, the outcome is "reviewed, no changes needed" and that is a valid result.

- Repo: `artifact-first-engineering-workflow`
- Files: `skills/af-implement/SKILL.md`, possibly `skills/af-implement/references/drift-examples.md` (new, only if extraction helps)

#### Automated verification

- `wc -l skills/af-implement/SKILL.md` (record before and after)
- If a new reference file is created, verify it is referenced from SKILL.md

#### Manual verification

- Read the modified af-implement and confirm no guidance was lost
- Confirm any extracted reference material is still discoverable by an agent following the skill

## Rollback

- All changes are additive Markdown edits in a single repo with no runtime dependencies.
- Git revert of the implementation commits restores the prior state.
- New skill directories can be removed and re-running `scripts/install.sh` will clean up symlinks (they will point to missing targets, which the script handles gracefully on next run).

## Exit criteria

- af-plan includes inline research delegation (no more "stop and emit research request") and mandatory Questioning, Design Discussion, and Structure Approval steps with clear differentiation for PI vs RPI work
- af-research includes principle-based sub-agent delegation guidance
- Two new lifecycle skills (af-iterate, af-handoff with create/resume modes) exist with SKILL.md and templates
- af-implement has been reviewed for instruction budget; outcome documented even if no changes made
- All existing strengths (drift management, stuck-state detection, verification recovery, structured research modes, sufficiency gate) are preserved
- No skill exceeds ~160 lines without clear justification

