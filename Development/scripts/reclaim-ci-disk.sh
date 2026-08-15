#!/usr/bin/env bash
# Reclaim self-hosted CI scratch: derived data, SPM checkouts, xcresults,
# and simctl devices named "Clone N of …" (#416).
#
# Usage:
#   ./Development/scripts/reclaim-ci-disk.sh [--workspace DIR] [--skip-simulators]
#
# Defaults: --workspace is $GITHUB_WORKSPACE or cwd.
# Does not run `simctl delete unavailable` (#413).
#
# If Mini will not boot or checkout fails (disk 100% full), run this on the
# runner host from any checkout that still has the script, or delete:
#   $GITHUB_WORKSPACE/.ci-derived-data
#   $GITHUB_WORKSPACE/.ci-spm
#   $GITHUB_WORKSPACE/build/*.xcresult
# and `xcrun simctl delete` each "Clone N of …" device.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/reclaim_ci_disk.sh
source "${SCRIPT_DIR}/lib/reclaim_ci_disk.sh"

WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
SKIP_SIMULATORS=0

usage() {
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace)
            WORKSPACE="${2:-}"
            if [[ -z "$WORKSPACE" ]]; then
                echo "reclaim-ci-disk.sh: --workspace requires a directory" >&2
                exit 2
            fi
            shift 2
            ;;
        --skip-simulators)
            SKIP_SIMULATORS=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "reclaim-ci-disk.sh: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

echo "Reclaiming CI disk under: $WORKSPACE"
reclaim_ci_disk_log_df
reclaim_ci_disk_clean_workspace "$WORKSPACE"

if [[ "$SKIP_SIMULATORS" -eq 0 ]] && command -v xcrun >/dev/null 2>&1; then
    devices_json="$(xcrun simctl list devices -j 2>/dev/null || true)"
    if [[ -n "$devices_json" ]]; then
        while IFS= read -r udid; do
            [[ -z "$udid" ]] && continue
            echo "Deleting simulator clone $udid"
            xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
            xcrun simctl delete "$udid" >/dev/null 2>&1 || true
        done < <(reclaim_ci_disk_clone_udids_from_devices_json "$devices_json")
    fi
fi

reclaim_ci_disk_log_df
