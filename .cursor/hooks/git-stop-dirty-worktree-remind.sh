#!/usr/bin/env bash
# On agent stop (completed), if git worktree is dirty or unpushed, auto-follow-up to demand commits/push.
# Bypass: SIXLAYER_GIT_HOOK_BYPASS=1
set -euo pipefail
input="$(cat)"

if [[ "${SIXLAYER_GIT_HOOK_BYPASS:-}" == "1" ]]; then
  printf '%s\n' '{}'
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOOK_JSON="$input"
exec python3 "${script_dir}/git_stop_dirty_worktree_remind.py"
