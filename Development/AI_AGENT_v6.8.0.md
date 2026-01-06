# AI Agent Guide for SixLayer Framework v6.8.0

This guide summarizes the version-specific context for v6.8.0. **Always read this file before assisting with the framework at this version.**

> **Scope**: This guide is for AI assistants helping developers use or extend the framework (not for automated tooling).

## 🎯 Quick Start

1. Confirm the project is on **v6.8.0** (see `Package.swift` comment or release tags).
2. **📚 Start with the Sample App**: See `Development/Examples/TaskManagerSampleApp/` for a complete, canonical example of how to structure a real app using SixLayer Framework correctly.
3. Know that **PlatformStrategy** is now the single source of truth for platform-specific simple values.
4. Know that **platform switch statements** for simple values have been consolidated into `PlatformStrategy`.
5. Know that **runtime capability checks** are consistently handled in `PlatformStrategy`.
6. Apply TDD, DRY, DTRT, and Epistemology rules in every change.

## 🆕 What's New in v6.8.0

### Platform Switch Consolidation (DRY Improvements)
- **PlatformStrategy Module**: Centralized platform-specific simple values in `Framework/Sources/Core/Models/PlatformStrategy.swift`
- **19 switch statements** consolidated into `PlatformStrategy`
- **4 duplicate functions** eliminated
- **Total: 23 code duplications eliminated**
- **100% consolidation** of identified simple value switches

### New PlatformStrategy Properties
- **Form style preferences**: `defaultFormStylePreference` (`.grouped` for iOS/watchOS/tvOS/visionOS, `.automatic` for macOS)
- **UI styling numeric values**: `defaultCardCornerRadius`, `defaultButtonCornerRadius`, `defaultShadowRadius`, `defaultShadowOffset`, `defaultAdaptiveBorderWidth`, `defaultAnnouncementDelay`
- **Boolean values**: `supportsLiquidGlassEffects`, `supportsLiquidGlassReflections`
- **Array values**: `defaultGridColumnCount`
- **Optimization properties**: `defaultDisplayOptimization`, `defaultFrameRateOptimization`, `defaultCompatibilityScore`, `defaultPerformanceScore`, `defaultAccessibilityScore`
- **Animation and interaction properties**: `defaultAnimationCategory`, `defaultKeyboardModifiers`, `defaultShortcutDescription`

### Eliminated Duplicate Functions
- **Removed 4 duplicate `convertPlatformStyle` functions** across multiple files
- **Added `PlatformStyle.sixLayerPlatform` property** to `VisualDesignSystem.swift` for centralized conversion

### Runtime Check Pattern Consistency
- **Consistent runtime capability checks**: Runtime capability checks (e.g., `supportsHover`, `supportsTouch`) are now consistently handled in `PlatformStrategy`
- **Example**: `hoverDelay` now checks `RuntimeCapabilityDetection.supportsHover` before returning platform-specific values
- **Impact**: Ensures platform-specific values are only returned when capabilities are actually available

## 🔄 What's Inherited from v6.7.0

### Count-Based Automatic Presentation Behavior
- **Count-Aware Automatic**: `.automatic` presentation preference now considers item count for generic/collection content, with platform-aware thresholds (macOS/iPad: 12, iPhone: 8, watchOS/tvOS: 3)
- **Explicit Control**: `.countBased(lowCount:highCount:threshold:)` enum case available for explicit count-based presentation control
- **Context-Aware Layout**: Enhanced layout parameter selection based on screen size and edge cases
- **Safety Override**: Very large collections (>200 items) automatically use list presentation

### Touch Target Test Fixes
- **Apple HIG Compliance**: Tests correctly expect 44.0 minimum touch target when touch is enabled, per Apple Human Interface Guidelines
- **Floating Point Comparison**: Tolerance-based comparison in touch target tests handles precision issues
- **Error Messages**: Improved error messages show actual vs expected values for better debugging

## 📝 Important Patterns

### Using PlatformStrategy
When you need platform-specific simple values, use `PlatformStrategy` instead of writing new switch statements:

```swift
// ✅ Good: Use PlatformStrategy
let cornerRadius = platform.sixLayerPlatform.defaultCardCornerRadius

// ❌ Bad: Don't write new switch statements for simple values
switch platform {
case .iOS: return 12.0
case .macOS: return 8.0
// ...
}
```

### Runtime Capability Checks
Runtime capability checks should be in `PlatformStrategy`, then delegated from `RuntimeCapabilityDetection`:

```swift
// ✅ Good: Runtime check in PlatformStrategy
var hoverDelay: TimeInterval {
    guard RuntimeCapabilityDetection.supportsHover else {
        return 0.0
    }
    // Return platform-specific value
}

// ❌ Bad: Don't skip runtime checks
var hoverDelay: TimeInterval {
    // Just return platform value without checking capability
}
```

### Switch Statement Preferences
- **Prefer `switch` statements** over `if/else if` chains for enum matching
- **Use consistent conditional compilation** (`#if os(...)`) for compile-time safety
- **Make switches exhaustive** by explicitly listing all cases

## 🔗 Related Issues

- **Issue #140**: Consolidate Platform Switch Statements (DRY Improvement) - ✅ Complete
- **Issue #141**: PlatformStrategy Runtime Check Pattern Consistency - ✅ Complete

## 📚 Key Files

- **PlatformStrategy**: `Framework/Sources/Core/Models/PlatformStrategy.swift` - Single source of truth for platform-specific simple values
- **RuntimeCapabilityDetection**: `Framework/Sources/Core/Models/RuntimeCapabilityDetection.swift` - Delegates to PlatformStrategy for platform values

## ⚠️ Remaining Switches

**~38 switches remain**, but these are complex/domain-specific and appropriate as-is:
- **ViewBuilder switches (5)**: Dispatch to platform-specific ViewBuilders
- **Struct initialization (6)**: Complex structs with multiple properties
- **Function dispatch (1)**: Platform-specific function calls
- **Domain-specific logic (~26)**: Complex business logic

These represent legitimate domain logic rather than simple value duplication.

