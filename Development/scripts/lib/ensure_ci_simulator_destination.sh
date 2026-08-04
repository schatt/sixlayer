#!/usr/bin/env bash
# Library helpers for ensuring CI simulator destinations (#399).
# Source from ensure-ci-simulator-destination.sh or tests.

ensure_ci_sim_xcode_platform_label() {
    local platform_family="$1"
    case "$platform_family" in
        tvOS) printf '%s\n' "tvOS Simulator" ;;
        watchOS) printf '%s\n' "watchOS Simulator" ;;
        visionOS) printf '%s\n' "visionOS Simulator" ;;
        iOS) printf '%s\n' "iOS Simulator" ;;
        *) printf '%s\n' "${platform_family} Simulator" ;;
    esac
}

ensure_ci_sim_default_device_type() {
    local platform_family="$1"
    case "$platform_family" in
        tvOS) printf '%s\n' "com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p" ;;
        watchOS) printf '%s\n' "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-46mm" ;;
        visionOS) printf '%s\n' "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro" ;;
        iOS) printf '%s\n' "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" ;;
        *) printf '%s\n' "" ;;
    esac
}

ensure_ci_sim_default_name() {
    local platform_family="$1"
    case "$platform_family" in
        tvOS) printf '%s\n' "Apple TV" ;;
        watchOS) printf '%s\n' "Apple Watch Series 11 (46mm)" ;;
        visionOS) printf '%s\n' "Apple Vision Pro" ;;
        iOS) printf '%s\n' "iPhone 17 Pro Max" ;;
        *) printf '%s\n' "" ;;
    esac
}

# Newest available runtime whose name contains the platform family token.
# Args: runtimes JSON string, platform family (tvOS|watchOS|visionOS|iOS)
ensure_ci_sim_pick_runtime_identifier() {
    local runtimes_json="$1"
    local platform_family="$2"
    ENSURE_CI_SIM_RUNTIMES_JSON="$runtimes_json" ENSURE_CI_SIM_PLATFORM_FAMILY="$platform_family" python3 - <<'PY'
import json, os, re, sys

raw = os.environ.get("ENSURE_CI_SIM_RUNTIMES_JSON", "")
family = os.environ.get("ENSURE_CI_SIM_PLATFORM_FAMILY", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

def version_key(v: str):
    parts = []
    for piece in re.split(r"[^\d]+", v or ""):
        if piece.isdigit():
            parts.append(int(piece))
    return parts

matches = []
for rt in data.get("runtimes", []):
    if not rt.get("isAvailable"):
        continue
    name = rt.get("name") or ""
    # visionOS runtimes may still use xrOS in identifier; name uses visionOS.
    if family == "visionOS":
        token_ok = ("visionOS" in name) or ("xrOS" in name) or ("xros" in (rt.get("identifier") or "").lower())
    else:
        token_ok = family in name
    if not token_ok:
        continue
    matches.append(rt)

if not matches:
    sys.exit(0)

matches.sort(key=lambda rt: version_key(str(rt.get("version") or "")), reverse=True)
print(matches[0].get("identifier") or "")
PY
}

# First available device UDID with exact name across all runtimes.
# Args: devices JSON string (simctl list devices -j), device name
ensure_ci_sim_udid_for_name() {
    local devices_json="$1"
    local device_name="$2"
    ENSURE_CI_SIM_DEVICES_JSON="$devices_json" ENSURE_CI_SIM_DEVICE_NAME="$device_name" python3 - <<'PY'
import json, os, sys

raw = os.environ.get("ENSURE_CI_SIM_DEVICES_JSON", "")
want = os.environ.get("ENSURE_CI_SIM_DEVICE_NAME", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

for _runtime, devices in (data.get("devices") or {}).items():
    for device in devices or []:
        if device.get("name") != want:
            continue
        if device.get("isAvailable") is False:
            continue
        udid = device.get("udid") or ""
        if udid:
            print(udid)
            sys.exit(0)
PY
}

ensure_ci_sim_destination_specifier() {
    local platform_family="$1"
    local name="$2"
    local udid="$3"
    local label
    label="$(ensure_ci_sim_xcode_platform_label "$platform_family")"
    printf '%s\n' "platform=${label},name=${name},id=${udid}"
}

# Stub — wrong until green (Refs #399 deliberate red for create-pair / family fallback).
ensure_ci_sim_pick_create_pair() {
    printf '%s\n' ""
}

ensure_ci_sim_any_device_for_family() {
    printf '%s\n' ""
}

# Ensure a named simulator exists; print destination specifier on stdout.
# Args: platform_family [name] [device_type]
ensure_ci_sim_resolve_destination() {
    local platform_family="$1"
    local name="${2:-}"
    local device_type="${3:-}"

    if [[ -z "$name" ]]; then
        name="$(ensure_ci_sim_default_name "$platform_family")"
    fi
    if [[ -z "$device_type" ]]; then
        device_type="$(ensure_ci_sim_default_device_type "$platform_family")"
    fi
    if [[ -z "$name" || -z "$device_type" ]]; then
        echo "ensure_ci_sim_resolve_destination: unsupported platform family: ${platform_family}" >&2
        return 1
    fi

    # Wake CoreSimulator; prune unavailable entries (best-effort).
    xcrun simctl list devices >/dev/null 2>&1 || true
    xcrun simctl delete unavailable >/dev/null 2>&1 || true

    local devices_json udid
    local attempt
    for attempt in 1 2 3 4 5; do
        devices_json="$(xcrun simctl list devices -j 2>/dev/null || true)"
        udid="$(ensure_ci_sim_udid_for_name "$devices_json" "$name")"
        if [[ -n "$udid" ]]; then
            ensure_ci_sim_destination_specifier "$platform_family" "$name" "$udid"
            return 0
        fi

        local runtimes_json runtime
        runtimes_json="$(xcrun simctl list runtimes available -j 2>/dev/null || true)"
        runtime="$(ensure_ci_sim_pick_runtime_identifier "$runtimes_json" "$platform_family")"
        if [[ -z "$runtime" ]]; then
            echo "ensure_ci_sim_resolve_destination: no available ${platform_family} runtime (attempt ${attempt})" >&2
            sleep 2
            continue
        fi

        echo "ensure_ci_sim_resolve_destination: creating ${name} (${device_type}, ${runtime})" >&2
        if ! xcrun simctl create "$name" "$device_type" "$runtime" >/dev/null 2>&1; then
            echo "ensure_ci_sim_resolve_destination: simctl create failed (attempt ${attempt})" >&2
            sleep 2
            continue
        fi

        devices_json="$(xcrun simctl list devices -j 2>/dev/null || true)"
        udid="$(ensure_ci_sim_udid_for_name "$devices_json" "$name")"
        if [[ -n "$udid" ]]; then
            ensure_ci_sim_destination_specifier "$platform_family" "$name" "$udid"
            return 0
        fi
        sleep 2
    done

    echo "ensure_ci_sim_resolve_destination: failed to resolve ${platform_family} simulator named '${name}'" >&2
    return 1
}
