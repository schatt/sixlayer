#!/usr/bin/env bash
# Library helpers for reclaiming self-hosted CI disk (#416, #417).
# Source from reclaim-ci-disk.sh or tests.
#
# Workspace scratch only. Does not call simctl (Mini is shared with CarManager).

reclaim_ci_disk_clean_workspace() {
    local root="${1:-}"
    if [[ -z "$root" || ! -d "$root" ]]; then
        echo "reclaim_ci_disk_clean_workspace: missing directory: ${root:-<empty>}" >&2
        return 2
    fi
    rm -rf "${root}/.ci-derived-data" "${root}/.ci-spm"
    shopt -s nullglob
    local bundle
    for bundle in "${root}/build"/*.xcresult; do
        rm -rf "$bundle"
    done
    shopt -u nullglob
}

reclaim_ci_disk_log_df() {
    echo "---- df ----"
    df -h /System/Volumes/Data / 2>/dev/null || df -h /
}
