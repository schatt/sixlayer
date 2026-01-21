# AI Agent Guide - SixLayer Framework v7.4.2

**Version**: v7.4.2  
**Release Date**: January 20, 2026  
**Release Type**: Patch (@MainActor Concurrency Fix for platformFrame)

---

## 🎯 What's Fixed in v7.4.2

### **Concurrency: @MainActor Annotation for platformFrame()**

Added `@MainActor` annotation to `platformFrame()` functions to ensure correct Swift concurrency behavior.

#### **The Issue**

`platformFrame()` functions were calling `@MainActor` helper functions (`clampFrameConstraints()`, `getMaxFrameSize()`, `getDefaultMaxFrameSize()`) which access main-actor isolated APIs, but the `platformFrame()` functions themselves were not marked as `@MainActor`.

#### **The Solution**

Added `@MainActor` annotation to both `platformFrame()` functions:

```swift
@MainActor
func platformFrame() -> some View

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

#### **Why This Matters**

The helper functions require `@MainActor` because they access:
- **iOS**: `UIApplication.shared.connectedScenes`, `UIScreen.main.bounds`
- **macOS**: `NSScreen.main.visibleFrame`
- **watchOS/tvOS/visionOS**: `WKInterfaceDevice.current()`, `UIScreen.main.bounds`

These are all main-actor isolated APIs that must be accessed from the main actor.

---

## ✅ Backward Compatibility

**Fully backward compatible** - All existing code continues to work:
- View extension methods are typically called from View bodies, which are already on the main actor
- The `@MainActor` annotation doesn't change behavior when called from main-actor contexts
- Code that was already working continues to work unchanged

### **Calling from Non-Isolated Contexts**

If you need to call `platformFrame()` from a non-isolated context, use `await`:

```swift
// From non-isolated context
Task {
    await someView.platformFrame(minWidth: 400)
}
```

---

## 📝 Key Points for AI Agents

1. **Concurrency Correctness**: `platformFrame()` now explicitly requires main-actor context
2. **Swift 6 Compliance**: Aligns with Swift 6 strict concurrency requirements
3. **Flexibility**: Functions can be called from non-isolated contexts using `await`
4. **Clarity**: Makes concurrency requirements explicit in the API
5. **Future-Proof**: Prevents issues when upgrading to Swift 6 strict concurrency mode

### **When Helping with Concurrency**

1. **Main Actor Context**: `platformFrame()` must be called from main actor
2. **View Bodies**: Typically called from View bodies (already on main actor)
3. **Non-Isolated Contexts**: Use `await` when calling from non-isolated contexts
4. **Swift 6 Ready**: This change prepares for Swift 6 strict concurrency

---

## 🔗 Related Documentation

- [RELEASE_v7.4.2.md](RELEASE_v7.4.2.md) - Complete release notes
- [RELEASE_NOTES_v7.4.2.md](../RELEASE_NOTES_v7.4.2.md) - User-facing release notes

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
