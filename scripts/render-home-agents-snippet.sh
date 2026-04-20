#!/usr/bin/env bash

set -euo pipefail

script_name="${0##*/}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

agents_template_relative="../templates/HOME.AGENTS.snippets.md"
agents_template="${script_dir}/${agents_template_relative}"

repos_root='~/git'
context_root='~/git/engineering-context'
worktrees_root='~/worktrees'
scratch_root='~/tmp/_ai_scratch'
skills_root='~/.agents/skills'

usage() {
  cat <<USAGE
Usage: ${script_name} [options]

Output the AGENTS.md snippet from templates/HOME.AGENTS.snippets.md with
workstation placeholders replaced.

Options:
  --repos-root PATH      Code repository root. Default: ${repos_root}
  --context-root PATH    Shared engineering context root. Default: ${context_root}
  --worktrees-root PATH  Implementation worktrees root. Default: ${worktrees_root}
  --scratch-root PATH    Ephemeral scratch root. Default: ${scratch_root}
  --skills-root PATH     Installed skills root. Default: ${skills_root}
  --template PATH        Template file to render. Default: ${agents_template_relative} relative to this script.
  -h, --help             Show this help.
USAGE
}

require_value() {
  if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
    printf 'error: %s requires a value\n' "$1" >&2
    exit 2
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repos-root)
      require_value "$@"
      repos_root="$2"
      shift 2
      ;;
    --context-root)
      require_value "$@"
      context_root="$2"
      shift 2
      ;;
    --worktrees-root)
      require_value "$@"
      worktrees_root="$2"
      shift 2
      ;;
    --scratch-root)
      require_value "$@"
      scratch_root="$2"
      shift 2
      ;;
    --skills-root)
      require_value "$@"
      skills_root="$2"
      shift 2
      ;;
    --template)
      require_value "$@"
      agents_template="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      printf 'Run %s --help for usage.\n' "$script_name" >&2
      exit 2
      ;;
  esac
done

if [ ! -f "$agents_template" ]; then
  printf 'error: expected AGENTS template at %s\n' "$agents_template" >&2
  exit 1
fi

awk '
  $0 == "```md" {
    in_snippet = 1
    next
  }

  in_snippet {
    if (have_pending) {
      print pending
    }

    pending = $0
    have_pending = 1
  }

  END {
    if (!in_snippet) {
      exit 2
    }

    if (have_pending && pending != "```") {
      print pending
    }
  }
' "$agents_template" |
awk \
  -v repos_root="$repos_root" \
  -v context_root="$context_root" \
  -v worktrees_root="$worktrees_root" \
  -v scratch_root="$scratch_root" \
  -v skills_root="$skills_root" '
  function replace_all(text, needle, replacement,    out, pos) {
    out = ""
    while ((pos = index(text, needle)) > 0) {
      out = out substr(text, 1, pos - 1) replacement
      text = substr(text, pos + length(needle))
    }
    return out text
  }

  {
    $0 = replace_all($0, "<REPOS_ROOT>", repos_root)
    $0 = replace_all($0, "<CONTEXT_ROOT>", context_root)
    $0 = replace_all($0, "<WORKTREES_ROOT>", worktrees_root)
    $0 = replace_all($0, "<SCRATCH_ROOT>", scratch_root)
    $0 = replace_all($0, "<SKILLS_ROOT>", skills_root)
    print
  }
'
