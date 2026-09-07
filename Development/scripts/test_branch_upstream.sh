#!/usr/bin/env bash
# Unit tests for matching wip/done upstreams (#459).
#
# Proves: create-from-remote-next tracks next; helper/retire/repair leave
# merge on the matching branch name, not next or a stale wip/ name.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/branch_upstream.sh"
REPAIR="${SCRIPT_DIR}/repair_branch_upstreams.sh"
RETIRE="${SCRIPT_DIR}/retire_wip_branch.sh"
PASS=0
FAIL=0

assert_eq() {
    local got="$1" want="$2" label="$3"
    if [ "$got" = "$want" ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   got:  $got"
        echo "   want: $want"
        FAIL=$((FAIL + 1))
    fi
}

assert_true() {
    local label="$1"
    shift
    if "$@"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    fi
}

assert_false() {
    local label="$1"
    shift
    if "$@"; then
        echo "❌ $label (expected false)"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
    fi
}

assert_exit_zero() {
    local rc="$1" label="$2"
    if [ "$rc" -eq 0 ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label (expected exit 0, got $rc)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== test_branch_upstream (#459) ==="

if [ ! -f "$LIB" ]; then
    echo "❌ library missing: $LIB"
    exit 1
fi
# shellcheck source=/dev/null
source "$LIB"

if [ ! -x "$REPAIR" ]; then
    echo "❌ repair script missing or not executable: $REPAIR"
    exit 1
fi
if [ ! -x "$RETIRE" ]; then
    echo "❌ retire script missing or not executable: $RETIRE"
    exit 1
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/branch-upstream.XXXXXX")"
ORIGIN_BARE="${WORKDIR}/origin.git"
ALL_BARE="${WORKDIR}/all.git"
REPO="${WORKDIR}/repo"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

git init -q --bare "$ORIGIN_BARE"
git init -q --bare "$ALL_BARE"

git clone -q "$ORIGIN_BARE" "$REPO"
git -C "$REPO" config user.email "test@example.com"
git -C "$REPO" config user.name "Test"
git -C "$REPO" checkout -q -b next
echo "seed" > "$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit -q -m "seed"
git -C "$REPO" push -q -u origin next
git -C "$REPO" remote add all "$ALL_BARE"
git -C "$REPO" remote set-url --add --push all "$ORIGIN_BARE"
git -C "$REPO" remote set-url --add --push all "$ALL_BARE"
git -C "$REPO" config remote.pushDefault all
git -C "$REPO" push -q all next
git -C "$REPO" fetch -q all

# --- footgun: branch from origin/next tracks next ---
git -C "$REPO" branch --track wip/footgun origin/next
assert_eq "$(branch_configured_merge "$REPO" "wip/footgun")" "refs/heads/next" \
    "branch from origin/next without --no-track sets merge=next"
assert_eq "$(branch_configured_remote "$REPO" "wip/footgun")" "origin" \
    "branch from origin/next without --no-track sets remote=origin"
assert_false "footgun branch is not matching upstream" \
    branch_upstream_is_matching "$REPO" "wip/footgun"

# Publish the wip name so a matching remote ref exists, then retarget.
git -C "$REPO" push -q origin "wip/footgun"
git -C "$REPO" fetch -q origin
set +e
set_matching_branch_upstream "$REPO" "wip/footgun"
RC=$?
set -e
assert_exit_zero "$RC" "set_matching_branch_upstream retargets footgun off next"
assert_eq "$(branch_configured_merge "$REPO" "wip/footgun")" "refs/heads/wip/footgun" \
    "helper sets merge to matching wip/ name"
assert_eq "$(branch_configured_remote "$REPO" "wip/footgun")" "origin" \
    "helper prefers origin when origin/<branch> exists"
assert_true "footgun is matching after helper" \
    branch_upstream_is_matching "$REPO" "wip/footgun"

# Idempotent: already matching stays matching.
set_matching_branch_upstream "$REPO" "wip/footgun"
assert_true "second helper pass is a no-op" \
    branch_upstream_is_matching "$REPO" "wip/footgun"

# --no-track does not inherit next.
git -C "$REPO" branch --no-track wip/no-track origin/next
assert_eq "$(branch_configured_merge "$REPO" "wip/no-track")" "" \
    "--no-track leaves merge unset"

# --- repair: done/ tracking next ---
git -C "$REPO" branch --no-track done/456-splitview origin/next
git -C "$REPO" push -q origin done/456-splitview
git -C "$REPO" fetch -q origin
git -C "$REPO" config "branch.done/456-splitview.remote" all
git -C "$REPO" config "branch.done/456-splitview.merge" refs/heads/next
assert_false "done/456 tracks next before repair" \
    branch_upstream_is_matching "$REPO" "done/456-splitview"

set +e
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
RC=$?
set -e
assert_exit_zero "$RC" "repair script exits 0"
assert_eq "$(branch_configured_merge "$REPO" "done/456-splitview")" "refs/heads/done/456-splitview" \
    "repair retargets done/ off next"
assert_eq "$(branch_configured_remote "$REPO" "done/456-splitview")" "origin" \
    "repair prefers origin for done/"
assert_true "done/456 is matching after repair" \
    branch_upstream_is_matching "$REPO" "done/456-splitview"

# --- repair: done/ merge still names stale wip/ ---
git -C "$REPO" branch --no-track done/314-stale origin/next
git -C "$REPO" push -q origin done/314-stale
git -C "$REPO" fetch -q origin
git -C "$REPO" config "branch.done/314-stale.remote" all
git -C "$REPO" config "branch.done/314-stale.merge" refs/heads/wip/314-stale
assert_false "done/314 stale wip merge is not matching" \
    branch_upstream_is_matching "$REPO" "done/314-stale"
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
assert_eq "$(branch_configured_merge "$REPO" "done/314-stale")" "refs/heads/done/314-stale" \
    "repair retargets done/ off stale wip/ merge"
assert_true "done/314 is matching after repair" \
    branch_upstream_is_matching "$REPO" "done/314-stale"

# --- repair dry-run does not change config ---
git -C "$REPO" config "branch.done/456-splitview.merge" refs/heads/next
set +e
DRY_OUT="$("$REPAIR" --dry-run --no-fetch --git-dir "$REPO" 2>&1)"
RC=$?
set -e
assert_exit_zero "$RC" "repair --dry-run exits 0"
assert_eq "$(branch_configured_merge "$REPO" "done/456-splitview")" "refs/heads/next" \
    "repair --dry-run leaves merge=next"
git -C "$REPO" config "branch.done/456-splitview.merge" refs/heads/done/456-splitview

# --- repair: wip/ that tracks next ---
git -C "$REPO" branch --track wip/still-open origin/next
git -C "$REPO" push -q origin wip/still-open
git -C "$REPO" fetch -q origin
assert_eq "$(branch_configured_merge "$REPO" "wip/still-open")" "refs/heads/next" \
    "open wip from origin/next tracks next"
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
assert_eq "$(branch_configured_merge "$REPO" "wip/still-open")" "refs/heads/wip/still-open" \
    "repair retargets wip/ that tracked next"

# --- retire: rename keeps merge=next unless script retargets ---
git -C "$REPO" branch --track wip/459-slug origin/next
git -C "$REPO" push -q origin wip/459-slug
git -C "$REPO" fetch -q origin
assert_eq "$(branch_configured_merge "$REPO" "wip/459-slug")" "refs/heads/next" \
    "pre-retire wip tracks next"
set +e
"$RETIRE" --git-dir "$REPO" --no-worktree-remove 459-slug >/dev/null
RC=$?
set -e
assert_exit_zero "$RC" "retire script exits 0"
assert_false "wip/459-slug is gone after retire" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/wip/459-slug
assert_true "done/459-slug exists after retire" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/459-slug
assert_eq "$(branch_configured_merge "$REPO" "done/459-slug")" "refs/heads/done/459-slug" \
    "retire sets merge to done/ name not next"
assert_eq "$(branch_configured_remote "$REPO" "done/459-slug")" "origin" \
    "retire prefers origin/done/"
assert_true "retired branch is matching" \
    branch_upstream_is_matching "$REPO" "done/459-slug"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
