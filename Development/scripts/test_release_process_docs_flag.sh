#!/usr/bin/env bash
# Tests for release-process.sh --docs (skip tests, no release).
# Refs #341

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SCRIPT="${SCRIPT_DIR}/release-process.sh"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PASS=0
FAIL=0

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

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        echo "❌ $label"
        echo "   must not contain: $needle"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
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

cd "$ROOT"

echo "=== test_release_process_docs_flag (#341) ==="

# --- Help documents --docs ---
HELP_OUT="$("$RELEASE_SCRIPT" --help 2>&1 || true)"
assert_contains "$HELP_OUT" "--docs" "help documents --docs"
assert_contains "$HELP_OUT" "skip" "help mentions skip (tests/release) for --docs"

# --- --docs and --release are mutually exclusive ---
set +e
MUTEX_OUT="$("$RELEASE_SCRIPT" --docs --release patch 2>&1)"
MUTEX_RC=$?
set -e
assert_exit_nonzero "$MUTEX_RC" "--docs --release exits nonzero"
assert_contains "$MUTEX_OUT" "mutually exclusive" "--docs --release reports mutual exclusion"

# --- --docs skips xcodebuild and does not release ---
FAKE_BIN="$(mktemp -d "${TMPDIR:-/tmp}/release-docs-flag.XXXXXX")"
cleanup() { rm -rf "$FAKE_BIN"; }
trap cleanup EXIT

cat > "${FAKE_BIN}/xcodebuild" <<'EOF'
#!/usr/bin/env bash
echo "XCODEBUILD_INVOKED" >&2
exit 99
EOF
chmod +x "${FAKE_BIN}/xcodebuild"

# Prefer an already-released version so doc checks can pass when the tree is clean.
# If checks fail for unrelated reasons, we still assert skip-tests / no-release signals.
set +e
DOCS_OUT="$(
    PATH="${FAKE_BIN}:${PATH}" \
    "$RELEASE_SCRIPT" --docs minor 8.2.0 2>&1
)"
DOCS_RC=$?
set -e

assert_not_contains "$DOCS_OUT" "XCODEBUILD_INVOKED" "--docs does not invoke xcodebuild"
assert_contains "$DOCS_OUT" "Docs-only mode" "--docs run prints Docs-only mode banner"
assert_contains "$DOCS_OUT" "Skipping unit tests (--docs)" "--docs explicitly skips unit tests"
assert_not_contains "$DOCS_OUT" "Creating and pushing tag" "--docs does not create/push release tag"
assert_not_contains "$DOCS_OUT" "Creating GitHub Release" "--docs does not create GitHub Release"
assert_not_contains "$DOCS_OUT" "Unknown option" "--docs is a recognized option"

# If documentation checks passed, docs mode must exit 0 and state that release was skipped.
if printf '%s' "$DOCS_OUT" | grep -Fq "All release documentation checks passed"; then
    if [ "$DOCS_RC" -eq 0 ]; then
        echo "✅ --docs exits 0 when documentation checks pass"
        PASS=$((PASS + 1))
    else
        echo "❌ --docs should exit 0 when documentation checks pass (got $DOCS_RC)"
        FAIL=$((FAIL + 1))
    fi
    assert_contains "$DOCS_OUT" "Skipping release" "--docs success message skips release"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
