#!/usr/bin/env bash
# Asserts release-process.sh unit gate uses a single `rtk xcodebuild test`
# (revert of the #410 build-for-testing / test-without-building split; #411).
#
# Refs #411

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SCRIPT="${SCRIPT_DIR}/release-process.sh"
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

echo "=== test_release_process_unit_gate (#411) ==="

if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "❌ release-process.sh missing at $RELEASE_SCRIPT"
    exit 1
fi

SRC="$(cat "$RELEASE_SCRIPT")"

MACOS_BLOCK="$(
    awk '
      /Running macOS unit tests \(SLF-macOS-UnitTests\)/ {capture=1}
      capture {print}
      capture && /Recorded macOS unit-test pass/ {exit}
    ' "$RELEASE_SCRIPT"
)"

IOS_BLOCK="$(
    awk '
      /Running iOS unit tests on Simulator \(SLF-iOS-UnitTests\)/ {capture=1}
      capture {print}
      capture && /Recorded iOS unit-test pass/ {exit}
    ' "$RELEASE_SCRIPT"
)"

assert_contains "$MACOS_BLOCK" "rtk xcodebuild test" "macOS unit gate uses rtk xcodebuild test"
assert_not_contains "$MACOS_BLOCK" "build-for-testing" "macOS unit gate does not use build-for-testing"
assert_not_contains "$MACOS_BLOCK" "test-without-building" "macOS unit gate does not use test-without-building"
assert_not_contains "$MACOS_BLOCK" "release_run_platform_unit_tests" "macOS unit gate does not call helper"

assert_contains "$IOS_BLOCK" "rtk xcodebuild test" "iOS unit gate uses rtk xcodebuild test"
assert_not_contains "$IOS_BLOCK" "build-for-testing" "iOS unit gate does not use build-for-testing"
assert_not_contains "$IOS_BLOCK" "test-without-building" "iOS unit gate does not use test-without-building"
assert_not_contains "$IOS_BLOCK" "release_run_platform_unit_tests" "iOS unit gate does not call helper"

assert_not_contains "$SRC" "release_run_platform_unit_tests() {" "helper function is removed"
assert_contains "$SRC" "FB24278669" "script still references Apple Feedback FB24278669"
assert_contains "$SRC" "#411" "script references issue #411"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
