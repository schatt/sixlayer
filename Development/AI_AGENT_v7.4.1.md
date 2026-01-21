# AI Agent Guide - SixLayer Framework v7.4.1

**Version**: v7.4.1  
**Release Date**: January 19, 2026  
**Release Type**: Patch (idealWidth and idealHeight Support for platformFrame)

---

## 🎯 What's New in v7.4.1

### **idealWidth and idealHeight Support for platformFrame() (Issue #152)**

The `platformFrame()` function now supports `idealWidth` and `idealHeight` parameters, making the API complete and consistent with SwiftUI's native `.frame()` modifier.

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

---

## 🔧 Implementation Improvements

### **Simplified Implementation**

The `platformFrame()` implementation has been simplified to use SwiftUI's `.frame()` modifier directly, eliminating 50+ lines of complex conditional logic:

**Before:**
```swift
// 50+ lines of nested conditionals
if let minWidth = clamped.minWidth, let minHeight = clamped.minHeight {
    if let maxWidth = clamped.maxWidth, let maxHeight = clamped.maxHeight {
        // ... many nested conditions
    }
}
```

**After:**
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

**Benefits:**
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

## 📝 Key Points for AI Agents

1. **API Completeness**: `platformFrame()` now matches SwiftUI's native `.frame()` modifier API
2. **Ideal Sizes**: Can specify ideal sizes alongside min/max constraints
3. **Automatic Clamping**: Ideal sizes are automatically clamped to screen/window bounds
4. **Backward Compatible**: All existing code continues to work unchanged
5. **Simplified Code**: Implementation is cleaner and more maintainable

### **When Helping with Frame Sizing**

1. **Use Ideal Sizes**: When you want to suggest a preferred size but allow flexibility
2. **Combine Constraints**: Can use min/ideal/max in any combination
3. **Platform-Aware**: Ideal sizes are automatically clamped, so safe to use
4. **Consistent API**: Same API as SwiftUI's native `.frame()` modifier

---

## 🔗 Related Documentation

- [RELEASE_v7.4.1.md](RELEASE_v7.4.1.md) - Complete release notes
- [RELEASE_NOTES_v7.4.1.md](../RELEASE_NOTES_v7.4.1.md) - User-facing release notes
- Issue #152: Add idealWidth and idealHeight support to platformFrame()

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
