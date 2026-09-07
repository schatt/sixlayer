#!/usr/bin/env bash
# Unit tests for wip tracking + dropping unused local done/ (#459).
#
# During work: local+remote wip/ with matching origin/wip/… (not next).
# After retire/repair: remotes keep done/; no unused local done/ branch.

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
assert_false "footgun branch is not matching upstream" \
    branch_upstream_is_matching "$REPO" "wip/footgun"

git -C "$REPO" push -q origin "wip/footgun"
git -C "$REPO" fetch -q origin
set_matching_branch_upstream "$REPO" "wip/footgun"
assert_eq "$(branch_configured_merge "$REPO" "wip/footgun")" "refs/heads/wip/footgun" \
    "helper sets merge to matching wip/ name"
assert_true "footgun is matching after helper" \
    branch_upstream_is_matching "$REPO" "wip/footgun"

git -C "$REPO" branch --no-track wip/no-track origin/next
assert_eq "$(branch_configured_merge "$REPO" "wip/no-track")" "" \
    "--no-track leaves merge unset"

# --- repair: leftover local done/ with remote counterpart is deleted ---
git -C "$REPO" branch --no-track done/456-splitview origin/next
git -C "$REPO" push -q origin done/456-splitview
git -C "$REPO" fetch -q origin
git -C "$REPO" config "branch.done/456-splitview.remote" all
git -C "$REPO" config "branch.done/456-splitview.merge" refs/heads/next
assert_true "local done/456 exists before repair" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/456-splitview

set +e
DRY_OUT="$("$REPAIR" --dry-run --no-fetch --git-dir "$REPO" 2>&1)"
RC=$?
set -e
assert_exit_zero "$RC" "repair --dry-run exits 0"
assert_true "dry-run leaves local done/456" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/456-splitview

set +e
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
RC=$?
set -e
assert_exit_zero "$RC" "repair script exits 0"
assert_false "repair deletes leftover local done/456" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/456-splitview
assert_true "origin/done/456 remains after local delete" \
    git -C "$REPO" show-ref --verify --quiet refs/remotes/origin/done/456-splitview

# --- repair: unique local-only done/ is not deleted ---
git -C "$REPO" branch --no-track done/no-remote origin/next
git -C "$REPO" config "branch.done/no-remote.remote" all
git -C "$REPO" config "branch.done/no-remote.merge" refs/heads/next
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
assert_true "repair keeps unique local-only done/no-remote" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/no-remote

# --- repair: live wip/ that tracks next is retargeted, not deleted ---
git -C "$REPO" branch --track wip/still-open origin/next
git -C "$REPO" push -q origin wip/still-open
git -C "$REPO" fetch -q origin
assert_eq "$(branch_configured_merge "$REPO" "wip/still-open")" "refs/heads/next" \
    "open wip from origin/next tracks next"
"$REPAIR" --no-fetch --git-dir "$REPO" >/dev/null
assert_true "repair keeps live local wip/still-open" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/wip/still-open
assert_eq "$(branch_configured_merge "$REPO" "wip/still-open")" "refs/heads/wip/still-open" \
    "repair retargets wip/ that tracked next"

# --- retire: remote done/ kept; no local done/ or wip/ ---
git -C "$REPO" branch --track wip/459-slug origin/next
git -C "$REPO" push -q origin wip/459-slug
git -C "$REPO" fetch -q origin
set +e
"$RETIRE" --git-dir "$REPO" --no-worktree-remove 459-slug >/dev/null
RC=$?
set -e
assert_exit_zero "$RC" "retire script exits 0"
assert_false "wip/459-slug is gone locally after retire" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/wip/459-slug
assert_false "done/459-slug is not kept as a local branch" \
    git -C "$REPO" show-ref --verify --quiet refs/heads/done/459-slug
assert_true "origin/done/459-slug exists after retire" \
    git -C "$REPO" show-ref --verify --quiet refs/remotes/origin/done/459-slug

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
