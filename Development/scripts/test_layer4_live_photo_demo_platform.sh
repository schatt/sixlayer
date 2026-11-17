#!/usr/bin/env bash
# Assert TestApp Live Photo camera demo is iOS-only (#696).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/../Tests/SixLayerFrameworkUITests/TestApp/Layer4Examples/Layer4ExamplesView.swift"
PASS=0
FAIL=0

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   expected to contain: $needle"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        echo "❌ $label"
        echo "   must not contain: $needle"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
    fi
}

echo "=== test_layer4_live_photo_demo_platform (#696) ==="

if [ ! -f "$SRC" ]; then
    echo "❌ missing: $SRC"
    exit 1
fi

BODY="$(cat "$SRC")"

# Extract CameraInterfaceExample body (through the next top-level struct).
CAMERA_BLOCK="$(
    awk '
      /^struct CameraInterfaceExample/ {capture=1}
      capture {print}
      capture && /^struct / && !/^struct CameraInterfaceExample/ {exit}
    ' "$SRC"
)"

assert_contains "$CAMERA_BLOCK" "fullScreenCover(isPresented: \$showCamera)" \
    "iOS Live Photo demo uses fullScreenCover"
assert_contains "$CAMERA_BLOCK" "Open Live Photo Camera" \
    "iOS keeps Live Photo camera button"
assert_not_contains "$CAMERA_BLOCK" "sheet keeps the Live Photo camera demo runnable" \
    "macOS sheet shim comment is gone"
assert_not_contains "$CAMERA_BLOCK" ".sheet(isPresented: \$showCamera)" \
    "Live Photo camera demo does not present via sheet"
assert_contains "$CAMERA_BLOCK" "Live Photo capture is iOS-only" \
    "macOS path states Live Photo capture is iOS-only"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
