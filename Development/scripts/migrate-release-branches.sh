#!/bin/bash

set -euo pipefail

# Migrates legacy flat release branches:
#   bX.Y.Z
#   vX.Y.Z
# to namespaced branches:
#   bX/bX.Y.Z
#
# Works on both local refs and remote refs present on the selected remote.
# Default mode is dry-run. Use --apply to perform changes.

APPLY=0
REMOTE_NAME="all"

usage() {
    echo "Usage: $0 [--apply] [--remote <name>] [--help]"
    echo ""
    echo "  --apply          Perform local + remote migration actions."
    echo "  --remote <name>  Remote to inspect/update (default: all)."
    echo "  --help           Show this help."
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --apply"
    echo "  $0 --apply --remote origin"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)
            APPLY=1
            shift
            ;;
        --remote)
            if [ $# -lt 2 ]; then
                echo "❌ --remote requires a value" >&2
                exit 1
            fi
            REMOTE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository." >&2
    exit 1
fi

current_branch="$(git branch --show-current)"
plan_file="/tmp/migrate-release-branches-plan-${CURSOR_PID:-$$}.txt"
remote_heads_file="/tmp/migrate-release-branches-remote-${CURSOR_PID:-$$}.txt"
: > "$plan_file"
: > "$remote_heads_file"

local_sha_for_branch() {
    local branch="$1"
    git rev-parse "refs/heads/${branch}" 2>/dev/null || true
}

remote_sha_for_branch() {
    local branch="$1"
    local line
    line="$(rg "^[0-9a-f]{40}[[:space:]]+refs/heads/${branch}$" "$remote_heads_file" -m 1 || true)"
    if [ -z "$line" ]; then
        echo ""
    else
        echo "$line" | awk '{print $1}'
    fi
}

append_plan_entry() {
    local scope="$1"
    local old="$2"
    local new="$3"
    local old_sha="$4"
    local new_sha="$5"
    local action
    if [ -z "$new_sha" ]; then
        action="rename"
    elif [ "$old_sha" = "$new_sha" ]; then
        action="duplicate_delete"
    else
        action="conflict_skip"
    fi
    printf '%s|%s|%s|%s|%s|%s\n' "$scope" "$old" "$new" "$old_sha" "$new_sha" "$action" >> "$plan_file"
}

legacy_to_new() {
    local raw_branch="$1"
    local normalized
    normalized="${raw_branch#heads/}"
    if [[ "$normalized" =~ ^[bv]([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local major="${BASH_REMATCH[1]}"
        local semver="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        echo "${normalized}|b${major}/b${semver}"
        return 0
    fi
    return 1
}

# Build local candidates
while IFS= read -r branch; do
    pair="$(legacy_to_new "$branch" || true)"
    if [ -z "$pair" ]; then
        continue
    fi
    old="${pair%%|*}"
    new="${pair#*|}"
    old_sha="$(local_sha_for_branch "$old")"
    [ -z "$old_sha" ] && continue
    new_sha="$(local_sha_for_branch "$new")"
    append_plan_entry "local" "$old" "$new" "$old_sha" "$new_sha"
done < <(git for-each-ref --format='%(refname:short)' refs/heads)

# Build remote candidates (without requiring local branches)
if git ls-remote --heads "$REMOTE_NAME" > "$remote_heads_file" 2>/dev/null; then
    while IFS= read -r line; do
        remote_sha="$(echo "$line" | awk '{print $1}')"
        remote_ref="$(echo "$line" | awk '{print $2}')"
        remote_branch="${remote_ref#refs/heads/}"
        pair="$(legacy_to_new "$remote_branch" || true)"
        if [ -z "$pair" ]; then
            continue
        fi
        old="${pair%%|*}"
        new="${pair#*|}"
        new_sha="$(remote_sha_for_branch "$new")"
        append_plan_entry "remote" "$old" "$new" "$remote_sha" "$new_sha"
    done < "$remote_heads_file"
else
    echo "⚠️ Could not read remote heads from ${REMOTE_NAME}; continuing with local branches only."
fi

count="$(wc -l < "$plan_file" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
    echo "ℹ️ No legacy flat branches found (bX.Y.Z or vX.Y.Z) on local refs or remote ${REMOTE_NAME}."
    exit 0
fi

echo "📋 Branch migration plan (${count}):"
while IFS='|' read -r scope old new old_sha new_sha action; do
    case "$action" in
        rename)
            echo "  - [${scope}] ${old} -> ${new}"
            ;;
        duplicate_delete)
            echo "  - [${scope}] ${old} == ${new} (same commit, duplicate can be deleted)"
            ;;
        conflict_skip)
            echo "  - [${scope}] ${old} -> ${new} (target exists with different commit, will skip)"
            ;;
    esac
done < "$plan_file"

if [ "$APPLY" -ne 1 ]; then
    echo ""
    echo "Dry-run complete. Re-run with --apply to execute."
    exit 0
fi

echo ""
echo "🚀 Applying migration..."

while IFS='|' read -r scope old new old_sha new_sha action; do
    if [ "$scope" = "local" ]; then
        case "$action" in
            conflict_skip)
                echo "⚠️ [local] Skipping ${old}: target ${new} exists with different commit."
                ;;
            duplicate_delete)
                echo "🧹 [local] Deleting duplicate legacy branch ${old}"
                if [ "$current_branch" = "$old" ]; then
                    git checkout "$new"
                    current_branch="$new"
                fi
                git branch -d "$old" 2>/dev/null || git branch -D "$old"
                ;;
            rename)
                echo "🔧 [local] Renaming ${old} -> ${new}"
                if [ "$current_branch" = "$old" ]; then
                    git branch -m "$new"
                    current_branch="$new"
                else
                    git branch -m "$old" "$new"
                fi
                ;;
        esac
    else
        case "$action" in
            conflict_skip)
                echo "⚠️ [remote] Skipping ${old}: target ${new} exists with different commit."
                ;;
            duplicate_delete)
                echo "🧹 [remote] Deleting duplicate legacy branch ${old} from ${REMOTE_NAME}"
                git push "$REMOTE_NAME" --delete "refs/heads/${old}" 2>/dev/null || true
                ;;
            rename)
                echo "🔧 [remote] Creating ${new} at ${old_sha} on ${REMOTE_NAME}"
                git push "$REMOTE_NAME" "${old_sha}:refs/heads/${new}"
                echo "🧹 [remote] Deleting legacy ${old} from ${REMOTE_NAME}"
                git push "$REMOTE_NAME" --delete "refs/heads/${old}" 2>/dev/null || true
                ;;
        esac
    fi
done < "$plan_file"

echo ""
echo "✅ Migration complete."
