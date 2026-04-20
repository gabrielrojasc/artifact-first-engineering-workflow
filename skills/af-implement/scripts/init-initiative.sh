#!/usr/bin/env bash

set -euo pipefail

script_name="${0##*/}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"

# shellcheck source=./lib/initiative-context.sh
. "${script_dir}/lib/initiative-context.sh"

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

Create git worktrees for an existing numbered initiative folder.

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
repos_root="$(af_expand_home_path "$repos_root")"
context_root="$(af_expand_home_path "$context_root")"
worktrees_root="$(af_expand_home_path "$worktrees_root")"

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

af_resolve_initiative_folder "$active_dir" "$archive_dir" "$initiative_name" "$ticket_key"

if [ "$AF_REUSED" -ne 1 ]; then
  log_error "Initiative context does not exist for ${initiative_name}${ticket_key:+ ${ticket_key}}."
  log_error "Run the planning or research context helper first:"
  log_error "  af-plan/scripts/init-initiative-context.sh --context-root ${context_root} ${initiative_name}${ticket_key:+ ${ticket_key}}"
  exit 1
fi

folder_name="$AF_FOLDER_NAME"
seq_num="$AF_SEQ_NUM"
log_info "Reusing existing initiative folder: ${folder_name}"

initiative_dir="${active_dir}/${folder_name}"
worktree_dir="${worktrees_root}/${seq_num}"

log_info "Initiative: ${folder_name}"
log_info "Sequence number: ${seq_num}"

# ---------------------------------------------------------------------------
# Ensure implementation-owned status directory exists
# ---------------------------------------------------------------------------

status_dir="${initiative_dir}/status"
if [ ! -d "$status_dir" ]; then
  log_info "Creating missing status directory"
  log_command "mkdir -p ${status_dir}"
  mkdir -p "$status_dir"
fi

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

default_parallel_jobs() {
  local cpu_count=""

  if command -v getconf >/dev/null 2>&1; then
    cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  fi

  if [ -z "$cpu_count" ] && command -v nproc >/dev/null 2>&1; then
    cpu_count="$(nproc 2>/dev/null || true)"
  fi

  if [ -z "$cpu_count" ] && command -v sysctl >/dev/null 2>&1; then
    cpu_count="$(sysctl -n hw.logicalcpu 2>/dev/null || true)"
  fi

  if ! [[ "$cpu_count" =~ ^[0-9]+$ ]] || [ "$cpu_count" -lt 1 ]; then
    cpu_count=4
  fi

  if [ "$cpu_count" -gt 8 ]; then
    cpu_count=8
  fi

  printf '%s' "$cpu_count"
}

running_job_count() {
  jobs -pr | wc -l | tr -d ' '
}

wait_for_available_slot() {
  local max_jobs="$1"

  while [ "$(running_job_count)" -ge "$max_jobs" ]; do
    sleep 0.1
  done
}

process_repo_worktree() {
  local repo_path="$1"
  local repo_name="$2"
  local wt_dest="$3"
  local branch_name="$4"
  local log_file="$5"
  local status_file="$6"
  local outcome="skipped"
  local default_branch=""

  {
    if git -C "$repo_path" show-ref --verify --quiet "refs/heads/${branch_name}"; then
      log_command "git -C ${repo_path} worktree add ${wt_dest} ${branch_name}"
      if git -C "$repo_path" worktree add "$wt_dest" "$branch_name" 2>/dev/null; then
        log_success "Created worktree: ${repo_name} -> ${wt_dest} (branch: ${branch_name})"
        outcome="created"
      else
        log_warning "Failed to reattach existing branch for ${repo_name}"
      fi
    else
      # Fetch before creating a new branch from the remote default branch.
      log_command "git -C ${repo_path} fetch"
      if ! git -C "$repo_path" fetch --quiet 2>/dev/null; then
        log_warning "Fetch failed for ${repo_name}, skipping"
        printf '%s\n' "$outcome" >"$status_file"
        return 0
      fi

      if ! default_branch="$(detect_default_branch "$repo_path")"; then
        log_warning "Cannot detect default branch for ${repo_name}, skipping"
        printf '%s\n' "$outcome" >"$status_file"
        return 0
      fi

      log_command "git -C ${repo_path} worktree add ${wt_dest} -b ${branch_name} origin/${default_branch}"
      if git -C "$repo_path" worktree add "$wt_dest" -b "$branch_name" "origin/${default_branch}" 2>/dev/null; then
        log_success "Created worktree: ${repo_name} -> ${wt_dest} (branch: ${branch_name})"
        outcome="created"
      else
        log_warning "Failed to create worktree for ${repo_name}"
      fi
    fi

    printf '%s\n' "$outcome" >"$status_file"
  } >"$log_file" 2>&1
}

# ---------------------------------------------------------------------------
# Create worktrees
# ---------------------------------------------------------------------------

log_info "Creating worktrees under ${worktree_dir}"
mkdir -p "$worktree_dir"

created_count=0
skipped_count=0
context_root_real="$(resolve_physical_path "$context_root")"
parallel_jobs="$(default_parallel_jobs)"
repo_paths_to_process=()
repo_names_to_process=()
repo_destinations_to_process=()

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

  repo_paths_to_process+=("$repo_path")
  repo_names_to_process+=("$repo_name")
  repo_destinations_to_process+=("$wt_dest")
done

if [ "${#repo_paths_to_process[@]}" -gt 0 ]; then
  log_info "Processing ${#repo_paths_to_process[@]} repos with up to ${parallel_jobs} parallel jobs"
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/af-implement.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

pids=()
log_files=()
status_files=()
branch_name="${branch_prefix}/${seq_num}-${initiative_name}"

for i in "${!repo_paths_to_process[@]}"; do
  wait_for_available_slot "$parallel_jobs"

  log_file="${tmp_dir}/${i}.log"
  status_file="${tmp_dir}/${i}.status"

  process_repo_worktree \
    "${repo_paths_to_process[$i]}" \
    "${repo_names_to_process[$i]}" \
    "${repo_destinations_to_process[$i]}" \
    "$branch_name" \
    "$log_file" \
    "$status_file" &

  pids+=("$!")
  log_files+=("$log_file")
  status_files+=("$status_file")
done

for pid in "${pids[@]}"; do
  wait "$pid" || true
done

for i in "${!repo_paths_to_process[@]}"; do
  if [ -f "${log_files[$i]}" ]; then
    cat "${log_files[$i]}"
  fi

  if [ -f "${status_files[$i]}" ]; then
    result="$(cat "${status_files[$i]}")"
  else
    result="skipped"
    log_warning "No result recorded for ${repo_names_to_process[$i]}, skipping"
  fi

  if [ "$result" = "created" ]; then
    created_count=$((created_count + 1))
  elif [ "$result" = "skipped" ]; then
    skipped_count=$((skipped_count + 1))
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
