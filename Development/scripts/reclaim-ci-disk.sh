#!/usr/bin/env bash
# Reclaim self-hosted CI scratch: derived data, SPM checkouts, xcresults (#416).
# Does not modify simctl devices (#417) — Mini is shared with CarManager.
#
# Usage:
#   ./Development/scripts/reclaim-ci-disk.sh [--workspace DIR]
#
# Defaults: --workspace is $GITHUB_WORKSPACE or cwd.
#
# If Mini will not boot or checkout fails (disk 100% full), run this on the
# runner host from any checkout that still has the script, or delete:
#   $GITHUB_WORKSPACE/.ci-derived-data
#   $GITHUB_WORKSPACE/.ci-spm
#   $GITHUB_WORKSPACE/build/*.xcresult

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/reclaim_ci_disk.sh
source "${SCRIPT_DIR}/lib/reclaim_ci_disk.sh"

WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"

usage() {
    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
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
reclaim_ci_disk_log_df
