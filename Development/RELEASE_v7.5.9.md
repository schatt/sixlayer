# SixLayer Framework v7.5.9 Release Documentation

**Release Date**: March 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.8  
**Status**: In preparation

---

## 🎯 Release Summary

Patch release that follows **v7.5.8**. It includes a Swift concurrency fix for file drop handling in advanced field types, and test-infrastructure fixes for accessibility identifier pattern matching used by ViewInspector tests.

---

## 🆕 What's New

### **Advanced field file drop: Swift concurrency (Resolves Issue #196)**

- **`AdvancedFieldTypes` / file upload**: Dropped-file handling no longer mutates view state from `NSItemProvider` completion handlers off the main actor. File selection is delivered on the main actor via `Task { @MainActor in ... }`, eliminating the data-race warning around asynchronous load callbacks.

### **Accessibility test utilities: glob matching and Xcode project sync (Resolves Issue #192)**

- **Expected-pattern matching**: Glob patterns such as `SixLayer.*ui` now match real identifiers (for example `SixLayer.main.ui.test.Button`) instead of incorrectly requiring the string to end with `ui`.
- **Coverage**: Unit tests validate glob vs regex behavior; the generated Xcode project includes the new test source so `SLFiOSViewInspectorTests` builds those tests.

---

## ✅ Backward Compatibility

**Fully backward compatible** — behavior changes are limited to correct main-actor delivery for dropped files and more accurate test matching; no public API removals.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [RELEASE_v7.5.8.md](RELEASE_v7.5.8.md) — Previous patch (v7.5.8)
