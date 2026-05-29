#!/usr/bin/env bash
# Block Write/StrReplace to a *new* path when other paths already have uncommitted changes.
# Bypass: export SIXLAYER_GIT_HOOK_BYPASS=1 (or remove hook from hooks.json).
set -euo pipefail
input="$(cat)"

if [[ "${SIXLAYER_GIT_HOOK_BYPASS:-}" == "1" ]]; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOOK_JSON="$input"
exec python3 "${script_dir}/git_prevent_multi_file_dirty.py"
