#!/usr/bin/env bash
# Drop unused local done/* when origin/all already has them. Retarget live
# wip/* that still track next. Does not change remote.pushDefault. See #459.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/branch_upstream.sh
source "${SCRIPT_DIR}/lib/branch_upstream.sh"

usage() {
    sed -n '2,3p' "$0" | sed 's/^# \?//'
    echo "Usage: $0 [--dry-run] [--no-fetch] [--git-dir|--repo <path>]"
}

DRY=""
NO_FETCH=0
REPO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --dry-run) DRY="dry"; shift ;;
        --no-fetch) NO_FETCH=1; shift ;;
        --git-dir|--repo)
            [[ $# -ge 2 ]] || { echo "✗ $1 requires a path" >&2; exit 1; }
            REPO="$2"
            shift 2
            ;;
        *)
            echo "✗ Unexpected argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO="${REPO:-$(pwd)}"
if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "✗ Not a git repository: $REPO" >&2
    exit 1
fi

GIT_COMMON="$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)"
REPO_ROOT="$(dirname "$GIT_COMMON")"
CURRENT="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"

worktree_for_branch() {
    local want="$1"
    local wt="" branch=""
    while IFS= read -r line; do
        case "$line" in
            worktree*) wt="${line#worktree }"; branch="" ;;
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

if [[ "$NO_FETCH" -eq 0 ]]; then
    git -C "$REPO_ROOT" fetch origin --prune 2>/dev/null || true
    git -C "$REPO_ROOT" fetch all --prune 2>/dev/null || true
fi

FAILED=0

delete_unused_local_done() {
    local branch="$1"
    if [[ "$branch" == "$CURRENT" ]]; then
        echo "⚠ Skipping ${branch} (currently checked out)" >&2
        return 0
    fi
    if worktree_for_branch "$branch" >/dev/null; then
        echo "⚠ Skipping ${branch} (registered worktree)" >&2
        return 0
    fi
    if ! branch_has_published_remote "$REPO_ROOT" "$branch"; then
        echo "⚠️  No origin/${branch} or all/${branch} — skip ${branch}" >&2
        return 0
    fi
    if [[ "$DRY" = "dry" ]]; then
        echo "would delete local ${branch}"
        return 0
    fi
    git -C "$REPO_ROOT" branch -D "$branch"
    echo "✅ Deleted local ${branch}"
}

while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    set +e
    delete_unused_local_done "$branch"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        FAILED=$((FAILED + 1))
    fi
done < <(git -C "$REPO_ROOT" for-each-ref --format='%(refname:short)' refs/heads/done/)

retarget_wip_off_next() {
    local branch="$1"
    local merge
    merge="$(branch_configured_merge "$REPO_ROOT" "$branch")"
    if [[ "$merge" != "refs/heads/next" ]]; then
        return 0
    fi
    local rc
    set +e
    set_matching_branch_upstream "$REPO_ROOT" "$branch" "$DRY"
    rc=$?
    set -e
    if [[ "$rc" -eq 2 ]]; then
        return 0
    fi
    return "$rc"
}

while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    set +e
    retarget_wip_off_next "$branch"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
        FAILED=$((FAILED + 1))
    fi
done < <(git -C "$REPO_ROOT" for-each-ref --format='%(refname:short)' refs/heads/wip/)

if [[ "$FAILED" -ne 0 ]]; then
    echo "✗ ${FAILED} branch(es) failed" >&2
    exit 1
fi
exit 0
