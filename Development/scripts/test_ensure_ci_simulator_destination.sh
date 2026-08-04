#!/usr/bin/env bash
# Unit tests for ensure-ci-simulator-destination (#399).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/ensure_ci_simulator_destination.sh"
PASS=0
FAIL=0

assert_eq() {
    local got="$1" want="$2" label="$3"
    if [ "$got" = "$want" ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   got:  $got"
        echo "   want: $want"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   expected to contain: $needle"
        echo "   haystack: $haystack"
        FAIL=$((FAIL + 1))
    fi
}

assert_true() {
    local label="$1"
    shift
    if "$@"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    fi
}

if [[ ! -f "$LIB" ]]; then
    echo "❌ missing lib: $LIB"
    exit 1
fi

# shellcheck source=lib/ensure_ci_simulator_destination.sh
source "$LIB"

FIXTURE_RUNTIMES='{
  "runtimes": [
    {
      "name": "tvOS 26.5",
      "identifier": "com.apple.CoreSimulator.SimRuntime.tvOS-26-5",
      "isAvailable": true,
      "version": "26.5",
      "supportedDeviceTypes": [
        {"identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p"},
        {"identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p"}
      ]
    },
    {
      "name": "tvOS 27.0",
      "identifier": "com.apple.CoreSimulator.SimRuntime.tvOS-27-0",
      "isAvailable": true,
      "version": "27.0",
      "supportedDeviceTypes": [
        {"identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p"}
      ]
    },
    {
      "name": "iOS 27.0",
      "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
      "isAvailable": true,
      "version": "27.0",
      "supportedDeviceTypes": []
    },
    {
      "name": "watchOS 27.0",
      "identifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-0",
      "isAvailable": false,
      "version": "27.0",
      "supportedDeviceTypes": []
    }
  ]
}'

got="$(ensure_ci_sim_pick_runtime_identifier "$FIXTURE_RUNTIMES" "tvOS")"
assert_eq "$got" "com.apple.CoreSimulator.SimRuntime.tvOS-27-0" "pick newest available tvOS runtime"

got="$(ensure_ci_sim_pick_runtime_identifier "$FIXTURE_RUNTIMES" "watchOS")"
assert_eq "$got" "" "unavailable watchOS runtime yields empty"

got="$(ensure_ci_sim_pick_create_pair "$FIXTURE_RUNTIMES" "tvOS" "com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p")"
assert_eq "$got" $'com.apple.CoreSimulator.SimRuntime.tvOS-26-5\tcom.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p' \
  "create pair prefers compatible older runtime for classic Apple TV"

got="$(ensure_ci_sim_pick_create_pair "$FIXTURE_RUNTIMES" "tvOS" "com.apple.CoreSimulator.SimDeviceType.Missing-Type")"
assert_eq "$got" $'com.apple.CoreSimulator.SimRuntime.tvOS-27-0\tcom.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p' \
  "create pair falls back to newest runtime first supported type"

FIXTURE_DEVICES='{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.tvOS-27-0": [
      {
        "udid": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
        "name": "Apple TV",
        "isAvailable": true,
        "state": "Shutdown"
      },
      {
        "udid": "11111111-2222-3333-4444-555555555555",
        "name": "Apple TV 4K (3rd generation)",
        "isAvailable": true,
        "state": "Shutdown"
      }
    ],
    "com.apple.CoreSimulator.SimRuntime.tvOS-26-5": [
      {
        "udid": "99999999-8888-7777-6666-555555555555",
        "name": "Apple TV",
        "isAvailable": false,
        "state": "Shutdown"
      }
    ]
  }
}'

got="$(ensure_ci_sim_udid_for_name "$FIXTURE_DEVICES" "Apple TV")"
assert_eq "$got" "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" "prefer available UDID for exact name"

got="$(ensure_ci_sim_any_device_for_family "$FIXTURE_DEVICES" "tvOS")"
assert_eq "$got" $'Apple TV\tAAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' \
  "family fallback returns first available tvOS device"

FIXTURE_DEVICES_NO_PREFERRED='{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.tvOS-27-0": [
      {
        "udid": "11111111-2222-3333-4444-555555555555",
        "name": "Apple TV 4K (3rd generation)",
        "isAvailable": true,
        "state": "Shutdown"
      }
    ]
  }
}'

got="$(ensure_ci_sim_udid_for_name "$FIXTURE_DEVICES_NO_PREFERRED" "Apple TV")"
assert_eq "$got" "" "missing preferred name yields empty"

got="$(ensure_ci_sim_any_device_for_family "$FIXTURE_DEVICES_NO_PREFERRED" "tvOS")"
assert_eq "$got" $'Apple TV 4K (3rd generation)\t11111111-2222-3333-4444-555555555555' \
  "family fallback finds 4K when classic Apple TV absent"

got="$(ensure_ci_sim_destination_specifier "tvOS" "Apple TV" "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")"
assert_eq "$got" "platform=tvOS Simulator,name=Apple TV,id=AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" \
  "destination includes platform, name, and id"

got="$(ensure_ci_sim_destination_specifier "visionOS" "Apple Vision Pro" "ABCD")"
assert_contains "$got" "platform=visionOS Simulator" "visionOS platform string"

got="$(ensure_ci_sim_xcode_platform_label "watchOS")"
assert_eq "$got" "watchOS Simulator" "watchOS xcode platform label"

assert_true "device type map has Apple TV" \
  test -n "$(ensure_ci_sim_default_device_type "tvOS")"
assert_true "device type map has Apple Watch Series 11 (46mm)" \
  test -n "$(ensure_ci_sim_default_device_type "watchOS")"
assert_true "device type map has Apple Vision Pro" \
  test -n "$(ensure_ci_sim_default_device_type "visionOS")"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
