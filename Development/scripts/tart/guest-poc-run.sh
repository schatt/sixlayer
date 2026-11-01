#!/usr/bin/env bash
# SixLayer Tart XCUITest PoC — runs INSIDE the Tart guest (#583).
# Launch from guest Terminal:
#   bash "/Volumes/My Shared Files/sixlayer/Development/scripts/tart/guest-poc-run.sh"
# Copies the shared worktree to guest-local disk, runs one macOS UI test and
# one iOS Simulator UI test, streams logs back through the shared folder.
set -u

SHARE="/Volumes/My Shared Files/sixlayer"
OUT="$SHARE/tart-poc-out"
WORK="$HOME/sixlayer-583"
DD="$HOME/DD-583"

mkdir -p "$OUT"
LOG="$OUT/guest-poc.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== guest-poc start $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "--- guest ---"
sw_vers
whoami; hostname
xcodebuild -version
echo "--- simulator runtimes ---"
xcrun simctl list runtimes
echo "--- simulator devices (available) ---"
xcrun simctl list devices available | head -40

echo "--- sync worktree share -> $WORK ---"
mkdir -p "$WORK"
rsync -a --delete \
  --exclude 'tart-poc-out' \
  --exclude 'DerivedData' \
  "$SHARE/" "$WORK/"
cd "$WORK" || exit 1
git log -1 --oneline 2>/dev/null || true

echo "--- resolve packages ---"
xcodebuild -resolvePackageDependencies -project SixLayerFramework.xcodeproj

echo "=== macOS UITest: app gate + SD150 toggle ==="
date -u +%Y-%m-%dT%H:%M:%SZ
xcodebuild test -project SixLayerFramework.xcodeproj \
  -scheme SLF-macOS-UITests \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath "$DD" \
  -parallel-testing-enabled YES \
  -only-testing:'SixLayerFrameworkUITests_macOS/SixLayerUITestAppGateTests' \
  -only-testing:'SixLayerFrameworkUITests_macOS/PlatformStandaloneDropIn150UITests/test150_platformToggle_tapUpdatesBinding' \
  2>&1 | tee "$OUT/macos-test.log" | tail -n 40

echo "=== iOS UITest: SD150 text field ==="
date -u +%Y-%m-%dT%H:%M:%SZ
xcodebuild test -project SixLayerFramework.xcodeproj \
  -scheme SLF-iOS-UITests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath "$DD" \
  -parallel-testing-enabled YES \
  -only-testing:'SixLayerFrameworkUITests_iOS/PlatformStandaloneDropIn150UITests/test150_platformTextField_typingUpdatesBinding' \
  2>&1 | tee "$OUT/ios-test.log" | tail -n 40

echo "=== guest-poc done $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
date -u +%Y-%m-%dT%H:%M:%SZ > "$OUT/DONE"
