# SixLayer Framework v7.5.11 Release Documentation

**Release Date**: April 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.10  
**Status**: Released

---

## 🎯 Release Summary

Patch release following **v7.5.10**. Aligns **`platformFormContainer`** with its name: the container **owns** a SwiftUI `Form` on every Apple platform so consumers are not forced to add a macOS-only inner `Form` (which nested with the iOS `Form` and broke layout). Includes a focused ViewInspector test where the unit-test target links ViewInspector.

---

## 🆕 What's New

### **`platformFormContainer` owns `Form` everywhere (Resolves [Issue #218](https://github.com/schatt/sixlayer/issues/218))**

- **macOS**: Wraps content in `Form` with `.formStyle(.grouped)` and outer padding (same spacing role as before).
- **iOS**: Unchanged — still a plain `Form` host.
- **tvOS, watchOS, visionOS, and other non–iOS/macOS targets**: Use `Form` with outer padding instead of a padded `VStack`, matching the API contract across the matrix.
- **Documentation**: API doc states callers must not wrap `content` in another outer `Form`; use `Section` and controls inside this container only.

### **Tests**

- **`PlatformStandaloneDropInTests.testPlatformFormContainer_OwnsForm()`**: Asserts a `Form` appears in the hierarchy when `ViewInspector` is linked (iOS/macOS unit targets). Other platform unit targets omit ViewInspector; see [Issue #219](https://github.com/schatt/sixlayer/issues/219) for a planned coverage follow-up.

---

## ✅ Backward Compatibility

**Behavior change (intentional)**: Apps that previously wrapped **`platformFormContainer`** content in an extra `Form` on macOS (or other platforms) to get grouped behavior should **remove** the inner `Form` and rely on this API as the single form host. Nesting `Form` inside `Form` remains invalid on iOS and is unnecessary on macOS after this release.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.10.md](RELEASE_v7.5.10.md) — Previous patch (v7.5.10)
