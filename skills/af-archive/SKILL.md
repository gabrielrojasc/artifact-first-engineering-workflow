---
name: af-archive
description: archive a completed or abandoned initiative by removing worktrees, cleaning up branches, and moving the initiative folder from active to archive. use when an initiative is merged, abandoned, or otherwise finished and its workspace should be torn down.
---

# Artifact-First Archive

## Overview

Clean up the workspace for a completed or abandoned initiative. This skill removes git worktrees, optionally deletes local and remote branches, and moves the initiative folder from `active/` to `archive/` in the shared engineering context.

## Workflow

Run the installed `af-archive` helper script to perform the archival:

```bash
$HOME/.agents/skills/af-archive/scripts/archive-initiative.sh \
  --repos-root <REPOS_ROOT> \
  --context-root <CONTEXT_ROOT> \
  --worktrees-root <WORKTREES_ROOT> \
  [--delete-remote] [--yes] <NNNN or folder-name>
```

The script handles the full lifecycle:

1. Resolves the initiative by sequence number or folder name.
2. Scans worktrees for uncommitted changes, unpushed commits, and open PRs.
3. Presents an archive plan and prompts for confirmation (unless `--yes` is passed).
4. Removes each worktree via `git worktree remove`.
5. Deletes local branches with `git branch -d` (safe delete; warns on unmerged).
6. Optionally deletes remote branches when `--delete-remote` is passed.
7. Moves the initiative folder from `active/` to `archive/`.

If `<WORKTREES_ROOT>/NNNN/` does not exist, the script skips worktree removal and proceeds to archiving the initiative folder.

Pass the repo, context, and worktrees roots explicitly on every invocation.

## Safety Checks

Before any destructive action:

- **Uncommitted changes**: list them and require explicit user confirmation to discard.
- **Unpushed commits**: list them and require explicit user confirmation to proceed.
- **Unmerged branches**: `git branch -d` will fail for unmerged branches. Report the failure and ask the user whether to force-delete with `-D` or stop.
- **Active PRs**: if `gh` is available, check for open PRs from the branch. Warn if any exist.

Never force-delete branches or discard uncommitted work without explicit user confirmation.

## Rules

- Always confirm with the user before removing worktrees or deleting branches.
- Preserve the initiative's sequence number when moving to `archive/`.
- Do not delete the initiative folder -- move it.
- Do not modify any files inside the initiative folder during archival.
- If any safety check fails and the user does not confirm, stop and report what was skipped.
- Remote branch deletion is opt-in, not default.
