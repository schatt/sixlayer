# SixLayer Framework v7.4.2 Release Documentation

**Release Date**: January 20, 2026  
**Release Type**: Patch (@MainActor Concurrency Fix for platformFrame)  
**Previous Release**: v7.4.1  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Patch release adding `@MainActor` annotation to `platformFrame()` functions to ensure correct Swift concurrency behavior. This makes the concurrency requirement explicit and allows the functions to be called from non-isolated contexts with `await`.

---

## 🔧 What's Fixed

### **Concurrency: @MainActor Annotation for platformFrame()**

#### **Issue**

`platformFrame()` functions were calling `@MainActor` helper functions (`clampFrameConstraints()`, `getMaxFrameSize()`, `getDefaultMaxFrameSize()`) which access main-actor isolated APIs (`UIApplication.shared`, `UIScreen.main`, `NSScreen.main`), but the `platformFrame()` functions themselves were not marked as `@MainActor`.

#### **Solution**

Added `@MainActor` annotation to both `platformFrame()` functions:
- `platformFrame()` (parameterless version)
- `platformFrame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)` (parameterized version)

#### **Technical Details**

The helper functions require `@MainActor` because they access:
- **iOS**: `UIApplication.shared.connectedScenes` and `UIScreen.main.bounds`
- **macOS**: `NSScreen.main.visibleFrame`
- **watchOS/tvOS/visionOS**: `WKInterfaceDevice.current()` and `UIScreen.main.bounds`

These are all main-actor isolated APIs that must be accessed from the main actor.

#### **Benefits**

- **Concurrency Correctness**: Explicitly marks functions that require main-actor context
- **Swift 6 Compliance**: Aligns with Swift 6 strict concurrency requirements
- **Flexibility**: Functions can now be called from non-isolated contexts using `await`
- **Clarity**: Makes concurrency requirements explicit in the API

---

## ✅ Backward Compatibility

**Fully backward compatible** - All existing code continues to work:
- View extension methods are typically called from View bodies, which are already on the main actor
- The `@MainActor` annotation doesn't change behavior when called from main-actor contexts
- Code that was already working continues to work unchanged

---

## 🧪 Testing

- Verified compilation with `@MainActor` annotation
- All existing tests continue to pass
- No breaking changes to API behavior

---

## 📝 Files Changed

- `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift` - Added `@MainActor` to both `platformFrame()` functions

---

## 🔗 Related Components

- Uses existing `PlatformFrameHelpers.clampFrameConstraints()` helper (already `@MainActor`)
- Integrates with platform-specific frame sizing system
- Works with all platform-specific styling and optimizations

---

## 📚 Documentation

- Updated inline documentation to reflect concurrency requirements
- Follows Swift concurrency best practices for main-actor isolation

---

## 🎯 Next Steps

Future enhancements could include:
- Additional concurrency audits for other View extension methods
- Enhanced documentation for concurrency patterns in the framework

---

**Resolves concurrency correctness issue**
