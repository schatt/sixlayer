# SixLayer Framework v7.4.2 Release Notes

**Release Date**: January 20, 2026  
**Release Type**: Patch (@MainActor Concurrency Fix for platformFrame)  
**Previous Version**: v7.4.1

## 🎯 Release Summary

This patch release adds `@MainActor` annotation to `platformFrame()` functions to ensure correct Swift concurrency behavior. This makes the concurrency requirement explicit and allows the functions to be called from non-isolated contexts with `await`. The fix addresses a concurrency correctness issue where `platformFrame()` functions were calling `@MainActor` helper functions without being marked as `@MainActor` themselves.

## 🔧 What's Fixed

### **Concurrency: @MainActor Annotation for platformFrame()**

#### **The Issue**

`platformFrame()` functions were calling `@MainActor` helper functions (`clampFrameConstraints()`, `getMaxFrameSize()`, `getDefaultMaxFrameSize()`) which access main-actor isolated APIs (`UIApplication.shared`, `UIScreen.main`, `NSScreen.main`), but the `platformFrame()` functions themselves were not marked as `@MainActor`.

This created a concurrency correctness issue:
- Helper functions require `@MainActor` because they access main-actor isolated APIs
- `platformFrame()` functions called these helpers but weren't marked as `@MainActor`
- This could cause runtime issues in Swift 6 strict concurrency mode

#### **The Solution**

Added `@MainActor` annotation to both `platformFrame()` functions:

1. **`platformFrame()` (parameterless version)**:
   ```swift
   @MainActor
   func platformFrame() -> some View
   ```

2. **`platformFrame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)` (parameterized version)**:
   ```swift
   @MainActor
   func platformFrame(
       minWidth: CGFloat? = nil,
       idealWidth: CGFloat? = nil,
       maxWidth: CGFloat? = nil,
       minHeight: CGFloat? = nil,
       idealHeight: CGFloat? = nil,
       maxHeight: CGFloat? = nil
   ) -> some View
   ```

#### **Technical Details**

The helper functions require `@MainActor` because they access:

- **iOS**: 
  - `UIApplication.shared.connectedScenes` - Main-actor isolated
  - `UIScreen.main.bounds` - Main-actor isolated

- **macOS**: 
  - `NSScreen.main.visibleFrame` - Main-actor isolated

- **watchOS/tvOS/visionOS**: 
  - `WKInterfaceDevice.current()` - Main-actor isolated
  - `UIScreen.main.bounds` - Main-actor isolated

These are all main-actor isolated APIs that must be accessed from the main actor.

#### **Benefits**

- **Concurrency Correctness**: Explicitly marks functions that require main-actor context
- **Swift 6 Compliance**: Aligns with Swift 6 strict concurrency requirements
- **Flexibility**: Functions can now be called from non-isolated contexts using `await`
- **Clarity**: Makes concurrency requirements explicit in the API
- **Future-Proof**: Prevents issues when upgrading to Swift 6 strict concurrency mode

## ✅ Backward Compatibility

**Fully backward compatible** - All existing code continues to work:

- View extension methods are typically called from View bodies, which are already on the main actor
- The `@MainActor` annotation doesn't change behavior when called from main-actor contexts
- Code that was already working continues to work unchanged
- For code calling from non-isolated contexts, use `await`:

```swift
// From non-isolated context
Task {
    await someView.platformFrame(minWidth: 400)
}
```

## 🧪 Testing

### **Verification**

- Verified compilation with `@MainActor` annotation
- All existing tests continue to pass
- No breaking changes to API behavior
- Concurrency correctness verified

### **Test Coverage**

- All existing `platformFrame()` tests continue to pass
- Tests verify functions work correctly with `@MainActor` annotation
- No additional test changes required (tests already run on main actor)

## 📝 Files Changed

- `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift`:
  - Added `@MainActor` to both `platformFrame()` functions
  - Updated inline documentation to reflect concurrency requirements

## 🔗 Related Components

- Uses existing `PlatformFrameHelpers.clampFrameConstraints()` helper (already `@MainActor`)
- Uses existing `PlatformFrameHelpers.getMaxFrameSize()` helper (already `@MainActor`)
- Uses existing `PlatformFrameHelpers.getDefaultMaxFrameSize()` helper (already `@MainActor`)
- Integrates with platform-specific frame sizing system
- Works with all platform-specific styling and optimizations

## 📚 Documentation

- Updated inline documentation to reflect concurrency requirements
- Follows Swift concurrency best practices for main-actor isolation
- Documents that functions can be called from non-isolated contexts with `await`

## 🎯 Next Steps

Future enhancements could include:
- Additional concurrency audits for other View extension methods
- Enhanced documentation for concurrency patterns in the framework
- Comprehensive Swift 6 strict concurrency compliance review
- Additional concurrency correctness improvements

---

**Version**: 7.4.2  
**Release Date**: January 20, 2026  
**Previous Version**: v7.4.1  
**Status**: Production Ready 🚀
