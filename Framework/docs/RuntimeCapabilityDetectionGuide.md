# Runtime Capability Detection Guide

## Overview

The SixLayer Framework now uses **runtime capability detection** instead of hardcoded platform assumptions. This means the framework queries the OS for actual hardware/software capabilities rather than making assumptions based on the platform.

## Key Benefits

- **Accurate Detection**: Detects actual hardware capabilities, not just platform assumptions
- **External Hardware Support**: Works with third-party touchscreens, haptic devices, etc.
- **Testing Predictability**: Uses hardcoded defaults in testing mode for consistent test behavior
- **Override Capability**: Allows manual override for special configurations

## Usage Examples

### Basic Usage

```swift
import SixLayerFramework

// Check if touch is supported (runtime detection)
if RuntimeCapabilityDetection.supportsTouch {
    // Enable touch-specific features
    enableTouchGestures()
}

// Check if haptic feedback is supported
if RuntimeCapabilityDetection.supportsHapticFeedback {
    // Enable haptic feedback
    enableHapticFeedback()
}

// Check if hover is supported
if RuntimeCapabilityDetection.supportsHover {
    // Enable hover effects
    enableHoverEffects()
}
```

### Enabling Touch on macOS with External Touchscreen

If you have an external touchscreen connected to your Mac with third-party drivers (like UPDD), you can enable touch support:

```swift
// Method 1: Enable via UserDefaults (persistent, process-wide)
UserDefaults.standard.set(true, forKey: "SixLayerFramework.TouchEnabled")

// Method 2: Use the override system (runtime only; thread-scoped — see GitHub #236)
CapabilityOverride.touchSupport = true

// Method 3: Check if touch is now supported
if RuntimeCapabilityDetection.supportsTouchWithOverride {
    print("Touch is now enabled!")
    // Your app will now use touch-specific features
}
```

### Thread / test isolation (GitHub #236)

- **`RuntimeCapabilityHarness`**: On macOS, `SixLayerFramework.TouchEnabled` and `SixLayerFramework.HapticEnabled` are read from **`@TaskLocal` harness slots** first when set, so unit tests are not coupled to polluted `UserDefaults.standard` (and values follow the Swift Testing task, not only the OS thread).
- **`CapabilityOverride`**: Assignments are stored on the **current thread** first (all platforms, including iOS). Setters **do not write** `SixLayerFramework.Override.*` into `UserDefaults.standard` (they remove stale keys so legacy reads do not resurrect old values). Getters still read `standard` when no thread-local value is present, for backward compatibility with keys set outside the framework.
- **Swift Testing**: Apply `DefaultRuntimeCapabilityIsolationTrait()` on `@Suite` types that exercise runtime capabilities (see `Development/Tests/Shared/TestHelpers/DefaultRuntimeCapabilityIsolationTrait.swift`). It scrubs legacy keys and pins macOS harness preferences off for each test.
- **`RuntimeCapabilityDetection.clearAllCapabilityOverrides()`**: Clears thread test hooks, thread `CapabilityOverride` state, and scrubs the legacy `UserDefaults.standard` keys listed above. (Harness `@TaskLocal` values are reset by the test suite trait’s `withValue` scopes.)

### Testing Configuration

In tests, use `RuntimeCapabilityDetection.setTestTouchSupport` / `CapabilityOverride` and **`clearAllCapabilityOverrides()`** (or the suite trait) so parallel runs stay deterministic:

```swift
func testTouchCapability() {
    // In testing mode, macOS defaults to false for touch
    XCTAssertFalse(RuntimeCapabilityDetection.supportsTouch)
    
    // But you can override for specific tests
    CapabilityOverride.touchSupport = true
    XCTAssertTrue(RuntimeCapabilityDetection.supportsTouchWithOverride)
    
    // Clean up
    CapabilityOverride.touchSupport = nil
    RuntimeCapabilityDetection.clearAllCapabilityOverrides()
}
```

## Platform-Specific Behavior

### Testing Defaults (Used in XCTest)

| Platform | Touch | Haptic | Hover | VoiceOver | SwitchControl | AssistiveTouch |
|----------|-------|--------|-------|-----------|---------------|----------------|
| iOS      | ✅    | ✅     | ❌    | ❌        | ❌            | ❌             |
| macOS    | ❌    | ❌     | ✅    | ❌        | ❌            | ❌             |
| watchOS  | ✅    | ✅     | ❌    | ❌        | ❌            | ❌             |
| tvOS     | ❌    | ❌     | ❌    | ❌        | ❌            | ❌             |
| visionOS | ✅    | ✅     | ✅    | ❌        | ❌            | ❌             |

### Runtime Detection (Used in Production)

- **iOS**: Always supports touch and haptic feedback
- **macOS**: Supports hover by default, touch only with third-party drivers or override
- **watchOS**: Supports touch and haptic feedback
- **tvOS**: Limited capabilities
- **visionOS**: Supports touch, haptic, and hover

## Override System

The framework provides an override system for special configurations:

```swift
// Enable touch support (useful for external touchscreens)
CapabilityOverride.touchSupport = true

// Enable haptic feedback (useful for external haptic devices)
CapabilityOverride.hapticSupport = true

// Disable hover (useful for testing hover-free scenarios)
CapabilityOverride.hoverSupport = false

// Check with overrides
let supportsTouch = RuntimeCapabilityDetection.supportsTouchWithOverride
let supportsHaptic = RuntimeCapabilityDetection.supportsHapticFeedbackWithOverride
let supportsHover = RuntimeCapabilityDetection.supportsHoverWithOverride
```

## Integration with Framework Components

The runtime detection is automatically integrated into:

- **Card Expansion**: Uses runtime detection for touch, haptic, and hover capabilities
- **Platform Optimization**: Uses runtime detection for gesture support
- **Accessibility**: Uses runtime detection for VoiceOver, Switch Control, and AssistiveTouch

## Migration from Hardcoded Detection

If you were previously using hardcoded platform detection:

```swift
// OLD: Hardcoded approach
let supportsTouch = Platform.current == .iOS

// NEW: Runtime detection
let supportsTouch = RuntimeCapabilityDetection.supportsTouchWithOverride
```

## Best Practices

1. **Use Override System**: For external hardware or special configurations
2. **Test Both Modes**: Test with and without overrides
3. **Clean Up Overrides**: Always clear overrides in test teardown
4. **Document Special Cases**: Document any special hardware configurations
5. **Fallback Gracefully**: Always provide fallbacks for unsupported capabilities

## Troubleshooting

### Touch Not Working on macOS

1. Check if third-party drivers are installed (UPDD, TouchBase, etc.)
2. Enable touch via override: `CapabilityOverride.touchSupport = true`
3. Check system preferences for touch enablement
4. Verify external touchscreen is properly connected

### Tests Failing

1. Ensure you're clearing overrides in `tearDown()`
2. Check that testing mode is properly detected
3. Verify platform-specific testing defaults are correct

### Performance Considerations

- Runtime detection is cached and efficient
- `CapabilityOverride` is thread-scoped; it no longer persists overrides to `UserDefaults.standard` (GitHub #236). Use `UserDefaults` only when you intentionally want process-wide, cross-launch configuration.
- Testing mode detection is optimized for XCTest environment
