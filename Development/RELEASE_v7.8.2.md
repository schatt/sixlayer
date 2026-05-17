# SixLayer Framework v7.8.2 Release Documentation

**Release Date**: May 17, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.1  
**Status**: Released

---

## 🎯 Release Summary

v7.8.2 is a **patch** release focused on **Layer 4 assistive visual adaptability** coverage and hosting fixes (**#255**), expanded **Layer 4 semantic matrix** evidence (**#254**), **`platformMapView_L4`** accessibility contract and UIKit hosting stability, broad **XCUITest** scroll/query hardening for L4 System and SD150 integration flows, a duplicate **CloudKit sync status** accessibility identifier fix in examples, and **integration-branch** git hook documentation/clarifications.

---

## 🆕 Confirmed in v7.8.2 (implemented)

### **Layer 4 assistive visual adaptability (Issue #255)**

- Hosted helpers and matrix sweep tests for **VoiceOver**, **Switch Control**, and **increased contrast** across Layer 4 APIs.
- **Dynamic Type** stability checks extended to split views, CloudKit, photo picker, share, form field, app navigation, settings, and related surfaces.
- Test hosting fixes for adaptability environment chains and high-contrast trait overrides.

### **Layer 4 semantic matrix evidence (Issue #254)**

- Hosted semantic tests and matrix documentation for stack items, styled containers, split views, row actions, context menus, maps, forms, camera interface/preview, CloudKit, print, and photo surfaces.

### **`platformMapView_L4` accessibility**

- Explicit map **contract** `accessibilityIdentifier`, container semantics (`accessibilityElement(children: .ignore)`), minimum frame for UIKit hosting, and `Group` wrapper so compliance tests host reliably.

### **XCUITest and integration test stabilization**

- Shared L4 System scroll helpers, CloudKit/photo contract query simplification, SD150 secure-field and Form scroll budgets, fail-fast scroll/wait caps, and deeper Form scroll for L4 System sections.

### **Examples and tooling**

- Removes duplicate CloudKit sync status accessibility identifier in L4 examples.
- Adds `Layer4AssistiveVisualAdaptabilityCriterionTests` to the iOS unit target via XcodeGen; aligns shared `SLF-iOS-AllTests` scheme after Xcode save.
- Ignores ephemeral Xcode derived-data access logs; documents integration pre-commit hook merge allowance.

---

## ✅ Resolved / advanced GitHub issues

- **[Issue #255](https://github.com/schatt/sixlayer/issues/255)** — Assistive visual adaptability matrix: VoiceOver, Switch Control, contrast, and Dynamic Type coverage on iOS.
- **[Issue #254](https://github.com/schatt/sixlayer/issues/254)** — Layer 4 semantic criterion matrix evidence for hosted compliance tests.
- **[Issue #261](https://github.com/schatt/sixlayer/issues/261)** — Layer 4–6 UITest runtime stabilization (scroll, queries, CloudKit/Form anchoring).

---

## ⚠️ Migration / consumer notes

- **UI tests**: Prefer contract `accessibilityIdentifier`s and shared scroll helpers added in this release over brittle tree scans for L4 System, CloudKit, and photo picker flows.
- **Maps**: `platformMapView_L4` now exposes a stable contract identifier; tests may assert map presence via `MKMapView` when wrapper ids are hidden.

---

## 🔗 References

- [RELEASE_v7.8.1.md](RELEASE_v7.8.1.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
