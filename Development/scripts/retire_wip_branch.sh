#!/usr/bin/env bash
# Rename wip/<slug> → done/<slug>, publish done/, drop remote wip/, remove
# worktree, delete local done/. Remotes keep history; no idle local done/.
# Does not merge to next. See #459.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/branch_upstream.sh
source "${SCRIPT_DIR}/lib/branch_upstream.sh"

usage() {
    sed -n '2,3p' "$0" | sed 's/^# \?//'
    echo "Usage: $0 [--git-dir|--repo <path>] [--no-worktree-remove] <slug>"
    echo "  slug: 459-short-name  or  wip/459-short-name"
}

REPO=""
REMOVE_WORKTREE=1
SLUG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --no-worktree-remove) REMOVE_WORKTREE=0; shift ;;
        --git-dir|--repo)
            [[ $# -ge 2 ]] || { echo "✗ $1 requires a path" >&2; exit 1; }
            REPO="$2"
            shift 2
            ;;
        *)
            if [[ -z "$SLUG" ]]; then
                SLUG="$1"
                shift
            else
                echo "✗ Unexpected argument: $1" >&2
                usage >&2
                exit 1
            fi
            ;;
    esac
done

[[ -n "$SLUG" ]] || { usage >&2; exit 1; }
SLUG="${SLUG#wip/}"
SLUG="${SLUG#done/}"

WIP_BRANCH="wip/${SLUG}"
DONE_BRANCH="done/${SLUG}"
REPO="${REPO:-$(pwd)}"

if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "✗ Not a git repository: $REPO" >&2
    exit 1
fi

# Resolve to the common repo (parent of .git) so worktree remove is safe.
GIT_COMMON="$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)"
REPO_ROOT="$(dirname "$GIT_COMMON")"

push_remote() {
    if git -C "$REPO_ROOT" remote | grep -qx all; then
        echo all
    else
        echo origin
    fi
}

find_worktree_for_branch() {
    local want="$1"
    local wt="" branch=""
    while IFS= read -r line; do
        case "$line" in
            worktree*)
                wt="${line#worktree }"
                branch=""
                ;;
            branch*)
                branch="${line#branch }"
                branch="${branch#refs/heads/}"
                if [[ "$branch" == "$want" ]]; then
                    echo "$wt"
                    return 0
                fi
                ;;
        esac
    done < <(git -C "$REPO_ROOT" worktree list --porcelain)
    return 1
}

WIP_EXISTS=0
DONE_EXISTS=0
git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/${WIP_BRANCH}" && WIP_EXISTS=1
git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/${DONE_BRANCH}" && DONE_EXISTS=1

if [[ "$WIP_EXISTS" -eq 0 && "$DONE_EXISTS" -eq 0 ]]; then
    echo "✗ Neither ${WIP_BRANCH} nor ${DONE_BRANCH} exists" >&2
    exit 1
fi

WORKTREE_PATH=""
if [[ "$WIP_EXISTS" -eq 1 ]]; then
    WORKTREE_PATH="$(find_worktree_for_branch "$WIP_BRANCH" || true)"
elif [[ "$DONE_EXISTS" -eq 1 ]]; then
    WORKTREE_PATH="$(find_worktree_for_branch "$DONE_BRANCH" || true)"
fi

if [[ "$WIP_EXISTS" -eq 1 && "$DONE_EXISTS" -eq 1 ]]; then
    echo "✗ Both ${WIP_BRANCH} and ${DONE_BRANCH} exist — resolve manually" >&2
    exit 1
fi

if [[ "$WIP_EXISTS" -eq 1 ]]; then
    echo "ℹ Renaming ${WIP_BRANCH} → ${DONE_BRANCH}"
    if [[ -n "$WORKTREE_PATH" ]]; then
        git -C "$WORKTREE_PATH" branch -m "$DONE_BRANCH"
        WORKTREE_PATH="$(find_worktree_for_branch "$DONE_BRANCH" || echo "$WORKTREE_PATH")"
    else
        git -C "$REPO_ROOT" branch -m "$WIP_BRANCH" "$DONE_BRANCH"
    fi
fi

REMOTE="$(push_remote)"
echo "ℹ Publishing ${DONE_BRANCH} to ${REMOTE}"
git -C "$REPO_ROOT" push "$REMOTE" "$DONE_BRANCH"
if git -C "$REPO_ROOT" ls-remote --exit-code "$REMOTE" "refs/heads/${WIP_BRANCH}" >/dev/null 2>&1; then
    echo "ℹ Deleting ${REMOTE}/${WIP_BRANCH}"
    git -C "$REPO_ROOT" push "$REMOTE" --delete "$WIP_BRANCH"
fi

git -C "$REPO_ROOT" fetch origin --prune 2>/dev/null || true
git -C "$REPO_ROOT" fetch all --prune 2>/dev/null || true

if [[ "$REMOVE_WORKTREE" -eq 1 && -n "$WORKTREE_PATH" ]]; then
    echo "ℹ Removing worktree ${WORKTREE_PATH}"
    git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH"
    WORKTREE_PATH=""
fi

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/${DONE_BRANCH}"; then
    still_wt="$(find_worktree_for_branch "$DONE_BRANCH" || true)"
    if [[ -n "$still_wt" ]]; then
        echo "⚠ Leaving local ${DONE_BRANCH} (checked out at ${still_wt})" >&2
    else
        echo "ℹ Deleting local ${DONE_BRANCH} (remote copy kept)"
        git -C "$REPO_ROOT" branch -D "$DONE_BRANCH"
    fi
fi

if branch_has_published_remote "$REPO_ROOT" "$DONE_BRANCH"; then
    echo "✓ Published ${DONE_BRANCH} on remotes; no unused local branch"
else
    echo "✗ ${DONE_BRANCH} not found on origin/ or all/ after push" >&2
    exit 1
fi
