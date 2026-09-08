#!/usr/bin/env bash
# Matching upstream for issue branches (#459).
#
# git push all does not set branch.*.merge. Creating a branch from origin/next
# or all/next sets merge=refs/heads/next. After wip → done rename, merge is
# left on next or a stale wip/ name unless we retarget to the matching name.
#
# Preferred remote: origin/<branch> when that remote-tracking ref exists,
# else all/<branch>. Already-matching origin-or-all + same-name merge is a no-op.
#
# shellcheck shell=bash

branch_configured_remote() {
    local repo="$1" branch="$2"
    git -C "$repo" config --get "branch.${branch}.remote" 2>/dev/null || true
}

branch_configured_merge() {
    local repo="$1" branch="$2"
    git -C "$repo" config --get "branch.${branch}.merge" 2>/dev/null || true
}

branch_upstream_is_matching() {
    local repo="$1" branch="$2"
    local remote merge
    remote="$(branch_configured_remote "$repo" "$branch")"
    merge="$(branch_configured_merge "$repo" "$branch")"
    if [ "$merge" != "refs/heads/${branch}" ]; then
        return 1
    fi
    case "$remote" in
        origin|all) return 0 ;;
        *) return 1 ;;
    esac
}

branch_preferred_upstream_remote() {
    local repo="$1" branch="$2"
    if git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
        echo origin
        return 0
    fi
    if git -C "$repo" show-ref --verify --quiet "refs/remotes/all/${branch}"; then
        echo all
        return 0
    fi
    return 1
}

# Usage: set_matching_branch_upstream <repo> <branch> [dry]
set_matching_branch_upstream() {
    local repo="$1" branch="$2" dry="${3:-}"
    local remote
    if branch_upstream_is_matching "$repo" "$branch"; then
        return 0
    fi
    if ! remote="$(branch_preferred_upstream_remote "$repo" "$branch")"; then
        echo "⚠️  No origin/${branch} or all/${branch} — skip ${branch}" >&2
        return 2
    fi
    if [ "$dry" = "dry" ]; then
        echo "would set ${branch} → ${remote}/${branch}"
        return 0
    fi
    git -C "$repo" branch --set-upstream-to="${remote}/${branch}" "$branch"
    echo "✅ ${branch} tracks ${remote}/${branch}"
}

# True when origin/<branch> or all/<branch> exists (safe to drop the local copy).
branch_has_published_remote() {
    local repo="$1" branch="$2"
    git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/${branch}" \
        || git -C "$repo" show-ref --verify --quiet "refs/remotes/all/${branch}"
}
