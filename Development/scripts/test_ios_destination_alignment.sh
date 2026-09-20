#!/usr/bin/env bash
# Regression: simulator destinations must use ensure-ci-simulator-destination
# (#494 iOS, #495 tvOS/watchOS/visionOS, #496 TEST_PERFORMANCE_ANALYSIS).

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
PERF="$ROOT/TEST_PERFORMANCE_ANALYSIS.md"

assert_true "buildconfig.yml exists" test -f "$BUILDCONFIG"
assert_true "release-process.sh exists" test -f "$RELEASE"

# iOS (#494)
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

assert_true "release-process invokes ensure via \$REPO_ROOT" \
    grep -qE '\$\{?REPO_ROOT\}?/Development/scripts/ensure-ci-simulator-destination\.sh|"\$REPO_ROOT/Development/scripts/ensure-ci-simulator-destination\.sh"' "$RELEASE"

assert_false "release-process does not use relative ./Development/scripts/ensure" \
    grep -qE '\$\(\./Development/scripts/ensure-ci-simulator-destination\.sh' "$RELEASE"

assert_true "TESTING_COMMANDS documents ensure script" \
    grep -qE 'ensure-ci-simulator-destination\.sh' "$ROOT/Development/TESTING_COMMANDS.md"

# tvOS / watchOS / visionOS (#495)
assert_false "buildconfig has no bare name=Apple TV" \
    grep -q 'name=Apple TV' "$BUILDCONFIG"

assert_false "buildconfig has no bare Apple Watch Series name=" \
    grep -qE 'name=Apple Watch Series' "$BUILDCONFIG"

assert_false "buildconfig has no bare name=Apple Vision Pro" \
    grep -q 'name=Apple Vision Pro' "$BUILDCONFIG"

assert_true "buildconfig tvOS commands use ensure-ci-simulator-destination.sh tvOS" \
    grep -qE 'ensure-ci-simulator-destination\.sh tvOS' "$BUILDCONFIG"

assert_true "buildconfig watchOS commands use ensure-ci-simulator-destination.sh watchOS" \
    grep -qE 'ensure-ci-simulator-destination\.sh watchOS' "$BUILDCONFIG"

assert_true "buildconfig visionOS commands use ensure-ci-simulator-destination.sh visionOS" \
    grep -qE 'ensure-ci-simulator-destination\.sh visionOS' "$BUILDCONFIG"

assert_true "TESTING_COMMANDS documents non-iOS ensure families" \
    grep -qE 'ensure-ci-simulator-destination\.sh (tvOS|watchOS|visionOS)' "$ROOT/Development/TESTING_COMMANDS.md"

# TEST_PERFORMANCE_ANALYSIS (#496)
assert_true "TEST_PERFORMANCE_ANALYSIS.md exists" test -f "$PERF"

assert_false "TEST_PERFORMANCE_ANALYSIS has no bare name=iPhone 17 Pro Max" \
    grep -q 'name=iPhone 17 Pro Max' "$PERF"

assert_true "TEST_PERFORMANCE_ANALYSIS documents ensure script" \
    grep -qE 'ensure-ci-simulator-destination\.sh' "$PERF"

echo
echo "Passed: $PASS  Failed: $FAIL"
exit "$FAIL"
