#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "${script_dir}/../../.." && pwd -P)"

exec "${repo_root}/scripts/init-initiative-context.sh" "$@"
