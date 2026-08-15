#!/usr/bin/env bash
# Library helpers for reclaiming self-hosted CI disk (#416).
# Source from reclaim-ci-disk.sh or tests.
#
# Does not call `simctl delete unavailable` (see #413).

reclaim_ci_disk_is_clone_device_name() {
    local name="${1:-}"
    [[ "$name" =~ ^Clone[[:space:]]+[0-9]+[[:space:]]+of[[:space:]].+ ]]
}

# Print one UDID per line for devices named "Clone N of …".
reclaim_ci_disk_clone_udids_from_devices_json() {
    local devices_json="$1"
    RECLAIM_CI_DISK_DEVICES_JSON="$devices_json" python3 - <<'PY'
import json, os, re, sys

raw = os.environ.get("RECLAIM_CI_DISK_DEVICES_JSON", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

clone_re = re.compile(r"^Clone\s+[0-9]+\s+of\s+.+$")
devices = data.get("devices") or {}
if not isinstance(devices, dict):
    sys.exit(0)

for entries in devices.values():
    if not isinstance(entries, list):
        continue
    for device in entries:
        if not isinstance(device, dict):
            continue
        name = device.get("name") or ""
        udid = device.get("udid") or ""
        if udid and clone_re.match(name):
            print(udid)
PY
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
