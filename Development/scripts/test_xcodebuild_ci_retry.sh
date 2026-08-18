#!/usr/bin/env bash
# Unit tests for xcodebuild CI bootstrap-retry helpers (#432).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/xcodebuild_ci_retry.sh"
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

if [[ ! -f "$LIB" ]]; then
    echo "❌ missing lib: $LIB"
    exit 1
fi

# shellcheck source=lib/xcodebuild_ci_retry.sh
source "$LIB"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/xcodebuild-ci-retry-test.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

BOOTSTRAP_LOG="$WORKDIR/bootstrap.log"
cat > "$BOOTSTRAP_LOG" <<'EOF'
Test case 'NativeTypesTests/testIntegerFieldNativeBinding()' passed on 'Clone 1 of iPhone 17 Pro Max - xctest (7208)' (11.919 seconds)
xctest (7169) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: The test runner exited with code 1 before establishing connection.))
** TEST FAILED **
EOF

ASSERTION_LOG="$WORKDIR/assertion.log"
cat > "$ASSERTION_LOG" <<'EOF'
Test case 'ExampleTests/testThing()' failed on 'Clone 1 of iPhone 17 Pro Max - xctest (7208)' (0.012 seconds)
** TEST FAILED **
EOF

MIXED_LOG="$WORKDIR/mixed.log"
cat > "$MIXED_LOG" <<'EOF'
Test case 'ExampleTests/testThing()' failed on 'Clone 1 of iPhone 17 Pro Max - xctest (7208)' (0.012 seconds)
xctest (7169) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: The test runner exited with code 1 before establishing connection.))
** TEST FAILED **
EOF

COMPILE_LOG="$WORKDIR/compile.log"
cat > "$COMPILE_LOG" <<'EOF'
error: cannot find 'Foo' in scope
** TEST FAILED **
EOF

PASS_LOG="$WORKDIR/pass.log"
cat > "$PASS_LOG" <<'EOF'
Test case 'ExampleTests/testThing()' passed on 'Clone 1 of iPhone 17 Pro Max - xctest (7208)' (0.012 seconds)
** TEST SUCCEEDED **
EOF

assert_true "bootstrap-only log is runner bootstrap failure" \
    xcodebuild_ci_log_is_runner_bootstrap_failure "$BOOTSTRAP_LOG"
assert_false "assertion failure log is not runner bootstrap failure" \
    xcodebuild_ci_log_is_runner_bootstrap_failure "$ASSERTION_LOG"
assert_false "mixed assertion + bootstrap is not treated as bootstrap-only" \
    xcodebuild_ci_log_is_runner_bootstrap_failure "$MIXED_LOG"
assert_false "compile failure log is not runner bootstrap failure" \
    xcodebuild_ci_log_is_runner_bootstrap_failure "$COMPILE_LOG"
assert_false "passing log is not runner bootstrap failure" \
    xcodebuild_ci_log_is_runner_bootstrap_failure "$PASS_LOG"

assert_true "nonzero + bootstrap-only should retry" \
    xcodebuild_ci_should_retry 65 "$BOOTSTRAP_LOG"
assert_false "zero exit should not retry even with bootstrap text" \
    xcodebuild_ci_should_retry 0 "$BOOTSTRAP_LOG"
assert_false "nonzero + assertion failure should not retry" \
    xcodebuild_ci_should_retry 65 "$ASSERTION_LOG"
assert_false "nonzero + mixed should not retry" \
    xcodebuild_ci_should_retry 65 "$MIXED_LOG"

ATTEMPTS_FILE="$WORKDIR/attempts"
MOCK="$WORKDIR/mock-xcodebuild"
cat > "$MOCK" <<EOF
#!/usr/bin/env bash
set -euo pipefail
n=0
if [[ -f "$ATTEMPTS_FILE" ]]; then
    n=\$(cat "$ATTEMPTS_FILE")
fi
n=\$((n + 1))
echo "\$n" > "$ATTEMPTS_FILE"
if [[ "\$n" -eq 1 ]]; then
    cat "$BOOTSTRAP_LOG"
    exit 65
fi
echo "** TEST SUCCEEDED **"
exit 0
EOF
chmod +x "$MOCK"

set +e
xcodebuild_ci_run_with_bootstrap_retry "$WORKDIR/run.log" "$MOCK"
run_status=$?
set -e
assert_eq "$run_status" "0" "retry wrapper succeeds after one bootstrap failure"
assert_eq "$(cat "$ATTEMPTS_FILE")" "2" "retry wrapper invokes command twice on bootstrap failure"

echo 0 > "$ATTEMPTS_FILE"
FAIL_MOCK="$WORKDIR/mock-fail-assertion"
cat > "$FAIL_MOCK" <<EOF
#!/usr/bin/env bash
n=0
if [[ -f "$ATTEMPTS_FILE" ]]; then
    n=\$(cat "$ATTEMPTS_FILE")
fi
n=\$((n + 1))
echo "\$n" > "$ATTEMPTS_FILE"
cat "$ASSERTION_LOG"
exit 65
EOF
chmod +x "$FAIL_MOCK"

set +e
xcodebuild_ci_run_with_bootstrap_retry "$WORKDIR/assert-run.log" "$FAIL_MOCK"
assert_status=$?
set -e
assert_eq "$assert_status" "65" "retry wrapper does not retry assertion failures"
assert_eq "$(cat "$ATTEMPTS_FILE")" "1" "assertion failure invokes command once"

BUNDLE="$WORKDIR/SLF-iOS-Framework.xcresult"
mkdir -p "$BUNDLE"
echo stale > "$BUNDLE/Info.plist"
echo 0 > "$ATTEMPTS_FILE"
BUNDLE_MOCK="$WORKDIR/mock-bundle"
cat > "$BUNDLE_MOCK" <<EOF
#!/usr/bin/env bash
n=0
if [[ -f "$ATTEMPTS_FILE" ]]; then
    n=\$(cat "$ATTEMPTS_FILE")
fi
n=\$((n + 1))
echo "\$n" > "$ATTEMPTS_FILE"
if [[ "\$n" -eq 1 ]]; then
    cat "$BOOTSTRAP_LOG"
    exit 65
fi
if [[ -e "$BUNDLE" ]]; then
    echo "stale bundle still present"
    exit 2
fi
echo "** TEST SUCCEEDED **"
exit 0
EOF
chmod +x "$BUNDLE_MOCK"

set +e
xcodebuild_ci_run_with_bootstrap_retry "$WORKDIR/bundle-run.log" "$BUNDLE_MOCK" \
    -resultBundlePath "$BUNDLE"
bundle_status=$?
set -e
assert_eq "$bundle_status" "0" "retry wrapper removes result bundle before retry"
assert_false "stale xcresult removed before retry" test -e "$BUNDLE"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
