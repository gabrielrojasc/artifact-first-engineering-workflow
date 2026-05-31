#!/usr/bin/env bash

# Render a Markdown artifact into a self-contained dark-mode HTML sibling.
#
# The Markdown file stays the source of truth. This emits a readable HTML view
# next to it: dark-mode-first with a light toggle, an auto-generated table of
# contents, Mermaid diagrams, syntax-highlighted code, and status pills.
#
# Usage:
#   render-artifact.sh <input.md> [output.html]
#
# Output defaults to the input path with a .html extension.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="${AF_ARTIFACT_TEMPLATE:-$script_dir/lib/artifact-template.html}"

input="${1:-}"
if [ -z "$input" ]; then
  echo "usage: render-artifact.sh <input.md> [output.html]" >&2
  exit 2
fi
if [ ! -f "$input" ]; then
  echo "render-artifact: input not found: $input" >&2
  exit 1
fi
if [ ! -f "$template" ]; then
  echo "render-artifact: template not found: $template" >&2
  exit 1
fi

output="${2:-${input%.md}.html}"

# Title: first level-1 heading, else the file name.
title="$(grep -m1 -E '^# ' "$input" 2>/dev/null | sed -E 's/^# +//' | sed -E 's/[[:space:]]+$//' || true)"
if [ -z "$title" ]; then
  title="$(basename "$input")"
fi

base="$(basename "$input")"

# Kind label: inferred from the file name.
shopt -s nocasematch
case "$base" in
  *research*)                 kind="Research" ;;
  *proposal*)                 kind="Proposal" ;;
  *mini-plan*|*phased-plan*|*plan*) kind="Plan" ;;
  *status*)                   kind="Status" ;;
  *handoff*)                  kind="Handoff" ;;
  *mismatch*)                 kind="Mismatch" ;;
  *boundary*|*checklist*)     kind="Checklist" ;;
  *decision*)                 kind="Decision" ;;
  *workflow-state*)           kind="State" ;;
  *)                          kind="Artifact" ;;
esac
shopt -u nocasematch

# Breadcrumb: path after engineering-context/ when present, else the file name.
abs="$(cd "$(dirname "$input")" && pwd)/$base"
if [[ "$abs" == *"/engineering-context/"* ]]; then
  crumbs="engineering-context/${abs#*/engineering-context/}"
else
  crumbs="$base"
fi

# Last-modified date of the source, else today.
date_str="$(date -r "$input" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)"

# Base64 of the Markdown, embedded so the HTML view is fully self-contained.
b64="$(base64 < "$input" | tr -d '\n')"

# HTML-escape short text values.
esc() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "$s"
}
e_title="$(esc "$title")"
e_kind="$(esc "$kind")"
e_crumbs="$(esc "$crumbs")"
e_base="$(esc "$base")"

# Literal placeholder substitution (no regex, handles any value).
while IFS= read -r line || [ -n "$line" ]; do
  line="${line//__AF_TITLE__/$e_title}"
  line="${line//__AF_KIND__/$e_kind}"
  line="${line//__AF_CRUMBS__/$e_crumbs}"
  line="${line//__AF_DATE__/$date_str}"
  line="${line//__AF_SOURCE__/$e_base}"
  line="${line//__AF_B64__/$b64}"
  printf '%s\n' "$line"
done < "$template" > "$output"

echo "rendered $output"
