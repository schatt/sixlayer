#!/usr/bin/env bash
# Unit tests for release-process test-pass stamp / docs-only skip (#342).

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

echo "=== test_release_test_stamp (#342) ==="

if [ ! -f "$LIB" ]; then
    echo "❌ library missing: $LIB"
    exit 1
fi
# shellcheck source=/dev/null
source "$LIB"

# --- path classification ---
assert_true "README.md is docs-only" release_is_docs_only_path "README.md"
assert_true "Development/RELEASE_v8.3.0.md is docs-only" release_is_docs_only_path "Development/RELEASE_v8.3.0.md"
assert_true "Development/AI_AGENT_v8.3.0.md is docs-only" release_is_docs_only_path "Development/AI_AGENT_v8.3.0.md"
assert_true "Framework/docs/foo.md is docs-only" release_is_docs_only_path "Framework/docs/foo.md"
assert_false "Framework/Sources/foo.swift is not docs-only" release_is_docs_only_path "Framework/Sources/foo.swift"
assert_false "Package.swift is not docs-only" release_is_docs_only_path "Package.swift"
assert_false "project.yml is not docs-only" release_is_docs_only_path "project.yml"

# --- temp repo fixtures ---
REPO="$(mktemp -d "${TMPDIR:-/tmp}/release-test-stamp.XXXXXX")"
cleanup() { rm -rf "$REPO"; }
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

STAMP_PATH="$(release_test_stamp_path "$REPO")"
rm -f "$STAMP_PATH"

# No stamp → do not skip
assert_false "no stamp means run tests" \
    release_should_skip_unit_tests "$REPO" 0

release_test_stamp_write "$REPO" "$BASE"
assert_eq "$(release_test_stamp_read_commit "$REPO")" "$BASE" "stamp stores commit"

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
release_test_stamp_write "$REPO" "$(git -C "$REPO" rev-parse HEAD)"
echo 'doc' >> "$REPO/README.md"
assert_false "--force-tests ignores stamp" \
    release_should_skip_unit_tests "$REPO" 1

# Invalid commit in stamp → run
printf 'commit=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\nrepo=%s\n' "$REPO" > "$STAMP_PATH"
assert_false "invalid stamp commit forces re-run" \
    release_should_skip_unit_tests "$REPO" 0

# Wrong repo path in stamp → run
release_test_stamp_write "$REPO" "$(git -C "$REPO" rev-parse HEAD)"
# corrupt repo= line
sed -i.bak 's|^repo=.*|repo=/tmp/other-repo|' "$STAMP_PATH"
assert_false "stamp for different repo forces re-run" \
    release_should_skip_unit_tests "$REPO" 0

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
