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
Usage: ${script_name} [options] <initiative-name> [ticket-key]

Create a numbered initiative folder and git worktrees for all repos.

Options:
  --repos-root DIR        Code repositories root
  --context-root DIR      Engineering context root
  --worktrees-root DIR    Worktrees root
  --branch-prefix PREFIX  Git branch prefix (default: feature)
  -h, --help              Show this help

Examples:
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees header-rollout GATE-123
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees --branch-prefix bugfix search-ranking-tuneup
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --worktrees-root ~/worktrees checkout-retry-policy PAY-204
EOF
  exit "${1:-0}"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

repos_root=""
context_root=""
worktrees_root=""
branch_prefix="feature"
initiative_name=""
ticket_key=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repos-root)
      repos_root="$2"; shift 2 ;;
    --context-root)
      context_root="$2"; shift 2 ;;
    --worktrees-root)
      worktrees_root="$2"; shift 2 ;;
    --branch-prefix)
      branch_prefix="$2"; shift 2 ;;
    -h|--help)
      usage 0 ;;
    -*)
      log_error "Unknown option: $1"
      usage 1 ;;
    *)
      if [ -z "$initiative_name" ]; then
        initiative_name="$1"
      elif [ -z "$ticket_key" ]; then
        ticket_key="$1"
      else
        log_error "Unexpected argument: $1"
        usage 1
      fi
      shift ;;
  esac
done

if [ -z "$initiative_name" ]; then
  log_error "Initiative name is required."
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

# Validate directories exist
for dir_var in repos_root context_root; do
  dir_val="${!dir_var}"
  if [ ! -d "$dir_val" ]; then
    log_error "${dir_var} directory does not exist: ${dir_val}"
    exit 1
  fi
done

active_dir="${context_root}/active"
archive_dir="${context_root}/archive"

if [ ! -d "$active_dir" ]; then
  log_error "Active directory does not exist: ${active_dir}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Determine next sequence number
# ---------------------------------------------------------------------------

