#!/usr/bin/env bash
# Helpers for retrying xcodebuild test on xctest bootstrap-only failures (#432).
# Source from xcodebuild-ci-retry.sh or tests. Stub: no retry yet.

xcodebuild_ci_log_is_runner_bootstrap_failure() {
    local log_file="${1:-}"
    [[ -n "$log_file" && -f "$log_file" ]] || return 1
    return 1
}

xcodebuild_ci_should_retry() {
    local exit_code="${1:-0}"
    local log_file="${2:-}"
    [[ "$exit_code" -ne 0 ]] || return 1
    xcodebuild_ci_log_is_runner_bootstrap_failure "$log_file"
}

xcodebuild_ci_run_with_bootstrap_retry() {
    local log_file="${1:?log file required}"
    shift
    "$@" 2>&1 | tee "$log_file"
    return "${PIPESTATUS[0]}"
}
