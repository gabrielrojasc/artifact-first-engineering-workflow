#!/usr/bin/env bash

set -euo pipefail

script_name="${0##*/}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"

# shellcheck source=./lib/initiative-context.sh
. "${repo_root}/scripts/lib/initiative-context.sh"

color_reset=""
color_red=""
color_green=""
color_blue=""
color_bold=""

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ] && command -v tput >/dev/null 2>&1; then
  colors="$(tput colors 2>/dev/null || printf '0')"
  if [ "${colors:-0}" -ge 8 ]; then
    color_reset="$(tput sgr0)"
    color_red="$(tput setaf 1)"
    color_green="$(tput setaf 2)"
    color_blue="$(tput setaf 4)"
    color_bold="$(tput bold)"
  fi
fi

log_info() {
  printf '%s%sinfo%s %s\n' "${color_blue}" "${color_bold}" "${color_reset}" "$1"
}

log_success() {
  printf '%s%ssuccess%s %s\n' "${color_green}" "${color_bold}" "${color_reset}" "$1"
}

log_error() {
  printf '%s%serror%s %s\n' "${color_red}" "${color_bold}" "${color_reset}" "$1" >&2
}

log_command() {
  printf '%s%srun%s %s\n' "${color_blue}" "${color_bold}" "${color_reset}" "$1"
}

usage() {
  cat <<EOF
Usage: ${script_name} --context-root DIR <initiative-name> [ticket-key]

Create or reuse the numbered initiative context folder for planning/research.

Options:
  --context-root DIR   Engineering context root
  -h, --help           Show this help

Examples:
  ${script_name} --context-root ~/git/engineering-context header-rollout GATE-123
  ${script_name} --context-root ~/git/engineering-context http-client-timeout
EOF
  exit "${1:-0}"
}

context_root=""
initiative_name=""
ticket_key=""

while [ $# -gt 0 ]; do
  case "$1" in
    --context-root)
      context_root="$2"; shift 2 ;;
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

if [ -z "$context_root" ]; then
  log_error "Pass --context-root."
  exit 1
fi

context_root="$(af_expand_home_path "$context_root")"

if [ ! -d "$context_root" ]; then
  log_error "context-root directory does not exist: ${context_root}"
  exit 1
fi

active_dir="${context_root}/active"
archive_dir="${context_root}/archive"

for dir in "$active_dir" "$archive_dir"; do
  if [ ! -d "$dir" ]; then
    log_command "mkdir -p ${dir}"
    mkdir -p "$dir"
  fi
done

af_resolve_initiative_folder "$active_dir" "$archive_dir" "$initiative_name" "$ticket_key"

initiative_dir="${active_dir}/${AF_FOLDER_NAME}"

if [ "$AF_REUSED" -eq 1 ]; then
  log_info "Reusing existing initiative folder: ${AF_FOLDER_NAME}"
else
  log_info "Creating initiative folder: ${AF_FOLDER_NAME}"
fi

for subdir in research plans status decisions; do
  target="${initiative_dir}/${subdir}"
  log_command "mkdir -p ${target}"
  mkdir -p "$target"
done

log_success "Prepared ${initiative_dir}"

printf '\n%s%sSummary%s\n' "${color_bold}" "${color_blue}" "${color_reset}"
printf 'Initiative folder: %s\n' "$initiative_dir"
printf 'Sequence number:   %s\n' "$AF_SEQ_NUM"
