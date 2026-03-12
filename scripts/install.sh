#!/usr/bin/env bash

set -euo pipefail

script_name="${0##*/}"

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

created_items=()
unchanged_items=()
skipped_items=()

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

record_created() {
  created_items+=("$1")
}

record_unchanged() {
  unchanged_items+=("$1")
}

record_skipped() {
  skipped_items+=("$1")
}

log_command() {
  printf '%s%srun%s %s\n' "${color_blue}" "${color_bold}" "${color_reset}" "$1"
}

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

ensure_directory() {
  dir_path="$1"
  label="$2"

  if [ -d "$dir_path" ]; then
    log_info "${label} already exists at ${dir_path}"
    record_unchanged "${label}: ${dir_path}"
    return
  fi

  if [ -e "$dir_path" ]; then
    log_error "Expected ${dir_path} to be a directory for ${label}, but it already exists as a file."
    exit 1
  fi

  log_command "mkdir -p ${dir_path}"
  mkdir -p "$dir_path"
  log_success "Created ${label} at ${dir_path}"
  record_created "${label}: ${dir_path}"
}

log_command "git rev-parse --show-toplevel"

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  log_error "Run ${script_name} from inside the artifact-first repo checkout or worktree."
  exit 1
fi

skills_source_dir="${repo_root}/skills"
agents_template="${repo_root}/templates/HOME.AGENTS.snippets.md"
home_guide_doc="${repo_root}/docs/home-agents-guide.md"
install_guide_doc="${repo_root}/docs/install-and-use.md"

if [ ! -d "$skills_source_dir" ]; then
  log_error "Expected skills directory at ${skills_source_dir}."
  exit 1
fi

if [ ! -f "$agents_template" ]; then
  log_error "Expected AGENTS template at ${agents_template}."
  exit 1
fi

agents_skills_dir="${HOME}/.agents/skills"
codex_dir="${HOME}/.codex"
claude_dir="${HOME}/.claude"
codex_agents_file="${codex_dir}/AGENTS.md"
claude_file="${claude_dir}/CLAUDE.md"

log_info "Using repo root ${repo_root}"
log_info "This installer runs: git rev-parse --show-toplevel, mkdir -p, ln -s, and cp."

ensure_directory "${HOME}/.agents" "agent home"
ensure_directory "$agents_skills_dir" "agent skills directory"
ensure_directory "$codex_dir" "Codex directory"
ensure_directory "$claude_dir" "Claude directory"

for skill_path in "$skills_source_dir"/*; do
  if [ ! -d "$skill_path" ]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  skill_dest="${agents_skills_dir}/${skill_name}"

  if [ -L "$skill_dest" ]; then
    current_target="$(readlink "$skill_dest")"
    if [ "$current_target" = "$skill_path" ]; then
      log_info "Skill ${skill_name} already points to ${skill_path}"
      record_unchanged "skill ${skill_name}: ${skill_dest}"
      continue
    fi

    log_warning "Skill destination ${skill_dest} already points to ${current_target}; leaving it unchanged."
    log_warning "Review ${install_guide_doc} and update that skill manually if you want this workflow there."
    record_skipped "skill ${skill_name}: ${skill_dest}"
    continue
  fi

  if [ -e "$skill_dest" ]; then
    log_warning "Skill destination ${skill_dest} already exists; leaving it unchanged."
    log_warning "Review ${install_guide_doc} and update that skill manually if you want this workflow there."
    record_skipped "skill ${skill_name}: ${skill_dest}"
    continue
  fi

  log_command "ln -s ${skill_path} ${skill_dest}"
  ln -s "$skill_path" "$skill_dest"
  log_success "Linked skill ${skill_name} -> ${skill_path}"
  record_created "skill ${skill_name}: ${skill_dest}"
done

if path_exists "$codex_agents_file"; then
  log_warning "${codex_agents_file} already exists; leaving it unchanged."
  log_warning "Review ${home_guide_doc} and add the workflow rules manually."
  record_skipped "Codex guidance: ${codex_agents_file}"
else
  log_command "cp ${agents_template} ${codex_agents_file}"
  cp "$agents_template" "$codex_agents_file"
  log_success "Copied Codex starter guide to ${codex_agents_file}"
  record_created "Codex guidance: ${codex_agents_file}"
fi

if path_exists "$claude_file"; then
  log_warning "${claude_file} already exists; leaving it unchanged."
  log_warning "Review ${home_guide_doc} and add the workflow rules manually."
  record_skipped "Claude guidance: ${claude_file}"
else
  log_command "ln -s ${codex_agents_file} ${claude_file}"
  ln -s "$codex_agents_file" "$claude_file"
  log_success "Linked Claude guidance ${claude_file} -> ${codex_agents_file}"
  record_created "Claude guidance: ${claude_file}"
fi

printf '\n%s%sPost-install required%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Replace the placeholders in %s before relying on it.\n' "$codex_agents_file"
printf 'Expected placeholders include %s, %s, and %s.\n' \
  '<CHOSEN_REPOS_ROOT>' \
  '<CHOSEN_ENGINEERING_CONTEXT_ROOT>' \
  '<CHOSEN_SCRATCH_ROOT>'
printf 'When created by this installer, %s is intentionally a symlink to %s so both tools read the same guidance.\n' \
  "$claude_file" \
  "$codex_agents_file"

printf '\n%s%sSummary%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Repo root: %s\n' "$repo_root"

printf '\nCreated:\n'
if [ "${#created_items[@]}" -eq 0 ]; then
  printf '  - none\n'
else
  for item in "${created_items[@]}"; do
    printf '  - %s\n' "$item"
  done
fi

printf '\nUnchanged:\n'
if [ "${#unchanged_items[@]}" -eq 0 ]; then
  printf '  - none\n'
else
  for item in "${unchanged_items[@]}"; do
    printf '  - %s\n' "$item"
  done
fi

printf '\nSkipped:\n'
if [ "${#skipped_items[@]}" -eq 0 ]; then
  printf '  - none\n'
else
  for item in "${skipped_items[@]}"; do
    printf '  - %s\n' "$item"
  done
fi

if [ "${#skipped_items[@]}" -gt 0 ]; then
  printf '\nManual follow-up docs:\n'
  printf '  - %s\n' "$home_guide_doc"
  printf '  - %s\n' "$install_guide_doc"
fi
