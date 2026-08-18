#!/usr/bin/env bash
# Ensure a secondary-platform simulator exists and print an xcodebuild destination.
#
# Usage:
#   ensure-ci-simulator-destination.sh <tvOS|watchOS|visionOS|iOS> [name] [device_type]
#
# Prints one line: platform=… Simulator,id=…
# Do not include name= — xcodebuild infers OS:latest from name, which misses
# non-latest runtimes (#429). UDID is unique.
# Suitable for: xcodebuild test -destination "$(…/ensure-ci-simulator-destination.sh tvOS)"
#
# Refs #399

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ensure_ci_simulator_destination.sh
source "${SCRIPT_DIR}/lib/ensure_ci_simulator_destination.sh"

if [[ "${1:-}" == "" ]]; then
    echo "Usage: $0 <tvOS|watchOS|visionOS|iOS> [name] [device_type]" >&2
    exit 2
fi

ensure_ci_sim_resolve_destination "$@"
