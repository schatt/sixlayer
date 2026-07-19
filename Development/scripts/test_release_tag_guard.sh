#!/usr/bin/env bash
# Unit tests for release tag existence guard (#356).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/release_tag_guard.sh"
RELEASE_SCRIPT="${SCRIPT_DIR}/release-process.sh"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
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

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   expected to contain: $needle"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_nonzero() {
    local rc="$1"
    local label="$2"
    if [ "$rc" -ne 0 ]; then
        echo "✅ $label (exit $rc)"
        PASS=$((PASS + 1))
    else
        echo "❌ $label (expected nonzero exit)"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_zero() {
    local rc="$1"
    local label="$2"
    if [ "$rc" -eq 0 ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label (expected exit 0, got $rc)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== test_release_tag_guard (#356, #357) ==="

if [ ! -f "$LIB" ]; then
    echo "❌ library missing: $LIB"
    exit 1
fi
# shellcheck source=/dev/null
source "$LIB"

REPO="$(mktemp -d "${TMPDIR:-/tmp}/release-tag-guard.XXXXXX")"
REMOTE="$(mktemp -d "${TMPDIR:-/tmp}/release-tag-guard-remote.XXXXXX")"
cleanup() { rm -rf "$REPO" "$REMOTE"; }
trap cleanup EXIT

git -C "$REPO" init -q
git -C "$REPO" config user.email "test@example.com"
git -C "$REPO" config user.name "Test"
echo "seed" > "$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit -q -m "seed"

git -C "$REMOTE" init -q --bare
git -C "$REPO" remote add origin "$REMOTE"
git -C "$REPO" push -q origin HEAD:main

# --- tag name normalization ---
assert_eq "$(release_tag_name_for_version "8.3.0")" "v8.3.0" "version without v becomes v8.3.0"
assert_eq "$(release_tag_name_for_version "v8.3.0")" "v8.3.0" "version with v stays v8.3.0"

cd "$REPO"

# --- local absence ---
assert_false "missing local tag is absent" release_tag_exists_local "v9.9.9"
assert_false "missing tag is absent overall" release_tag_exists "v9.9.9"
set +e
OUT="$(release_abort_if_tag_exists "9.9.9" 2>&1)"
RC=$?
set -e
assert_exit_zero "$RC" "abort helper allows missing tag"

# --- local presence ---
git tag -a "v8.3.0" -m "Release v8.3.0"
assert_true "local tag v8.3.0 exists" release_tag_exists_local "v8.3.0"
assert_true "existing local tag is detected overall" release_tag_exists "v8.3.0"
set +e
OUT="$(release_abort_if_tag_exists "8.3.0" 2>&1)"
RC=$?
set -e
assert_exit_nonzero "$RC" "abort helper rejects existing local tag"
assert_contains "$OUT" "v8.3.0" "abort message names the tag"
assert_contains "$OUT" "already exists" "abort message says already exists"

# --- remote-only presence (no local tag) ---
git push -q origin "v8.3.0"
git tag -d "v8.3.0" >/dev/null
assert_false "deleted local tag is absent locally" release_tag_exists_local "v8.3.0"
assert_true "remote tag is detected" release_tag_exists_on_remotes "v8.3.0"
assert_true "remote-only tag is detected overall" release_tag_exists "v8.3.0"
set +e
OUT="$(release_abort_if_tag_exists "8.3.0" 2>&1)"
RC=$?
set -e
assert_exit_nonzero "$RC" "abort helper rejects remote-only tag"
assert_contains "$OUT" "already exists" "remote abort message says already exists"

# --- release-process.sh: tag check is Step 1 (Refs #357) ---
cd "$ROOT"
EXISTING_TAG="$(git tag 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1 || true)"
if [ -n "$EXISTING_TAG" ]; then
    EXISTING_VERSION="${EXISTING_TAG#v}"
    set +e
    SCRIPT_OUT="$("$RELEASE_SCRIPT" --release patch "$EXISTING_VERSION" 2>&1)"
    SCRIPT_RC=$?
    set -e
    assert_exit_nonzero "$SCRIPT_RC" "release-process aborts when tag already exists"
    assert_contains "$SCRIPT_OUT" "Starting release process for v${EXISTING_VERSION}" \
        "start banner runs before tag Step 1"
    assert_contains "$SCRIPT_OUT" "Step 1:" "tag existence is labeled Step 1"
    assert_contains "$SCRIPT_OUT" "already exists" "Step 1 reports tag already exists"
    if printf '%s' "$SCRIPT_OUT" | grep -Fq "Step 1: Ensuring Xcode project"; then
        echo "❌ xcodegen must not remain Step 1 when tag check is first"
        FAIL=$((FAIL + 1))
    else
        echo "✅ xcodegen is not Step 1"
        PASS=$((PASS + 1))
    fi
else
    echo "⚠️  No local semver tags; skipping release-process Step 1 ordering checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
