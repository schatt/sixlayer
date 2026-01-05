# Testing Commands for macOS and iOS

## Test Organization

The test suite is organized into:

1. **Unit Tests** (`SixLayerFrameworkUnitTests`):
   - **Pure unit tests**: Test business logic, data structures, algorithms without rendering
   - **ViewInspector tests** (`ViewInspectorTests/` subdirectory): Test view structure and modifiers using ViewInspector (view structure inspection, not actual UI rendering)
   - Both types are unit tests - they test different aspects of the same functionality

2. **Real UI Tests** (TODO - not yet implemented):
   - Will test actual rendered UI in windows using XCUITest
   - Will verify views actually render correctly, layout works, and accessibility features function in real windows

**Key Distinction**: ViewInspector tests are unit tests that verify view structure (like testing a knife's sharpness), while pure unit tests verify logic (like testing a knife's hardness). Both test the same "blade" from different angles.

## Running Tests on Both Platforms (Recommended)

### Using dbs-build (Simplified)
```bash
# Run all tests on both macOS and iOS Simulator
dbs-build --target test
```

This command runs tests on both platforms as defined in `buildconfig.yml`:
- macOS tests: `swift test`
- iOS Simulator tests: `xcodebuild test` with iOS Simulator destination

## Running Tests on Individual Platforms

### macOS Tests Only
```bash
# Using dbs-build
dbs-build --target macOS_tests

# Or directly with swift test
swift test

# Or with xcodebuild (for SwiftUI rendering tests)
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme SixLayerFramework \
  -destination "platform=macOS,arch=arm64"
```

### iOS Simulator Tests Only
```bash
# Using dbs-build
dbs-build --target iOS_tests

# Or directly with xcodebuild
# Boot simulator first (if not already running)
xcrun simctl boot "iPhone 17 Pro Max" 2>/dev/null || echo "Simulator already booted..."

# Run tests
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme SixLayerFramework \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max"
```

## Quick Reference Commands

### All Tests (Both Platforms)
```bash
# Recommended: Use dbs-build
dbs-build --target test
```

### macOS Tests Only
```bash
dbs-build --target macOS_tests
# OR
swift test
```

### iOS Simulator Tests Only
```bash
dbs-build --target iOS_tests
```

### List Available Targets
```bash
dbs-build --list-targets
```

## Alternative: Direct Commands (Without dbs-build)

### macOS Tests
```bash
swift test
```

### iOS Simulator Tests
```bash
# Boot simulator first
xcrun simctl boot "iPhone 17 Pro Max"

# Run tests
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme SixLayerFramework \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max"
```

## Important Notes

1. **Platform-Specific Code**: Tests with `#if os(iOS)` only compile when targeting iOS
2. **Platform-Specific Code**: Tests with `#if os(macOS)` only compile when targeting macOS
3. **Complete Coverage**: To test all code paths, you must run tests on both platforms
4. **SwiftUI Rendering**: Use `xcodebuild test` for SwiftUI rendering tests (not just `swift test`)
5. **Simulator Management**: Boot simulator before running iOS tests if not already running

## Finding Available Simulators

```bash
# List all available iOS simulators
xcrun simctl list devices available | grep -i "iphone\|ipad"

# List booted simulators
xcrun simctl list devices | grep "Booted"

# Get device ID for a specific simulator
xcrun simctl list devices | grep "iPhone 16 Pro"
```

