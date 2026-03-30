---
name: af-handoff
description: structured context transfer between agent sessions. use when ending a session with incomplete work (create mode) or starting a session that continues prior work (resume mode). produces compact handoff documents that capture task state, decisions, and next actions without dumping raw context.
---

# Artifact-First Handoff

## Overview

Transfer working context between agent sessions so that continuity does not depend on conversation history. Handoff documents are compact, decision-focused artifacts -- not context dumps.

Two modes:

- **Create**: produce a handoff document when ending a session with incomplete work.
- **Resume**: read a handoff document and verify current state before continuing.

### Mode Selection

- Work is incomplete and the session is ending -> **create**.
- Starting a session with a handoff document from a prior session -> **resume**.

## Create Mode

### Workflow

1. Read the current plan and any status artifacts.
2. Identify the current task state: what phase, what step within the phase, what is done and what remains.
3. Gather critical file references: files changed, files that need changing, key files for context.
4. Collect recent changes with commit refs (use `git log --oneline` for the relevant range).
5. List key decisions made during this session and their rationale.
6. List open items: unresolved questions, known issues, deferred work.
7. State the next actions clearly -- what the resuming agent should do first.
8. Write the handoff document using `references/handoff-template.md`.

### Rules

- Keep the document under ~60 lines. If it is longer, you are including too much raw context.
- Reference files and commits by path and hash, do not inline their contents.
- Decisions should include rationale, not just the choice.
- Next actions should be specific enough that the resuming agent does not need to re-derive them.

## Resume Mode

### Workflow

1. Read the handoff document completely.
2. Read the referenced plan and status artifacts.
3. Verify current state against the handoff:
   - Do the referenced files still exist and match expectations?
   - Do the referenced commits exist in the current branch?
   - Is the plan status consistent with what the handoff describes?
4. Present a brief status assessment: what matches, what has changed since the handoff, and the recommended first action.
5. If state has diverged significantly, flag the divergence before proceeding.

### Rules

- Do not blindly trust the handoff. Verify before acting.
- If the handoff references files or commits that no longer exist, flag this immediately.
- If the plan has been updated since the handoff was created, use the plan as the authority and note the handoff is stale.

## Output

- Use `references/handoff-template.md` for create mode.
- Resume mode produces an in-chat status assessment, not a separate artifact.
