#!/usr/bin/env bash
# Regression: iOS destinations must use ensure-ci-simulator-destination (#494).
# Fails if buildconfig / release still hardcode name=iPhone 17 Pro Max.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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
    if ! "$@"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    fi
}

BUILDCONFIG="$ROOT/buildconfig.yml"
RELEASE="$ROOT/Development/scripts/release-process.sh"
ENSURE="Development/scripts/ensure-ci-simulator-destination.sh"

assert_true "buildconfig.yml exists" test -f "$BUILDCONFIG"
assert_true "release-process.sh exists" test -f "$RELEASE"

# iOS build_command lines must invoke ensure script, not bare Pro Max name.
assert_false "buildconfig has no bare name=iPhone 17 Pro Max" \
    grep -q 'name=iPhone 17 Pro Max' "$BUILDCONFIG"

assert_true "buildconfig iOS commands use ensure-ci-simulator-destination.sh" \
    grep -qE 'ensure-ci-simulator-destination\.sh iOS' "$BUILDCONFIG"

assert_false "release-process has no name=\${IOS_SIM_NAME} destination" \
    grep -qE 'destination "platform=iOS Simulator,name=\$\{IOS_SIM_NAME\}"' "$RELEASE"

assert_false "release-process does not hand-roll iPhone-16-Pro create for Pro Max" \
    grep -q 'SimDeviceType.iPhone-16-Pro' "$RELEASE"

assert_true "release-process uses ensure-ci-simulator-destination.sh" \
    grep -qE 'ensure-ci-simulator-destination\.sh' "$RELEASE"

assert_true "TESTING_COMMANDS documents ensure script" \
    grep -qE 'ensure-ci-simulator-destination\.sh' "$ROOT/Development/TESTING_COMMANDS.md"

echo
echo "Passed: $PASS  Failed: $FAIL"
exit "$FAIL"
