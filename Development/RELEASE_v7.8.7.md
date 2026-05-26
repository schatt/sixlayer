# SixLayer Framework v7.8.7 Release Documentation

**Release Date**: May 25, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.6  
**Status**: Released

---

## 🎯 Release Summary

v7.8.7 is a **patch** release that exposes a **public initializer** on `PlatformTabStrip` ([#292](https://github.com/schatt/sixlayer/issues/292)). App targets (e.g. CarManager) can construct the tab strip directly instead of duplicating the view with lower-level `platformPicker` / `platformHStackContainer` primitives.

---

## 🆕 Confirmed in v7.8.7 (implemented)

### **PlatformTabStrip public initializer (#292)**

- **`public init(selection: Binding<Int>, items: [PlatformTabItem])`** — explicit initializer for external modules; `body` behavior unchanged across iOS, watchOS, and macOS.
- **`ExternalModuleIntegrationTests.testPlatformTabStripAccessible`** — non-`@testable` import guards API visibility (same pattern as photo picker regression tests).

**Usage:**

```swift
import SixLayerFramework

let items = [
    PlatformTabItem(title: "Costs", systemImage: "dollarsign.circle"),
    PlatformTabItem(title: "Fuel", systemImage: "fuelpump"),
]

PlatformTabStrip(selection: $index, items: items)
```

---

## ✅ Resolved GitHub issues

- **[Issue #292](https://github.com/schatt/sixlayer/issues/292)** — `PlatformTabStrip` initializer inaccessible to app-target consumers.

---

## ⚠️ Migration / consumer notes

- **CarManager:** Bump SPM to **`7.8.7`** after tag. Replace duplicated `ReportTypeTabStrip` (or similar) with `PlatformTabStrip` ([#478](https://github.com/schatt/CarManager/issues/478)).
- **No breaking changes** — additive public API only.

---

## 🔗 References

- [RELEASE_v7.8.6.md](RELEASE_v7.8.6.md) — prior patch (OCR overlay bounding boxes #291).
- [RELEASES.md](RELEASES.md) — release history index.
