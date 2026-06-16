---
name: af-workspace
description: manage Artifact First workspace repo containers. use when adding, repairing, listing, or syncing cloned repos in the bare-container layout so default-branch browsing and initiative worktrees live under the repo container.
---

# Artifact-First Workspace

## Overview

Manage repositories in the Artifact First bare-container layout:

```text
<repos-root>/
  <repo>/
    .git/
    <default-branch>/
    NNNN-<initiative>/
```

Use this skill to add a new repository, repair an existing repo container, list what is in the workspace, or sync default-branch worktrees.

## Add Or Repair A Repo

Run the bundled helper:

```bash
<SKILLS_ROOT>/af-workspace/scripts/add-bare-repo.sh \
  --repos-root <REPOS_ROOT> \
  <repo-url>
```

If you are already inside the installed `af-workspace` skill directory, run `scripts/add-bare-repo.sh` directly.

Pass `--repo-name <name>` when the directory name should not be derived from the URL.

The helper:

1. Creates `<REPOS_ROOT>/<repo>/.git` as a bare repo.
2. Fetches remote branches.
3. Detects the remote default branch.
4. Creates a persistent default-branch worktree at `<REPOS_ROOT>/<repo>/<default-branch>/`.
5. Repairs an existing bare-container repo by refreshing refs and recreating the default worktree if missing.

### Add Many Repos At Once

Pass `--from-manifest <file>` to add or repair several repos in one run. Each line is `<repo-url> [repo-name]`; blank lines, `#` comment lines, and trailing ` #` comments are ignored:

```bash
<SKILLS_ROOT>/af-workspace/scripts/add-bare-repo.sh \
  --repos-root <REPOS_ROOT> \
  --from-manifest repos.txt
```

The run continues past a failed entry and exits non-zero if any entry failed.

## List The Workspace

Show every bare-container repo, its default branch, and its initiative worktrees:

```bash
<SKILLS_ROOT>/af-workspace/scripts/list-workspace.sh \
  --repos-root <REPOS_ROOT> \
  [--context-root <CONTEXT_ROOT>]
```

Pass `--context-root` to skip the shared engineering context repo. Initiative worktrees with uncommitted changes are flagged `[dirty]`.

## Sync The Workspace

Fetch each repo, fast-forward its default-branch worktree, and prune stale worktree registrations:

```bash
<SKILLS_ROOT>/af-workspace/scripts/sync-workspace.sh \
  --repos-root <REPOS_ROOT> \
  [--context-root <CONTEXT_ROOT>] [--jobs <N>] [--no-prune]
```

Sync never touches initiative worktrees. It skips a default worktree that has local changes rather than discarding them, and reports repos whose default worktree is missing so they can be repaired with `add-bare-repo.sh`.

## Rules

- Do not clone ordinary working copies directly under `<REPOS_ROOT>`.
- Do not use these helpers for the shared engineering context repo; pass `--context-root` so it is skipped.
- If the destination exists but is not a bare-container repo, stop and report it.
- If the remote cannot be reached, stop and report the failing command.
- Never discard uncommitted or unpushed work to make a sync or repair succeed.
