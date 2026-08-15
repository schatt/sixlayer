#!/usr/bin/env bash
# Unit tests for reclaim-ci-disk (#416, #417).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/reclaim_ci_disk.sh"
CLI="${SCRIPT_DIR}/reclaim-ci-disk.sh"
PASS=0
FAIL=0

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
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
    fi
}

if [[ ! -f "$LIB" ]]; then
    echo "❌ missing lib: $LIB"
    exit 1
fi
if [[ ! -f "$CLI" ]]; then
    echo "❌ missing CLI: $CLI"
    exit 1
fi

# shellcheck source=lib/reclaim_ci_disk.sh
source "$LIB"

# Mini is shared with CarManager; never simctl-delete/shutdown devices (#417).
assert_false "CLI does not invoke xcrun simctl delete" \
    grep -Fq 'xcrun simctl delete' "$CLI"
assert_false "CLI does not invoke xcrun simctl shutdown" \
    grep -Fq 'xcrun simctl shutdown' "$CLI"
assert_false "lib does not emit xcrun simctl delete" \
    grep -Fq 'xcrun simctl delete' "$LIB"
assert_false "lib does not invoke xcrun simctl shutdown" \
    grep -Fq 'xcrun simctl shutdown' "$LIB"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/reclaim-ci-disk-test.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

mkdir -p \
    "$WORKDIR/.ci-derived-data/SLF-iOS-UnitTests/Build" \
    "$WORKDIR/.ci-spm/SLF-iOS-UnitTests/checkouts" \
    "$WORKDIR/build/keep-me" \
    "$WORKDIR/Sources"
echo derived > "$WORKDIR/.ci-derived-data/SLF-iOS-UnitTests/Build/junk"
echo spm > "$WORKDIR/.ci-spm/SLF-iOS-UnitTests/checkouts/pkg"
mkdir -p "$WORKDIR/build/SLF-iOS-UnitTests.xcresult"
echo result > "$WORKDIR/build/SLF-iOS-UnitTests.xcresult/Info.plist"
echo keep > "$WORKDIR/build/keep-me/note.txt"
echo src > "$WORKDIR/Sources/File.swift"

reclaim_ci_disk_clean_workspace "$WORKDIR"

assert_false "removes .ci-derived-data" test -e "$WORKDIR/.ci-derived-data"
assert_false "removes .ci-spm" test -e "$WORKDIR/.ci-spm"
assert_false "removes build/*.xcresult" test -e "$WORKDIR/build/SLF-iOS-UnitTests.xcresult"
assert_true "preserves other build files" test -f "$WORKDIR/build/keep-me/note.txt"
assert_true "preserves Sources" test -f "$WORKDIR/Sources/File.swift"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
