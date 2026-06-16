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
Usage: ${script_name} [options] <initiative-id-or-name> [ticket-key]

Create git worktrees for an existing numbered initiative folder.

Options:
  --repos-root DIR        Code repositories root
  --context-root DIR      Engineering context root
  --repo NAME             Repo container to create a worktree for; repeatable
  --branch-prefix PREFIX  Git branch prefix (default: feature)
  -h, --help              Show this help

Examples:
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --repo api 0001
  ${script_name} --repos-root ~/git --context-root ~/git/engineering-context --repo gateway --repo worker header-rollout GATE-123
EOF
  exit "${1:-0}"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

repos_root=""
context_root=""
branch_prefix="feature"
initiative_name=""
ticket_key=""
selected_repos=()

add_selected_repo() {
  local repo_name="$1"
  local existing=""

  case "$repo_name" in
    ""|.|..|*/*)
      log_error "--repo must be a repo directory name directly under --repos-root: ${repo_name}"
      exit 2
      ;;
  esac

  if [ "${#selected_repos[@]}" -gt 0 ]; then
    for existing in "${selected_repos[@]}"; do
      if [ "$existing" = "$repo_name" ]; then
        return
      fi
    done
  fi

  selected_repos+=("$repo_name")
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repos-root)
      repos_root="$2"; shift 2 ;;
    --context-root)
      context_root="$2"; shift 2 ;;
    --repo)
      if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
        log_error "--repo requires a value."
        exit 2
      fi
      add_selected_repo "$2"; shift 2 ;;
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
  log_error "Initiative ID or name is required."
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

if [ "${#selected_repos[@]}" -eq 0 ]; then
  log_error "Pass at least one --repo."
  exit 1
fi

# Expand ~ if present
repos_root="$(af_expand_home_path "$repos_root")"
context_root="$(af_expand_home_path "$context_root")"

# Validate directories exist
for dir_var in repos_root context_root; do
  dir_val="${!dir_var}"
  if [ ! -d "$dir_val" ]; then
    log_error "${dir_var} directory does not exist: ${dir_val}"
    exit 1
  fi
done

repos_root="$(
  cd "$repos_root" >/dev/null 2>&1 &&
    pwd -P
)"
context_root="$(
  cd "$context_root" >/dev/null 2>&1 &&
    pwd -P
)"

active_dir="${context_root}/active"
archive_dir="${context_root}/archive"

if [ ! -d "$active_dir" ]; then
  log_error "Active directory does not exist: ${active_dir}"
  exit 1
fi

resolve_existing_initiative_folder() {
  local id_or_name="$1"
  local ticket="$2"
  local padded=""
  local entry=""
  local existing_folder=""

  if [ -z "$ticket" ]; then
    if [[ "$id_or_name" =~ ^[0-9]+$ ]]; then
      padded="$(printf '%04d' "$((10#$id_or_name))")"
      for entry in "$active_dir"/"${padded}"_*/; do
        if [ -d "$entry" ]; then
          basename "$entry"
          return 0
        fi
      done
      return 1
    fi

    if [ -d "${active_dir}/${id_or_name}" ]; then
      printf '%s' "$id_or_name"
      return 0
    fi
  fi

  if existing_folder="$(af_find_existing_initiative_folder "$active_dir" "$id_or_name" "$ticket")"; then
    printf '%s' "$existing_folder"
    return 0
  fi

  return 1
}

