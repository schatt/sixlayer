#!/usr/bin/env bash
# Gate a PR on its Greptile review (#723): wait for the "Greptile Review" check
# run on the PR's *current* head SHA, then require zero unresolved Greptile
# review threads. Run before `gh pr merge`.
#
# Exit codes:
#   0  review complete on current head SHA, no unresolved Greptile threads
#   1  unresolved Greptile review threads remain (fix, push, resolve the thread)
#   2  review absent/pending past timeout, failed, or thread list truncated
#   3  usage error

set -euo pipefail

GREPTILE_APP_SLUG="greptile-apps"
GREPTILE_CHECK_NAME="Greptile Review"
GREPTILE_LOGIN_REGEX='^greptile-apps(\[bot\])?$'

usage() {
    echo "Usage: $0 [--repo owner/name] [--timeout SECONDS] [--interval SECONDS] <pr-number>" >&2
    echo "  Defaults: --timeout 900 --interval 20; repo from \$GH_REPO or the gh default." >&2
}

REPO="${GH_REPO:-}"
TIMEOUT=900
INTERVAL=20
PR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --repo|--timeout|--interval)
            [[ $# -ge 2 ]] || { echo "✗ $1 requires a value" >&2; usage; exit 3; }
            case "$1" in
                --repo) REPO="$2" ;;
                --timeout) TIMEOUT="$2" ;;
                --interval) INTERVAL="$2" ;;
            esac
            shift 2
            ;;
        -*) echo "✗ Unknown option: $1" >&2; usage; exit 3 ;;
        *)
            [[ -z "$PR" ]] || { echo "✗ Unexpected argument: $1" >&2; usage; exit 3; }
            PR="$1"
            shift
            ;;
    esac
done

[[ "$PR" =~ ^[0-9]+$ ]] || { echo "✗ PR number required" >&2; usage; exit 3; }
[[ "$TIMEOUT" =~ ^[0-9]+$ && "$INTERVAL" =~ ^[0-9]+$ ]] || { echo "✗ --timeout/--interval must be integers" >&2; usage; exit 3; }

if [[ -z "$REPO" ]]; then
    REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi
OWNER="${REPO%%/*}"
NAME="${REPO#*/}"

# Prints the Greptile check state for a SHA as "<status> <conclusion>", or
# nothing when no Greptile check run exists for that exact SHA.
greptile_check_state() {
    local sha="$1"
    gh api "repos/${REPO}/commits/${sha}/check-runs?per_page=100" \
        | jq -r --arg slug "$GREPTILE_APP_SLUG" --arg name "$GREPTILE_CHECK_NAME" --arg sha "$sha" '
            [.check_runs[]
             | select(.app.slug == $slug and .name == $name and .head_sha == $sha)]
            | first // empty
            | "\(.status) \(.conclusion // "none")"'
}

QUERY='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){pageInfo{hasNextPage} nodes{isResolved isOutdated comments(first:1){nodes{author{login} path body}}}}}}}'

DEADLINE=$((SECONDS + TIMEOUT))
SHA=""
STATE=""
while :; do
    SHA="$(gh pr view "$PR" --json headRefOid -q .headRefOid)"
    STATE="$(greptile_check_state "$SHA")"
    case "$STATE" in
        "completed success"|"completed neutral") break ;;
        completed\ *)
            echo "✗ Greptile review ended '${STATE#completed }' on ${SHA:0:9}; re-run it (e.g. comment @greptileai) and retry" >&2
            exit 2
            ;;
    esac
    if (( SECONDS >= DEADLINE )); then
        echo "✗ No completed Greptile review for head ${SHA:0:9} after ${TIMEOUT}s (state: ${STATE:-absent})" >&2
        exit 2
    fi
    echo "ℹ Waiting for Greptile review on ${SHA:0:9} (state: ${STATE:-absent})"
    sleep "$INTERVAL"
done

THREADS="$(gh api graphql -f query="$QUERY" -f o="$OWNER" -f r="$NAME" -F n="$PR")"

if [[ "$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' <<<"$THREADS")" != "false" ]]; then
    echo "✗ More than 100 review threads; cannot prove Greptile findings are resolved" >&2
    exit 2
fi

UNRESOLVED="$(jq -r --arg re "$GREPTILE_LOGIN_REGEX" '
    .data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | .comments.nodes[0]
    | select(.author.login | test($re))
    | "  - \(.path): \((.body | gsub("<[^>]*>"; "") | split("\n") | map(select(length > 0)) | first // "" | sub("^\\s+"; "")) | .[0:140])"
' <<<"$THREADS")"

if [[ -n "$UNRESOLVED" ]]; then
    echo "✗ Unresolved Greptile threads on PR #${PR} (head ${SHA:0:9}):" >&2
    echo "$UNRESOLVED" >&2
    exit 1
fi

echo "✓ Greptile review complete on ${SHA:0:9}; no unresolved Greptile threads"
