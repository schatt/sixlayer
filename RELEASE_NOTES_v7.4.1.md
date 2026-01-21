# SixLayer Framework v7.4.1 Release Notes

**Release Date**: January 19, 2026  
**Release Type**: Patch (idealWidth and idealHeight Support for platformFrame)  
**Previous Version**: v7.4.0

## 🎯 Release Summary

This patch release adds `idealWidth` and `idealHeight` parameter support to `platformFrame()` to match SwiftUI's native `.frame()` modifier API. Ideal sizes are automatically clamped to screen/window bounds on all platforms, similar to max sizes. The implementation has also been simplified by using SwiftUI's frame modifier directly, eliminating complex conditional logic and improving maintainability.

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
    idealWidth: CGFloat? = nil,      // NEW
    maxWidth: CGFloat? = nil,
    minHeight: CGFloat? = nil,
    idealHeight: CGFloat? = nil,     // NEW
    maxHeight: CGFloat? = nil
) -> some View
```

#### **Usage Examples**

##### **Basic Ideal Size**

```swift
Text("Content")
    .platformFrame(idealWidth: 800, idealHeight: 600)
```

This sets the ideal size to 800x600, but allows the view to shrink or grow based on available space and other constraints.

##### **Full Constraint Set**

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

This provides complete control over view sizing with min, ideal, and max constraints.

##### **Combined with Other Constraints**

```swift
Text("Content")
    .platformFrame(
        minWidth: 400,
        idealWidth: 800,
        maxWidth: 1200
    )
```

You can specify ideal sizes alongside min/max constraints in any combination.

#### **Platform-Specific Clamping**

Ideal sizes are automatically clamped to available screen/window space:

- **iOS**: Clamped to actual window size (handles Split View, Stage Manager, etc.)
- **macOS**: Clamped to 90% of visible screen frame
- **watchOS/tvOS/visionOS**: Clamped to screen bounds

This ensures views never exceed device bounds, even when ideal sizes are specified.

#### **Benefits**

- **API Completeness**: Matches SwiftUI's native `.frame()` modifier API
- **Flexibility**: Specify ideal sizes alongside min/max constraints
- **Platform-Aware**: Automatic clamping prevents views from exceeding device bounds
- **Backward Compatible**: All existing code continues to work unchanged
- **Simplified Implementation**: Cleaner code using SwiftUI's frame modifier directly

## 🔧 What's Fixed

### **Implementation Simplification**

Refactored `platformFrame()` implementation to use SwiftUI's `.frame()` modifier directly, eliminating complex conditional logic:

**Before (50+ lines of complex conditionals):**
```swift
if let minWidth = clamped.minWidth, let minHeight = clamped.minHeight {
    if let maxWidth = clamped.maxWidth, let maxHeight = clamped.maxHeight {
        if let idealWidth = clamped.idealWidth, let idealHeight = clamped.idealHeight {
            // ... many nested conditions
        } else if let idealWidth = clamped.idealWidth {
            // ... more conditions
        } else if let idealHeight = clamped.idealHeight {
            // ... more conditions
        }
        // ... many more nested conditions
    }
}
// ... 50+ more lines of similar nested conditions
```

**After (Clean pass-through to SwiftUI):**
```swift
self.frame(
    minWidth: clamped.minWidth,
    idealWidth: clamped.idealWidth,
    maxWidth: clamped.maxWidth,
    minHeight: clamped.minHeight,
    idealHeight: clamped.idealHeight,
    maxHeight: clamped.maxHeight
)
```

#### **Benefits of Simplification**

- **DRY Principle**: Eliminated code duplication
- **Maintainability**: Easier to understand and modify
- **Consistency**: Uses SwiftUI's native frame modifier behavior
- **Extensibility**: Easy to add future frame constraint parameters
- **Reduced Complexity**: From 50+ lines to a single frame call

### **Ideal Size Clamping**

Ideal sizes are now automatically clamped using the existing `PlatformFrameHelpers.clampFrameConstraints()` helper:

- **Consistent Behavior**: Ideal sizes use the same clamping logic as min/max sizes
- **Platform-Aware**: Clamping respects platform-specific screen/window bounds
- **Safe Defaults**: Prevents views from exceeding device capabilities

## ✅ Backward Compatibility

**Fully backward compatible** - All existing code continues to work:

- Existing `platformFrame()` calls with min/max parameters work unchanged
- New ideal parameters are optional with default `nil` values
- No breaking changes to existing APIs
- All existing tests continue to pass

## 🧪 Testing

### **New Test Coverage**

Added 7 comprehensive test cases covering ideal size support:

1. **Basic Ideal Size Tests**:
   - Tests for ideal width only
   - Tests for ideal height only
   - Tests for both ideal width and height

2. **Combined Constraint Tests**:
   - Tests for min/ideal/max combinations
   - Tests for ideal with min only
   - Tests for ideal with max only

3. **Clamping Tests**:
   - Tests verify ideal size clamping on all platforms
   - Tests validate clamping respects screen/window bounds

### **Updated Tests**

- All existing `platformFrame()` tests continue to pass
- Tests updated to verify ideal size integration works correctly

## 📝 Files Changed

- `Framework/Sources/Extensions/Platform/PlatformFrameHelpers.swift`:
  - Added ideal size clamping support to `clampFrameConstraints()`
  - Updated clamping logic to handle ideal sizes

- `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift`:
  - Added `idealWidth` and `idealHeight` parameters to `platformFrame()`
  - Simplified implementation to use SwiftUI's frame modifier directly
  - Removed complex conditional logic

- `Development/Tests/SixLayerFrameworkUnitTests/Features/Platform/PlatformFrameSafetyTests.swift`:
  - Added comprehensive test coverage for ideal size support
  - Tests for all constraint combinations
  - Tests for platform-specific clamping

## 🔗 Related Components

- Uses existing `PlatformFrameHelpers.clampFrameConstraints()` helper
- Integrates with platform-specific frame sizing system
- Works with all platform-specific styling and optimizations
- Consistent with `platformAdaptiveFrame()` which uses ideal sizes with defaults

## 📚 Documentation

- **Issue #152**: Add idealWidth and idealHeight support to platformFrame() - ✅ Complete
- Updated inline documentation in `PlatformFrameHelpers.swift` and `PlatformSpecificViewExtensions.swift`
- Comprehensive test coverage demonstrates usage patterns

## 🎯 Next Steps

Future enhancements could include:
- Additional frame constraint parameters as SwiftUI evolves
- Enhanced documentation for ideal size usage patterns
- Performance optimizations for frame constraint calculations
- Additional convenience methods for common frame constraint patterns

---

**Version**: 7.4.1  
**Release Date**: January 19, 2026  
**Previous Version**: v7.4.0  
**Status**: Production Ready 🚀
