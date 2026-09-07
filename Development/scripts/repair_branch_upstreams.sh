#!/usr/bin/env bash
# Retarget local done/* (and wip/* that track next) to origin/<same-name>
# or all/<same-name>. Does not change remote.pushDefault. See #459.

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

if [[ "$NO_FETCH" -eq 0 ]]; then
    git -C "$REPO" fetch origin --prune 2>/dev/null || true
    git -C "$REPO" fetch all --prune 2>/dev/null || true
fi

apply_if_needed() {
    local branch="$1"
    local merge
    if branch_upstream_is_matching "$REPO" "$branch"; then
        return 0
    fi
    set +e
    set_matching_branch_upstream "$REPO" "$branch" "$DRY"
    local rc=$?
    set -e
    return "$rc"
}

FAILED=0

while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    set +e
    apply_if_needed "$branch"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$rc" -ne 2 ]]; then
        FAILED=$((FAILED + 1))
    fi
done < <(git -C "$REPO" for-each-ref --format='%(refname:short)' refs/heads/done/)

while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    merge="$(branch_configured_merge "$REPO" "$branch")"
    if [[ "$merge" != "refs/heads/next" ]]; then
        continue
    fi
    set +e
    apply_if_needed "$branch"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$rc" -ne 2 ]]; then
        FAILED=$((FAILED + 1))
    fi
done < <(git -C "$REPO" for-each-ref --format='%(refname:short)' refs/heads/wip/)

if [[ "$FAILED" -ne 0 ]]; then
    echo "✗ ${FAILED} branch(es) failed to retarget" >&2
    exit 1
fi
exit 0
