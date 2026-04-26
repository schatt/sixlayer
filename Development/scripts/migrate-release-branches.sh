#!/bin/bash

set -euo pipefail

# Migrates legacy flat release branches:
#   bX.Y.Z
# to namespaced branches:
#   bX/bX.Y.Z
#
# Default mode is dry-run. Use --apply to perform changes.

APPLY=0
REMOTE_NAME="all"

usage() {
    echo "Usage: $0 [--apply] [--remote <name>] [--help]"
    echo ""
    echo "  --apply          Perform local rename + remote push/delete."
    echo "  --remote <name>  Remote to update (default: all)."
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

declare -a old_branches
declare -a new_branches

while IFS= read -r branch; do
    if [[ "$branch" =~ ^b([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        old_branches+=("$branch")
        new_branches+=("b${major}/${branch}")
    fi
done < <(git for-each-ref --format='%(refname:short)' refs/heads)

count="${#old_branches[@]}"
if [ "$count" -eq 0 ]; then
    echo "ℹ️ No legacy flat branches found (bX.Y.Z)."
    exit 0
fi

echo "📋 Branch migration plan (${count}):"
for i in "${!old_branches[@]}"; do
    old="${old_branches[$i]}"
    new="${new_branches[$i]}"
    echo "  - ${old} -> ${new}"
done

if [ "$APPLY" -ne 1 ]; then
    echo ""
    echo "Dry-run complete. Re-run with --apply to execute."
    exit 0
fi

echo ""
echo "🚀 Applying migration..."

for i in "${!old_branches[@]}"; do
    old="${old_branches[$i]}"
    new="${new_branches[$i]}"

    if git show-ref --verify --quiet "refs/heads/${new}"; then
        echo "⚠️ Skipping ${old}: target ${new} already exists locally."
        continue
    fi

    echo "🔧 Renaming local branch ${old} -> ${new}"
    if [ "$current_branch" = "$old" ]; then
        git branch -m "$new"
        current_branch="$new"
    else
        git branch -m "$old" "$new"
    fi

    echo "📤 Pushing ${new} to ${REMOTE_NAME}"
    git push "$REMOTE_NAME" -u "$new"

    echo "🧹 Deleting remote ${old} from ${REMOTE_NAME} (if present)"
    git push "$REMOTE_NAME" --delete "$old" 2>/dev/null || true
done

echo ""
echo "✅ Migration complete."
