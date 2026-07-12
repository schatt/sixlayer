# SixLayer Framework v8.2.1 Release Documentation

**Release Date**: July 12, 2026  
**Release Type**: Patch  
**Previous Release**: v8.2.0  
**Status**: Released

---

## 🎯 Release Summary

v8.2.1 is a **patch** release that fixes **Xcode 27 beta** compile failures when consumers build SixLayer against **iOS 17 / macOS 15** deployment targets. Redundant `#available` gates for OS versions **below** the package minimum inside `@ViewBuilder` code triggered Xcode 27’s limited-availability ContentBuilder path, producing `TupleContent<…>: View` conformance errors requiring iOS/macOS **26+** ([#340](https://github.com/schatt/sixlayer/issues/340)).

---

## 🆕 Confirmed in v8.2.1 (implemented)

### **Xcode 27 `@ViewBuilder` compile fix (#340)**

- Removed **dead** `#available` gates (iOS ≤16, macOS ≤11–13) inside `@ViewBuilder` where package platforms already require iOS 17 / macOS 15.
- **No behavior change** on supported OS versions — compile-time fix only.
- **Legitimate** `#available(iOS 18.0, *)` gates on iOS 17 deploy targets compile cleanly under Xcode 27; only sub-minimum gates were removed.

**Files updated:**
- `PlatformSemanticLayer1.swift` — LabeledContent gates in field preview builders
- `PlatformNavigationLayer4.swift` — navigation / Label gates
- `DynamicFieldComponents.swift` — Gauge, MultiDatePicker, LabeledContent, text-field axis gates
- `PlatformSpecificViewExtensions.swift` — NavigationSplitView, fileImporter gates
- `PlatformNavigationHelpers.swift` — iOS 16 / macOS 13 navigation gates

---

## ✅ Resolved GitHub issues (milestone v8.2.1)

- **[Issue #340](https://github.com/schatt/sixlayer/issues/340)** — v8.2.0 macOS build: TupleContent View conformance requires iOS 26 (Xcode 27 beta).

---

## ⚠️ Migration / consumer notes

- **SPM consumers** on v8.2.0 (e.g. CarManager) should bump to **v8.2.1** when building with **Xcode 27 beta** toolchains.
- **No intentional breaking public API changes** — patch release; remove any local workarounds that duplicated dead-gate removal.
- **Apple Feedback:** FB23710247 (Xcode 27 ContentBuilder / redundant `#available` behavior).

---

## 🔗 References

- [RELEASE_v8.2.0.md](RELEASE_v8.2.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.2.0.md](AI_AGENT_v8.2.0.md) — Prior minor agent baseline.
