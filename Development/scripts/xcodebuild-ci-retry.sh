#!/usr/bin/env bash
# Run xcodebuild test, retrying once on xctest bootstrap-only failures (#432)
# or a silent hang (#433, default 180s with no new tee-log bytes).
#
# Usage:
#   xcodebuild-ci-retry.sh xcodebuild test [args...]
#
# Log: $XCODEBUILD_CI_RETRY_LOG or $RUNNER_TEMP/xcodebuild-ci-retry.log
# Stall: $XCODEBUILD_CI_STALL_SECONDS (default 180; 0 disables)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/xcodebuild_ci_retry.sh
source "${SCRIPT_DIR}/lib/xcodebuild_ci_retry.sh"

if [[ "${1:-}" == "" ]]; then
    echo "Usage: $0 <command> [args...]" >&2
    exit 2
fi

LOG="${XCODEBUILD_CI_RETRY_LOG:-${RUNNER_TEMP:-/tmp}/xcodebuild-ci-retry.log}"
mkdir -p "$(dirname "$LOG")"
xcodebuild_ci_run_with_bootstrap_retry "$LOG" "$@"
