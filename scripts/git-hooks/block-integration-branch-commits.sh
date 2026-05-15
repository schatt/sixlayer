#!/usr/bin/env bash
# Block creating **non-merge** commits while checked out on integration branches (main / next).
# Completing a `git merge` (merge commit while `MERGE_HEAD` exists) is allowed so integration branches
# can record merge commits locally without bypassing hooks.
# Implementation work must still use a worktree + wip/* branch; land feature work via merge or PR.
#
# Installed via: pre-commit install (see .pre-commit-config.yaml local hook).
# Bypass (emergency only): SIXLAYER_GIT_HOOK_BYPASS=1, or SKIP=no-commit-on-integration-branches for one shot.
set -euo pipefail

if [[ "${SIXLAYER_GIT_HOOK_BYPASS:-}" == "1" ]]; then
  exit 0
fi

if ! toplevel="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  exit 0
fi
cd "$toplevel"

if ! branch="$(git symbolic-ref -q --short HEAD 2>/dev/null)"; then
  # Detached HEAD (bisect, etc.) — do not block.
  exit 0
fi

case "$branch" in
  main|next)
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
    # Merge in progress → this commit is (almost certainly) completing `git merge` — allow on integration branches.
    if [[ -f "${git_dir}/MERGE_HEAD" ]]; then
      exit 0
    fi
    cat >&2 <<EOF
SixLayer: non-merge commits on integration branch '$branch' are blocked.

Do work in a dedicated git worktree on wip/<issue-slug> (or another non-integration branch),
then integrate via merge or GitHub PR into '$branch'.

Merge commits (while a merge is in progress) are allowed. For other exceptions:

Bypass (not for routine use): SIXLAYER_GIT_HOOK_BYPASS=1
Pre-commit one-shot skip: SKIP=no-commit-on-integration-branches git commit ...
EOF
    exit 1
    ;;
esac

exit 0
