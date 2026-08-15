#!/usr/bin/env bash
# Release unit gate must not prune unavailable simulators (#413).
#
# Refs #413

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

echo "=== test_release_process_no_simctl_prune (#413) ==="

if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "❌ release-process.sh missing at $RELEASE_SCRIPT"
    exit 1
fi

IOS_BLOCK="$(
    awk '
      /Running iOS unit tests on Simulator \(SLF-iOS-UnitTests\)/ {capture=1}
      capture {print}
      capture && /Recorded iOS unit-test pass/ {exit}
    ' "$RELEASE_SCRIPT"
)"

assert_not_contains "$IOS_BLOCK" "simctl delete unavailable" "iOS unit gate does not prune unavailable simulators"
assert_not_contains "$IOS_BLOCK" "Pruning unavailable" "iOS unit gate does not announce a prune"
assert_contains "$IOS_BLOCK" "rtk xcodebuild test" "iOS unit gate still runs xcodebuild test"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
