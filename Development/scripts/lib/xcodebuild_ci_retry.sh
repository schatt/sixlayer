#!/usr/bin/env bash
# Helpers for retrying xcodebuild test on xctest bootstrap-only failures (#432)
# and silent hangs (#433). Source from xcodebuild-ci-retry.sh or tests.
#
# Retry only when the runner dies during bootstrap, or when the process is
# killed after a stretch of no output (exit 124). Never retry assertion
# `failed on` lines. Do not disable parallel testing.
#
# Stall seconds: $XCODEBUILD_CI_STALL_SECONDS (default 180). 0 disables.
# The stall watchdog watches the tee log's mtime/size; it does not read
# xcodebuild stdout (#434).

_XCODEBUILD_CI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    if [[ "$exit_code" -eq 124 ]]; then
        [[ -n "$log_file" && -f "$log_file" ]] || return 0
        if grep -Eq 'failed on ' "$log_file"; then
            return 1
        fi
        if grep -Eq '(^|[[:space:]])error: ' "$log_file"; then
            return 1
        fi
        return 0
    fi
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

_xcodebuild_ci_restore_errexit() {
    [[ "${1:-0}" -eq 1 ]] && set -e
    return 0
}

xcodebuild_ci_invoke_logged() {
    local log_file="${1:?log file required}"
    shift
    local stall="${XCODEBUILD_CI_STALL_SECONDS:-180}"
    local stall_py="${_XCODEBUILD_CI_LIB_DIR}/xcodebuild_ci_stall_run.py"
    if [[ "$stall" =~ ^[1-9][0-9]*$ ]] \
        && [[ -f "$stall_py" ]] \
        && command -v python3 >/dev/null; then
        python3 "$stall_py" "$stall" "$log_file" "$@" 2>&1 | tee "$log_file"
        return "${PIPESTATUS[0]}"
    fi
    "$@" 2>&1 | tee "$log_file"
    return "${PIPESTATUS[0]}"
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
    xcodebuild_ci_invoke_logged "$log_file" "$@"
    status=$?

    if [[ "$status" -eq 0 ]]; then
        _xcodebuild_ci_restore_errexit "$had_errexit"
        return 0
    fi
    if ! xcodebuild_ci_should_retry "$status" "$log_file"; then
        _xcodebuild_ci_restore_errexit "$had_errexit"
        return "$status"
    fi

    if [[ "$status" -eq 124 ]]; then
        echo "xcodebuild CI: retrying once after output stall (#433)" >&2
    else
        echo "xcodebuild CI: retrying once after xctest bootstrap failure (#432)" >&2
    fi
    if [[ -n "$bundle" && -e "$bundle" ]]; then
        rm -rf "$bundle"
    fi

    xcodebuild_ci_invoke_logged "$log_file" "$@"
    status=$?
    _xcodebuild_ci_restore_errexit "$had_errexit"
    return "$status"
}
