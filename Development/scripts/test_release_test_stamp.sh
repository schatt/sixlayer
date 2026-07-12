#!/usr/bin/env bash
# Unit tests for release-process test-pass stamp / docs-only skip (#342, #343).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/release_test_stamp.sh"
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

echo "=== test_release_test_stamp (#346) ==="

if [ ! -f "$LIB" ]; then
    echo "❌ library missing: $LIB"
    exit 1
fi
# shellcheck source=/dev/null
source "$LIB"

# Isolate stamp file so tests never touch the real release stamp.
RELEASE_TEST_STAMP_FILE="$(mktemp "${TMPDIR:-/tmp}/release-test-stamp-file.XXXXXX")"
export RELEASE_TEST_STAMP_FILE
rm -f "$RELEASE_TEST_STAMP_FILE"

# --- path classification ---
assert_true "README.md is docs-only" release_is_docs_only_path "README.md"
assert_true "Development/RELEASE_v8.3.0.md is docs-only" release_is_docs_only_path "Development/RELEASE_v8.3.0.md"
assert_true "Development/AI_AGENT_v8.3.0.md is docs-only" release_is_docs_only_path "Development/AI_AGENT_v8.3.0.md"
assert_true "Framework/docs/foo.md is docs-only" release_is_docs_only_path "Framework/docs/foo.md"
assert_false "Framework/Sources/foo.swift is not docs-only" release_is_docs_only_path "Framework/Sources/foo.swift"
assert_false "Package.swift is not docs-only" release_is_docs_only_path "Package.swift"
assert_false "project.yml is not docs-only" release_is_docs_only_path "project.yml"

# --- single fixed stamp path ---
assert_eq "$(release_test_stamp_path)" "$RELEASE_TEST_STAMP_FILE" "stamp path is the single configured file"

# --- temp repo fixtures ---
REPO="$(mktemp -d "${TMPDIR:-/tmp}/release-test-stamp.XXXXXX")"
cleanup() { rm -rf "$REPO" "$RELEASE_TEST_STAMP_FILE"; }
trap cleanup EXIT

git -C "$REPO" init -q
git -C "$REPO" config user.email "test@example.com"
git -C "$REPO" config user.name "Test"
mkdir -p "$REPO/Framework/Sources" "$REPO/Development"
echo 'code' > "$REPO/Framework/Sources/A.swift"
echo 'readme' > "$REPO/README.md"
git -C "$REPO" add -A
git -C "$REPO" commit -qm "initial"
BASE="$(git -C "$REPO" rev-parse HEAD)"

# No stamp → do not skip
assert_false "no stamp means run tests" \
    release_should_skip_unit_tests "$REPO" 0

release_test_stamp_write "$BASE"
assert_eq "$(release_test_stamp_read_commit)" "$BASE" "stamp stores commit hash"
assert_eq "$(release_test_stamp_read_release_completed)" "0" "stamp marks release not completed on test pass"
assert_contains "$(cat "$RELEASE_TEST_STAMP_FILE")" "commit=$BASE" "stamp file uses commit= metadata"

# Same commit, clean tree → skip
assert_true "clean tree at stamped commit skips tests" \
    release_should_skip_unit_tests "$REPO" 0

# Docs-only working tree change → skip
echo 'docs bump' >> "$REPO/README.md"
assert_true "docs-only dirty tree still skips" \
    release_should_skip_unit_tests "$REPO" 0
git -C "$REPO" checkout -q -- README.md

# Code working tree change → run
echo 'code bump' >> "$REPO/Framework/Sources/A.swift"
assert_false "code dirty tree forces re-run" \
    release_should_skip_unit_tests "$REPO" 0
git -C "$REPO" checkout -q -- Framework/Sources/A.swift

# Docs-only commit after stamp → skip
echo 'more docs' >> "$REPO/Development/RELEASE_v9.0.0.md"
git -C "$REPO" add Development/RELEASE_v9.0.0.md
git -C "$REPO" commit -qm "docs only"
assert_true "docs-only commit after stamp skips" \
    release_should_skip_unit_tests "$REPO" 0

# Code commit after stamp → run
echo 'more code' >> "$REPO/Framework/Sources/A.swift"
git -C "$REPO" add Framework/Sources/A.swift
git -C "$REPO" commit -qm "code change"
assert_false "code commit after stamp forces re-run" \
    release_should_skip_unit_tests "$REPO" 0

# Force flag → run even when docs-only
release_test_stamp_write "$(git -C "$REPO" rev-parse HEAD)"
echo 'doc' >> "$REPO/README.md"
assert_false "--force-tests ignores stamp" \
    release_should_skip_unit_tests "$REPO" 1

# Invalid commit in stamp → run
printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' > "$RELEASE_TEST_STAMP_FILE"
assert_false "invalid stamp commit forces re-run" \
    release_should_skip_unit_tests "$REPO" 0

# --- stamp status / gate preview ---
git -C "$REPO" reset --hard "$BASE" >/dev/null
echo 'status doc' >> "$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit -qm "docs for status preview"
release_test_stamp_write "$BASE"
STATUS_OUT="$(release_print_unit_test_stamp_status "$REPO" 0)"
assert_contains "$STATUS_OUT" "Last green unit-test gate: $BASE" "status shows full last-pass hash"
assert_contains "$STATUS_OUT" "Release from this gate: not completed" "status explains tests-only stamp"
assert_contains "$STATUS_OUT" "Unit test gate (non-docs): would skip" "status shows skip when docs-only delta"

echo 'code bump' >> "$REPO/Framework/Sources/A.swift"
STATUS_RUN="$(release_print_unit_test_stamp_status "$REPO" 0)"
assert_contains "$STATUS_RUN" "Unit test gate (non-docs): would run" "status shows run when code changed"
git -C "$REPO" checkout -q -- Framework/Sources/A.swift

rm -f "$RELEASE_TEST_STAMP_FILE"
STATUS_NONE="$(release_print_unit_test_stamp_status "$REPO" 0)"
assert_contains "$STATUS_NONE" "Last green unit-test gate: (none recorded)" "status shows none when no stamp"

release_test_stamp_write "$BASE"
release_test_stamp_mark_release_complete
assert_eq "$(release_test_stamp_read_release_completed)" "1" "mark_release_complete sets flag"
COMPLETE_OUT="$(release_print_unit_test_stamp_status "$REPO" 0)"
assert_contains "$COMPLETE_OUT" "Release from this gate: completed successfully" "status shows completed release"

# Legacy bare-hash stamp still works for skip logic
printf '%s\n' "$BASE" > "$RELEASE_TEST_STAMP_FILE"
assert_true "legacy bare-hash stamp still skips on docs-only delta" \
    release_should_skip_unit_tests "$REPO" 0
assert_contains "$STATUS_NONE" "would run (no prior test-pass stamp)" "status shows run when no stamp"

# --- CLI wiring smoke (help) ---
HELP_OUT="$("${SCRIPT_DIR}/release-process.sh" --help 2>&1 || true)"
if printf '%s' "$HELP_OUT" | grep -Fq -- '--force-tests'; then
    echo "✅ help documents --force-tests"
    PASS=$((PASS + 1))
else
    echo "❌ help documents --force-tests"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
