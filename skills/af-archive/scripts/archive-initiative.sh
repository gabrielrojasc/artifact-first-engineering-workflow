#!/usr/bin/env bash

set -euo pipefail

script_name="${0##*/}"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

color_reset=""
color_red=""
color_yellow=""
color_green=""
color_blue=""
color_bold=""

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ] && command -v tput >/dev/null 2>&1; then
  colors="$(tput colors 2>/dev/null || printf '0')"
  if [ "${colors:-0}" -ge 8 ]; then
    color_reset="$(tput sgr0)"
    color_red="$(tput setaf 1)"
    color_yellow="$(tput setaf 3)"
    color_green="$(tput setaf 2)"
    color_blue="$(tput setaf 4)"
    color_bold="$(tput bold)"
  fi
fi

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

log_info() {
  printf '%s%sinfo%s %s\n' "${color_blue}" "${color_bold}" "${color_reset}" "$1"
}

log_success() {
  printf '%s%ssuccess%s %s\n' "${color_green}" "${color_bold}" "${color_reset}" "$1"
}

log_warning() {
  printf '%s%swarning%s %s\n' "${color_yellow}" "${color_bold}" "${color_reset}" "$1"
}

log_error() {
  printf '%s%serror%s %s\n' "${color_red}" "${color_bold}" "${color_reset}" "$1" >&2
}

log_command() {
  printf '%s%srun%s %s\n' "${color_blue}" "${color_bold}" "${color_reset}" "$1"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: ${script_name} [options] <initiative-id>

Archive an initiative: remove worktrees, clean up branches, move folder to archive.

The initiative-id can be:
  - A sequence number (e.g., 0001)
  - A full folder name (e.g., 0001_header-rollout_GATE-123)

Options:
  --repos-root DIR        Code repositories root
  --context-root DIR      Engineering context root
  --worktrees-root DIR    Worktrees root
  --delete-remote         Also delete remote branches
  --yes                   Skip confirmation prompt
  -h, --help              Show this help

Examples:
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees 0001
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees --delete-remote 0001_header-rollout_GATE-123
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees --yes 0003
EOF
  exit "${1:-0}"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

repos_root=""
context_root=""
worktrees_root=""
delete_remote=false
skip_confirm=false
initiative_id=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repos-root)
      repos_root="$2"; shift 2 ;;
    --context-root)
      context_root="$2"; shift 2 ;;
    --worktrees-root)
      worktrees_root="$2"; shift 2 ;;
    --delete-remote)
      delete_remote=true; shift ;;
    --yes)
      skip_confirm=true; shift ;;
    -h|--help)
      usage 0 ;;
    -*)
      log_error "Unknown option: $1"
      usage 1 ;;
    *)
      if [ -z "$initiative_id" ]; then
        initiative_id="$1"
      else
        log_error "Unexpected argument: $1"
        usage 1
      fi
      shift ;;
  esac
done

if [ -z "$initiative_id" ]; then
  log_error "Initiative ID is required."
  usage 1
fi

if [ -z "$repos_root" ]; then
  log_error "Pass --repos-root."
  exit 1
fi

if [ -z "$context_root" ]; then
  log_error "Pass --context-root."
  exit 1
fi

if [ -z "$worktrees_root" ]; then
  log_error "Pass --worktrees-root."
  exit 1
fi

# Expand ~ if present
repos_root="${repos_root/#\~/$HOME}"
context_root="${context_root/#\~/$HOME}"
worktrees_root="${worktrees_root/#\~/$HOME}"

active_dir="${context_root}/active"
archive_dir="${context_root}/archive"

# ---------------------------------------------------------------------------
# Resolve initiative folder
# ---------------------------------------------------------------------------