next_sequence_number() {
  local max=0
  local num

  for dir in "$active_dir" "$archive_dir"; do
    [ -d "$dir" ] || continue
    for entry in "$dir"/*/; do
      [ -d "$entry" ] || continue
      basename="$(basename "$entry")"
      # Extract leading digits
      num="${basename%%_*}"
      # Validate it is a number
      if [[ "$num" =~ ^[0-9]+$ ]]; then
        num=$((10#$num))  # strip leading zeros for arithmetic
        if [ "$num" -gt "$max" ]; then
          max="$num"
        fi
      fi
    done
  done

  printf '%04d' $(( max + 1 ))
}

# Check if an active folder already matches this initiative name
existing_folder=""
for entry in "$active_dir"/*/; do
  [ -d "$entry" ] || continue
  entry_base="$(basename "$entry")"
  # Strip the leading NNNN_ prefix to compare the initiative part
  entry_suffix="${entry_base#*_}"
  if [ -n "$ticket_key" ]; then
    target_suffix="${initiative_name}_${ticket_key}"
  else
    target_suffix="${initiative_name}"
  fi
  if [ "$entry_suffix" = "$target_suffix" ]; then
    existing_folder="$entry_base"
    break
  fi
done

if [ -n "$existing_folder" ]; then
  folder_name="$existing_folder"
  seq_num="${folder_name%%_*}"
  log_info "Reusing existing initiative folder: ${folder_name}"
else
  seq_num="$(next_sequence_number)"
  if [ -n "$ticket_key" ]; then
    folder_name="${seq_num}_${initiative_name}_${ticket_key}"
  else
    folder_name="${seq_num}_${initiative_name}"
  fi
fi

initiative_dir="${active_dir}/${folder_name}"
worktree_dir="${worktrees_root}/${seq_num}"

log_info "Initiative: ${folder_name}"
log_info "Sequence number: ${seq_num}"

# ---------------------------------------------------------------------------
# Create initiative folder structure
# ---------------------------------------------------------------------------

log_info "Creating initiative folder structure"

for subdir in research plans status decisions; do
  target="${initiative_dir}/${subdir}"
  log_command "mkdir -p ${target}"
  mkdir -p "$target"
done

log_success "Created ${initiative_dir}"

# ---------------------------------------------------------------------------
# Detect default branch for a repo
# ---------------------------------------------------------------------------

detect_default_branch() {
  local repo_path="$1"

  # Try symbolic-ref first
  if git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
    git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||'
    return
  fi

  # Fall back to checking known branch names
  if git -C "$repo_path" rev-parse --verify origin/main >/dev/null 2>&1; then
    printf 'main'
    return
  fi

  if git -C "$repo_path" rev-parse --verify origin/master >/dev/null 2>&1; then
    printf 'master'
    return
  fi

  return 1
}

resolve_physical_path() {
  local dir_path="$1"

  (
    cd "$dir_path" >/dev/null 2>&1 &&
      pwd -P
  )
}

# ---------------------------------------------------------------------------
# Create worktrees
# ---------------------------------------------------------------------------

log_info "Creating worktrees under ${worktree_dir}"
mkdir -p "$worktree_dir"

created_count=0
skipped_count=0
context_root_real="$(resolve_physical_path "$context_root")"

for repo_path in "$repos_root"/*/; do
  [ -d "$repo_path" ] || continue
  repo_name="$(basename "$repo_path")"

  # Skip the configured context repo, even if its directory name is custom.
  repo_real_path="$(resolve_physical_path "$repo_path")"
  if [ "$repo_real_path" = "$context_root_real" ]; then
    log_info "Skipping ${repo_name}"
    continue
  fi

  # Skip non-git directories
  if [ ! -d "${repo_path}.git" ] && ! git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
    log_warning "Skipping ${repo_name} (not a git repo)"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  wt_dest="${worktree_dir}/${repo_name}"

  # Skip if worktree already exists
  if [ -d "$wt_dest" ]; then
    log_info "Worktree already exists: ${wt_dest}"
    continue
  fi

  branch_name="${branch_prefix}/${seq_num}-${initiative_name}"
  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/${branch_name}"; then
    log_command "git -C ${repo_path} worktree add ${wt_dest} ${branch_name}"
    if git -C "$repo_path" worktree add "$wt_dest" "$branch_name" 2>/dev/null; then
      log_success "Created worktree: ${repo_name} -> ${wt_dest} (branch: ${branch_name})"
      created_count=$((created_count + 1))
    else
      log_warning "Failed to reattach existing branch for ${repo_name}"
      skipped_count=$((skipped_count + 1))
    fi
  else
    # Fetch before creating a new branch from the remote default branch.
    log_command "git -C ${repo_path} fetch"
    if ! git -C "$repo_path" fetch --quiet 2>/dev/null; then
      log_warning "Fetch failed for ${repo_name}, skipping"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    if ! default_branch="$(detect_default_branch "$repo_path")"; then
      log_warning "Cannot detect default branch for ${repo_name}, skipping"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    log_command "git -C ${repo_path} worktree add ${wt_dest} -b ${branch_name} origin/${default_branch}"
    if git -C "$repo_path" worktree add "$wt_dest" -b "$branch_name" "origin/${default_branch}" 2>/dev/null; then
      log_success "Created worktree: ${repo_name} -> ${wt_dest} (branch: ${branch_name})"
      created_count=$((created_count + 1))
    else
      log_warning "Failed to create worktree for ${repo_name}"
      skipped_count=$((skipped_count + 1))
    fi
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n%s%sSummary%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Initiative folder: %s\n' "$initiative_dir"
printf 'Worktrees root:    %s\n' "$worktree_dir"
printf 'Sequence number:   %s\n' "$seq_num"
printf 'Branch prefix:     %s\n' "${branch_prefix}/${seq_num}-${initiative_name}"
printf 'Worktrees created: %d\n' "$created_count"
if [ "$skipped_count" -gt 0 ]; then
  printf 'Worktrees skipped: %d\n' "$skipped_count"
fi
