---
name: af-archive
description: archive a completed or abandoned initiative by removing worktrees, cleaning up branches, and moving the initiative folder from active to archive. use when an initiative is merged, abandoned, or otherwise finished and its workspace should be torn down.
---

# Artifact-First Archive

## Overview

Clean up the workspace for a completed or abandoned initiative. This skill removes git worktrees, deletes local branches safely, and moves the initiative folder from `active/` to `archive/` in the shared engineering context.

## Workflow

Run the installed `af-archive` helper script to perform the archival:

```bash
$HOME/.agents/skills/af-archive/scripts/archive-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  [--jobs <N>] [--yes] <NNNN or folder-name>
```

The script handles the full lifecycle:

1. Resolves the initiative by sequence number or folder name.
2. Scans repo worktree lists for branches and worktree paths that match the initiative's exact `NNNN-<initiative>` worktree name, then checks matching worktrees for uncommitted changes and unpushed commits. The scan runs in parallel with an auto-selected worker count capped at 8, or a user-provided `--jobs <N>` override.
3. Presents an archive plan and prompts for confirmation (unless `--yes` is passed after a clean safety scan).
4. Removes each worktree via `git worktree remove`.
5. Deletes local branches with `git branch -d` (safe delete; failed deletes remain for manual follow-up).
6. Moves the initiative folder from `active/` to `archive/`.

If no repo under `<REPOS_ROOT>` has a matching worktree for the initiative, the script skips worktree removal and proceeds to archiving the initiative folder.

Pass the repo and context roots explicitly on every invocation.

## Safety Checks

Before any destructive action:

- **Uncommitted changes**: list them and stop before removal; clean, commit, or stash them before retrying.
- **Unpushed commits**: list them and require explicit user confirmation to proceed.
- **Unmerged branches**: `git branch -d` will fail for unmerged branches. Report the failure and leave the branch for manual follow-up.

Never force-delete branches or discard uncommitted work.

## Rules

- Confirm with the user before removing worktrees or deleting branches, unless `--yes` is used after a clean safety scan.
- Preserve the initiative's sequence number when moving to `archive/`.
- Do not delete the initiative folder -- move it.
- Do not modify any files inside the initiative folder during archival.
- If any safety check fails and the user does not confirm, stop and report what was skipped.