derive_initiative_slug() {
  local folder="$1"
  local seq="$2"
  local slug="${folder#${seq}_}"

  if [[ "$slug" =~ _[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
    slug="${slug%_*}"
  fi

  printf '%s' "${slug//_/-}"
}

if ! folder_name="$(resolve_existing_initiative_folder "$initiative_name" "$ticket_key")"; then
  log_error "Initiative context does not exist for ${initiative_name}${ticket_key:+ ${ticket_key}}."
  log_error "Run the planning or research context helper first:"
  log_error "  af-plan/scripts/init-initiative-context.sh --context-root ${context_root} ${initiative_name}${ticket_key:+ ${ticket_key}}"
  exit 1
fi

seq_num="${folder_name%%_*}"
initiative_slug="$(derive_initiative_slug "$folder_name" "$seq_num")"
log_info "Reusing existing initiative folder: ${folder_name}"

initiative_dir="${active_dir}/${folder_name}"

log_info "Initiative: ${folder_name}"
log_info "Sequence number: ${seq_num}"
log_info "Worktree slug: ${initiative_slug}"

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

path_is_under() {
  local child="$1"
  local parent="$2"

  case "${child}/" in
    "${parent}/"*) return 0 ;;
    *) return 1 ;;
  esac
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
  local outcome="failed"
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
        log_warning "Fetch failed for ${repo_name}"
        printf '%s\n' "$outcome" >"$status_file"
        return 0
      fi

      if ! default_branch="$(detect_default_branch "$repo_path")"; then
        log_warning "Cannot detect default branch for ${repo_name}"
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

log_info "Creating initiative worktrees under each repo container"

created_count=0
skipped_count=0
failed_count=0
context_root_real="$(resolve_physical_path "$context_root")"
parallel_jobs="$(default_parallel_jobs)"
repo_paths_to_process=()
repo_names_to_process=()
repo_destinations_to_process=()
branch_name="${branch_prefix}/${seq_num}-${initiative_slug}"

queue_repo_worktree() {
  local repo_path="$1"
  local repo_name=""
  local repo_real_path=""
  local wt_dest=""

  [ -d "$repo_path" ] || return 0
  repo_name="$(basename "$repo_path")"

  # Skip the configured context repo, even if its directory name is custom.
  repo_real_path="$(resolve_physical_path "$repo_path")"
  if [ "$repo_real_path" = "$context_root_real" ]; then
    log_info "Skipping ${repo_name}"
    return 0
  fi

  if ! path_is_under "$repo_real_path" "$repos_root"; then
    log_error "Repo resolves outside repos root: ${repo_name} -> ${repo_real_path}"
    exit 1
  fi

  # Skip non-git directories
  if [ ! -d "${repo_path}.git" ] && ! git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
    log_warning "Skipping ${repo_name} (not a git repo)"
    skipped_count=$((skipped_count + 1))
    return 0
  fi

  if [ "$(git -C "$repo_path" rev-parse --is-bare-repository 2>/dev/null || printf 'false')" != "true" ]; then
    log_error "Repo is not a bare-container repo: ${repo_name}"
    log_error "Add or repair it with af-workspace/scripts/add-bare-repo.sh before creating initiative worktrees."
    exit 1
  fi

  wt_dest="${repo_path%/}/${seq_num}-${initiative_slug}"

  if [ -e "$wt_dest" ]; then
    if git -C "$repo_path" worktree list --porcelain | grep -Fqx "worktree ${wt_dest}" &&
      [ "$(git -C "$wt_dest" rev-parse --abbrev-ref HEAD 2>/dev/null || true)" = "$branch_name" ]; then
      log_info "Worktree already exists: ${wt_dest}"
      return 0
    fi

    log_error "Worktree path exists but is not the expected registered branch: ${wt_dest}"
    exit 1
  fi

  repo_paths_to_process+=("$repo_path")
  repo_names_to_process+=("$repo_name")
  repo_destinations_to_process+=("$wt_dest")
}

for repo_name in "${selected_repos[@]}"; do
  repo_path="${repos_root%/}/${repo_name}/"
  if [ ! -d "$repo_path" ]; then
    log_error "Selected repo not found under repos root: ${repo_name}"
    exit 1
  fi
  queue_repo_worktree "$repo_path"
done

if [ "${#repo_paths_to_process[@]}" -gt 0 ]; then
  log_info "Processing ${#repo_paths_to_process[@]} repos with up to ${parallel_jobs} parallel jobs"
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/af-implement.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

pids=()
log_files=()
status_files=()

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

if [ "${#pids[@]}" -gt 0 ]; then
  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done
fi

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
  elif [ "$result" = "failed" ]; then
    failed_count=$((failed_count + 1))
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n%s%sSummary%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Initiative folder: %s\n' "$initiative_dir"
printf 'Repos root:         %s\n' "$repos_root"
printf 'Sequence number:   %s\n' "$seq_num"
printf 'Branch prefix:     %s\n' "${branch_prefix}/${seq_num}-${initiative_slug}"
printf 'Worktrees created: %d\n' "$created_count"
if [ "$skipped_count" -gt 0 ]; then
  printf 'Worktrees skipped: %d\n' "$skipped_count"
fi
if [ "$failed_count" -gt 0 ]; then
  printf 'Worktrees failed:  %d\n' "$failed_count"
  exit 1
fi