resolve_initiative() {
  local id="$1"

  # If it is a bare number, zero-pad it and find a matching folder
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    local padded
    padded="$(printf '%04d' "$((10#$id))")"
    for entry in "$active_dir"/"${padded}"_*/; do
      if [ -d "$entry" ]; then
        basename "$entry"
        return 0
      fi
    done
    log_error "No active initiative found matching sequence number ${padded}"
    return 1
  fi

  # Otherwise treat it as the full folder name
  if [ -d "${active_dir}/${id}" ]; then
    printf '%s' "$id"
    return 0
  fi

  log_error "Initiative folder not found: ${active_dir}/${id}"
  return 1
}

detect_default_branch() {
  local repo_path="$1"

  if git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
    git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||'
    return 0
  fi

  if git -C "$repo_path" rev-parse --verify origin/main >/dev/null 2>&1; then
    printf 'main'
    return 0
  fi

  if git -C "$repo_path" rev-parse --verify origin/master >/dev/null 2>&1; then
    printf 'master'
    return 0
  fi

  return 1
}

folder_name="$(resolve_initiative "$initiative_id")"
initiative_path="${active_dir}/${folder_name}"

# Extract the sequence number from the folder name
seq_num="${folder_name%%_*}"
worktree_dir="${worktrees_root}/${seq_num}"

log_info "Initiative: ${folder_name}"
log_info "Initiative path: ${initiative_path}"
log_info "Worktree directory: ${worktree_dir}"

# ---------------------------------------------------------------------------
# Collect what will be done
# ---------------------------------------------------------------------------

worktree_repos=()
worktree_branches=()
has_issues=false

if [ -d "$worktree_dir" ]; then
  for wt_path in "$worktree_dir"/*/; do
    [ -d "$wt_path" ] || continue
    repo_name="$(basename "$wt_path")"
    worktree_repos+=("$repo_name")

    # Get branch name
    branch=""
    if git -C "$wt_path" rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
      branch="$(git -C "$wt_path" rev-parse --abbrev-ref HEAD)"
    fi
    worktree_branches+=("$branch")

    # Check for uncommitted changes
    if [ -n "$(git -C "$wt_path" status --porcelain 2>/dev/null)" ]; then
      log_warning "${repo_name}: has uncommitted changes"
      has_issues=true
    fi

    # Check for unpushed commits
    if [ -n "$branch" ] && git -C "$wt_path" rev-parse "origin/${branch}" >/dev/null 2>&1; then
      unpushed="$(git -C "$wt_path" log "origin/${branch}..HEAD" --oneline 2>/dev/null)"
      if [ -n "$unpushed" ]; then
        log_warning "${repo_name}: has unpushed commits on ${branch}"
        has_issues=true
      fi
    elif [ -n "$branch" ]; then
      # Branch has no remote tracking. Only warn if it is ahead of the repo default branch.
      if default_branch="$(detect_default_branch "$wt_path")"; then
        ahead_count="$(git -C "$wt_path" rev-list --count "origin/${default_branch}..HEAD" 2>/dev/null || printf '0')"
        if [ "$ahead_count" -gt 0 ]; then
          log_warning "${repo_name}: branch ${branch} has no remote tracking and is ${ahead_count} commit(s) ahead of origin/${default_branch}"
          has_issues=true
        fi
      else
        log_warning "${repo_name}: branch ${branch} has no remote tracking and the default branch could not be detected"
        has_issues=true
      fi
    fi

    # Check for open PRs if gh is available
    if command -v gh >/dev/null 2>&1 && [ -n "$branch" ]; then
      pr_count="$(gh pr list --head "$branch" --state open --json number --jq 'length' -R "$(git -C "$wt_path" remote get-url origin 2>/dev/null)" 2>/dev/null || printf '0')"
      if [ "$pr_count" != "0" ] && [ "$pr_count" != "" ]; then
        log_warning "${repo_name}: has ${pr_count} open PR(s) from branch ${branch}"
        has_issues=true
      fi
    fi
  done
fi

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------

printf '\n%s%sArchive plan%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Move: %s -> %s/%s\n' "$initiative_path" "$archive_dir" "$folder_name"

if [ "${#worktree_repos[@]}" -gt 0 ]; then
  printf 'Remove %d worktree(s):\n' "${#worktree_repos[@]}"
  for i in "${!worktree_repos[@]}"; do
    printf '  - %s (branch: %s)\n' "${worktree_repos[$i]}" "${worktree_branches[$i]}"
  done
  printf 'Delete local branches: yes (safe delete with -d)\n'
  if [ "$delete_remote" = true ]; then
    printf 'Delete remote branches: yes\n'
  else
    printf 'Delete remote branches: no (pass --delete-remote to enable)\n'
  fi
else
  printf 'No worktrees found at %s\n' "$worktree_dir"
fi

if [ "$has_issues" = true ]; then
  printf '\n%s%sWARNING%s: Issues detected above. Review before proceeding.\n' \
    "${color_yellow}" "${color_bold}" "${color_reset}"
fi

if [ "$skip_confirm" != true ]; then
  printf '\nProceed? [y/N] '
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Aborted."
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Remove worktrees and branches
# ---------------------------------------------------------------------------

removed_wt=0
removed_branch=0
failed_wt=0
failed_branch=0
cleanup_failed=false
archived=false

if [ "${#worktree_repos[@]}" -gt 0 ]; then
  for i in "${!worktree_repos[@]}"; do
    repo_name="${worktree_repos[$i]}"
    branch="${worktree_branches[$i]}"
    wt_path="${worktree_dir}/${repo_name}"
    repo_path="${repos_root}/${repo_name}"
    worktree_removed=false

    if [ ! -d "$repo_path" ]; then
      log_error "Cannot clean up ${repo_name}: repo checkout not found at ${repo_path}"
      failed_wt=$((failed_wt + 1))
      cleanup_failed=true
      continue
    fi

    # Remove worktree
    log_command "git -C ${repo_path} worktree remove ${wt_path}"
    if git -C "$repo_path" worktree remove "$wt_path" 2>/dev/null; then
      log_success "Removed worktree: ${repo_name}"
      removed_wt=$((removed_wt + 1))
      worktree_removed=true
    else
      # Try with --force if the normal remove fails (e.g., dirty worktree after user confirmed)
      log_warning "Normal worktree remove failed for ${repo_name}, trying with --force"
      if git -C "$repo_path" worktree remove --force "$wt_path" 2>/dev/null; then
        log_success "Force-removed worktree: ${repo_name}"
        removed_wt=$((removed_wt + 1))
        worktree_removed=true
      else
        log_error "Failed to remove worktree: ${repo_name}"
        failed_wt=$((failed_wt + 1))
        cleanup_failed=true
      fi
    fi

    if [ "$worktree_removed" != true ]; then
      continue
    fi

    # Delete local branch
    if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
      log_command "git -C ${repo_path} branch -d ${branch}"
      if git -C "$repo_path" branch -d "$branch" 2>/dev/null; then
        log_success "Deleted local branch: ${branch} (${repo_name})"
        removed_branch=$((removed_branch + 1))
      else
        log_warning "Could not delete branch ${branch} in ${repo_name} (may be unmerged). Use 'git branch -D ${branch}' to force-delete."
        failed_branch=$((failed_branch + 1))
      fi
    fi

    # Delete remote branch if requested
    if [ "$delete_remote" = true ] && [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
      log_command "git -C ${repo_path} push origin --delete ${branch}"
      if git -C "$repo_path" push origin --delete "$branch" 2>/dev/null; then
        log_success "Deleted remote branch: ${branch} (${repo_name})"
      else
        log_warning "Could not delete remote branch ${branch} in ${repo_name} (may not exist on remote)"
      fi
    fi
  done

  # Remove the initiative worktree directory if empty
  if [ -d "$worktree_dir" ]; then
    rmdir "$worktree_dir" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Move initiative to archive
# ---------------------------------------------------------------------------

if [ "$cleanup_failed" != true ]; then
  mkdir -p "$archive_dir"

  log_command "mv ${initiative_path} ${archive_dir}/${folder_name}"
  mv "$initiative_path" "${archive_dir}/${folder_name}"
  log_success "Archived: ${folder_name}"
  archived=true
else
  log_error "Archive skipped: one or more worktrees could not be removed. Initiative remains active at ${initiative_path}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n%s%sSummary%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Initiative:         %s\n' "$folder_name"
if [ "$archived" = true ]; then
  printf 'Archived to:        %s/%s\n' "$archive_dir" "$folder_name"
else
  printf 'Archived to:        skipped\n'
fi
printf 'Worktrees removed:  %d\n' "$removed_wt"
if [ "$failed_wt" -gt 0 ]; then
  printf 'Worktrees failed:   %d (initiative left in active/ for retry)\n' "$failed_wt"
fi
printf 'Branches deleted:   %d\n' "$removed_branch"
if [ "$failed_branch" -gt 0 ]; then
  printf 'Branches failed:    %d (unmerged -- review manually)\n' "$failed_branch"
fi

if [ "$cleanup_failed" = true ]; then
  exit 1
fi
