#!/usr/bin/env bash
# Helpers for retrying xcodebuild test on xctest bootstrap-only failures (#432).
# Source from xcodebuild-ci-retry.sh or tests.
#
# Retry only when the runner dies during bootstrap (no assertion `failed on`
# lines). Do not disable parallel testing.

xcodebuild_ci_log_is_runner_bootstrap_failure() {
    local log_file="${1:-}"
    [[ -n "$log_file" && -f "$log_file" ]] || return 1
    if grep -Eq 'failed on ' "$log_file"; then
        return 1
    fi
    if grep -Eq '(^|[[:space:]])error: ' "$log_file"; then
        return 1
    fi
    grep -Eq 'never finished bootstrapping|exited with code [0-9]+ before establishing connection|Early unexpected exit' "$log_file"
}

xcodebuild_ci_should_retry() {
    local exit_code="${1:-0}"
    local log_file="${2:-}"
    [[ "$exit_code" -ne 0 ]] || return 1
    xcodebuild_ci_log_is_runner_bootstrap_failure "$log_file"
}

xcodebuild_ci_result_bundle_path() {
    local prev="" arg
    for arg in "$@"; do
        if [[ "$prev" == "-resultBundlePath" ]]; then
            printf '%s\n' "$arg"
            return 0
        fi
        prev="$arg"
    done
    return 1
}

xcodebuild_ci_run_with_bootstrap_retry() {
    local log_file="${1:?log file required}"
    shift
    local bundle=""
    bundle="$(xcodebuild_ci_result_bundle_path "$@" || true)"

    local status=0
    local had_errexit=0
    [[ $- == *e* ]] && had_errexit=1
    set +e
    "$@" 2>&1 | tee "$log_file"
    status="${PIPESTATUS[0]}"

    if [[ "$status" -eq 0 ]]; then
        [[ "$had_errexit" -eq 1 ]] && set -e
        return 0
    fi
    if ! xcodebuild_ci_should_retry "$status" "$log_file"; then
        [[ "$had_errexit" -eq 1 ]] && set -e
        return "$status"
    fi

    echo "xcodebuild CI: retrying once after xctest bootstrap failure (#432)" >&2
    if [[ -n "$bundle" && -e "$bundle" ]]; then
        rm -rf "$bundle"
    fi

    "$@" 2>&1 | tee "$log_file"
    status="${PIPESTATUS[0]}"
    [[ "$had_errexit" -eq 1 ]] && set -e
    return "$status"
}
