#!/usr/bin/env bash
# Unit tests for reclaim-ci-disk (#416).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/reclaim_ci_disk.sh"
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

assert_false() {
    local label="$1"
    shift
    if "$@"; then
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
    fi
}

if [[ ! -f "$LIB" ]]; then
    echo "❌ missing lib: $LIB"
    exit 1
fi

# shellcheck source=lib/reclaim_ci_disk.sh
source "$LIB"

assert_true "Clone 1 of iPhone 17 Pro Max is a clone name" \
    reclaim_ci_disk_is_clone_device_name "Clone 1 of iPhone 17 Pro Max"
assert_true "Clone 2 of Apple TV is a clone name" \
    reclaim_ci_disk_is_clone_device_name "Clone 2 of Apple TV"
assert_false "base iPhone 17 Pro Max is not a clone name" \
    reclaim_ci_disk_is_clone_device_name "iPhone 17 Pro Max"
assert_false "Clone without index is not a clone name" \
    reclaim_ci_disk_is_clone_device_name "Clone of iPhone 17 Pro Max"
assert_false "empty name is not a clone name" \
    reclaim_ci_disk_is_clone_device_name ""

FIXTURE_DEVICES='{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
      {"udid": "BASE-IPHONE", "name": "iPhone 17 Pro Max", "state": "Shutdown"},
      {"udid": "CLONE-1", "name": "Clone 1 of iPhone 17 Pro Max", "state": "Booted"},
      {"udid": "CLONE-2", "name": "Clone 2 of iPhone 17 Pro Max", "state": "Shutdown"}
    ],
    "com.apple.CoreSimulator.SimRuntime.tvOS-26-0": [
      {"udid": "BASE-TV", "name": "Apple TV", "state": "Shutdown"},
      {"udid": "CLONE-TV", "name": "Clone 1 of Apple TV", "state": "Shutdown"}
    ]
  }
}'

got="$(reclaim_ci_disk_clone_udids_from_devices_json "$FIXTURE_DEVICES" | LC_ALL=C sort | tr '\n' ' ')"
assert_eq "$got" "CLONE-1 CLONE-2 CLONE-TV " "clone UDID list excludes base simulators"

got="$(reclaim_ci_disk_simctl_delete_commands_from_udids $'CLONE-1\nCLONE-2')"
assert_eq "$got" $'xcrun simctl delete CLONE-1\nxcrun simctl delete CLONE-2' \
    "delete commands are per-UDID simctl delete (not delete unavailable)"

assert_false "planned commands do not prune unavailable" \
    bash -c 'printf "%s" "$1" | grep -Fq "delete unavailable"' _ "$got"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/reclaim-ci-disk-test.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

mkdir -p \
    "$WORKDIR/.ci-derived-data/SLF-iOS-UnitTests/Build" \
    "$WORKDIR/.ci-spm/SLF-iOS-UnitTests/checkouts" \
    "$WORKDIR/build/keep-me" \
    "$WORKDIR/Sources"
echo derived > "$WORKDIR/.ci-derived-data/SLF-iOS-UnitTests/Build/junk"
echo spm > "$WORKDIR/.ci-spm/SLF-iOS-UnitTests/checkouts/pkg"
mkdir -p "$WORKDIR/build/SLF-iOS-UnitTests.xcresult"
echo result > "$WORKDIR/build/SLF-iOS-UnitTests.xcresult/Info.plist"
echo keep > "$WORKDIR/build/keep-me/note.txt"
echo src > "$WORKDIR/Sources/File.swift"

reclaim_ci_disk_clean_workspace "$WORKDIR"

assert_false "removes .ci-derived-data" test -e "$WORKDIR/.ci-derived-data"
assert_false "removes .ci-spm" test -e "$WORKDIR/.ci-spm"
assert_false "removes build/*.xcresult" test -e "$WORKDIR/build/SLF-iOS-UnitTests.xcresult"
assert_true "preserves other build files" test -f "$WORKDIR/build/keep-me/note.txt"
assert_true "preserves Sources" test -f "$WORKDIR/Sources/File.swift"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
