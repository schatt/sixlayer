# SixLayer Framework v7.4.1 Release Documentation

**Release Date**: January 19, 2026  
**Release Type**: Patch (idealWidth and idealHeight Support for platformFrame)  
**Previous Release**: v7.3.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Patch release adding `idealWidth` and `idealHeight` parameter support to `platformFrame()` to match SwiftUI's native `.frame()` modifier API. Ideal sizes are automatically clamped to screen/window bounds on all platforms, similar to max sizes.

---

## 🆕 What's New

### **idealWidth and idealHeight Support for platformFrame() (Issue #152)**

#### **New Parameters: `idealWidth`, `idealHeight`**

Added support for ideal size constraints in `platformFrame()`, making the API complete and consistent with SwiftUI's native `.frame()` modifier:

```swift
// Before: Only min/max constraints
view.platformFrame(minWidth: 400, maxWidth: 1200)

// After: Full min/ideal/max support
view.platformFrame(
    minWidth: 400,
    idealWidth: 800,
    maxWidth: 1200,
    minHeight: 300,
    idealHeight: 600,
    maxHeight: 900
)
```

#### **Updated Function Signature**

```swift
func platformFrame(
    minWidth: CGFloat? = nil,
    idealWidth: CGFloat? = nil,
    maxWidth: CGFloat? = nil,
    minHeight: CGFloat? = nil,
    idealHeight: CGFloat? = nil,
    maxHeight: CGFloat? = nil
) -> some View
```

#### **Usage Examples**

**Basic Ideal Size:**
```swift
Text("Content")
    .platformFrame(idealWidth: 800, idealHeight: 600)
```

**Full Constraint Set:**
```swift
Text("Content")
    .platformFrame(
        minWidth: 400,
        idealWidth: 800,
        maxWidth: 1200,
        minHeight: 300,
        idealHeight: 600,
        maxHeight: 900
    )
```

**Combined with Other Constraints:**
```swift
Text("Content")
    .platformFrame(
        minWidth: 400,
        idealWidth: 800,
        maxWidth: 1200
    )
```

#### **Platform-Specific Clamping**

Ideal sizes are automatically clamped to available screen/window space:
- **iOS**: Clamped to actual window size (handles Split View, Stage Manager, etc.)
- **macOS**: Clamped to 90% of visible screen frame
- **watchOS/tvOS/visionOS**: Clamped to screen bounds

#### **Benefits**

- **API Completeness**: Matches SwiftUI's native `.frame()` modifier API
- **Flexibility**: Specify ideal sizes alongside min/max constraints
- **Platform-Aware**: Automatic clamping prevents views from exceeding device bounds
- **Backward Compatible**: All existing code continues to work unchanged
- **Simplified Implementation**: Cleaner code using SwiftUI's frame modifier directly

---

## 🔧 What's Fixed

### **Implementation Simplification**

Refactored `platformFrame()` implementation to use SwiftUI's `.frame()` modifier directly, eliminating complex conditional logic:

```swift
// Before: 50+ lines of complex conditionals
if let minWidth = clamped.minWidth, let minHeight = clamped.minHeight {
    if let maxWidth = clamped.maxWidth, let maxHeight = clamped.maxHeight {
        // ... many nested conditions
    }
}

// After: Clean pass-through to SwiftUI
self.frame(
    minWidth: clamped.minWidth,
    idealWidth: clamped.idealWidth,
    maxWidth: clamped.maxWidth,
    minHeight: clamped.minHeight,
    idealHeight: clamped.idealHeight,
    maxHeight: clamped.maxHeight
)
```

#### **Benefits**

- **DRY Principle**: Eliminated code duplication
- **Maintainability**: Easier to understand and modify
- **Consistency**: Uses SwiftUI's native frame modifier behavior
- **Extensibility**: Easy to add future frame constraint parameters

---

## ✅ Backward Compatibility

**Fully backward compatible** - All existing code continues to work:
- Existing `platformFrame()` calls with min/max parameters work unchanged
- New ideal parameters are optional with default `nil` values
- No breaking changes to existing APIs

---

## 🧪 Testing

- Added 7 comprehensive test cases covering ideal size support
- Tests verify ideal size clamping on all platforms
- Tests validate combinations of min/ideal/max constraints
- All existing tests continue to pass

---

## 📝 Files Changed

- `Framework/Sources/Extensions/Platform/PlatformFrameHelpers.swift` - Added ideal size clamping support
- `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift` - Added ideal parameters to `platformFrame()` and simplified implementation
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Platform/PlatformFrameSafetyTests.swift` - Added comprehensive test coverage

---

## 🔗 Related Components

- Uses existing `PlatformFrameHelpers.clampFrameConstraints()` helper
- Integrates with platform-specific frame sizing system
- Works with all platform-specific styling and optimizations
- Consistent with `platformAdaptiveFrame()` which uses ideal sizes with defaults

---

## 📚 Documentation

- Issue #152: Add idealWidth and idealHeight support to platformFrame()
- Updated inline documentation in `PlatformFrameHelpers.swift` and `PlatformSpecificViewExtensions.swift`
- Comprehensive test coverage demonstrates usage patterns

---

## 🎯 Next Steps

Future enhancements could include:
- Additional frame constraint parameters as SwiftUI evolves
- Enhanced documentation for ideal size usage patterns
- Performance optimizations for frame constraint calculations

---

**Resolves Issue #152**
