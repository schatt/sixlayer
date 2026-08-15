#!/usr/bin/env bash
# Library helpers for reclaiming self-hosted CI disk (#416).
# Source from reclaim-ci-disk.sh or tests.
#
# Does not call `simctl delete unavailable` (see #413).

reclaim_ci_disk_is_clone_device_name() {
    local name="${1:-}"
    [[ "$name" =~ ^Clone[[:space:]]+[0-9]+[[:space:]]+of[[:space:]].+ ]]
}

# Print name<TAB>udid for every device in `simctl list devices -j` JSON.
reclaim_ci_disk_device_name_udids_from_json() {
    local devices_json="$1"
    RECLAIM_CI_DISK_DEVICES_JSON="$devices_json" python3 - <<'PY'
import json, os, sys

raw = os.environ.get("RECLAIM_CI_DISK_DEVICES_JSON", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

devices = data.get("devices") or {}
if not isinstance(devices, dict):
    sys.exit(0)

for entries in devices.values():
    if not isinstance(entries, list):
        continue
    for device in entries:
        if not isinstance(device, dict):
            continue
        name = (device.get("name") or "").replace("\t", " ").replace("\n", " ")
        udid = device.get("udid") or ""
        if udid:
            print(f"{name}\t{udid}")
PY
}

# Print one UDID per line for devices named "Clone N of …".
reclaim_ci_disk_clone_udids_from_devices_json() {
    local devices_json="$1"
    local name udid
    while IFS=$'\t' read -r name udid; do
        [[ -z "$udid" ]] && continue
        if reclaim_ci_disk_is_clone_device_name "$name"; then
            printf '%s\n' "$udid"
        fi
    done < <(reclaim_ci_disk_device_name_udids_from_json "$devices_json")
}

# Print one `xcrun simctl delete <udid>` per UDID. Never emits `delete unavailable`.
reclaim_ci_disk_simctl_delete_commands_from_udids() {
    local udids="${1:-}"
    local udid
    while IFS= read -r udid; do
        [[ -z "$udid" ]] && continue
        printf 'xcrun simctl delete %s\n' "$udid"
    done <<< "$udids"
}

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
