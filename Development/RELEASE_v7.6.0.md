# SixLayer Framework v7.6.0 Release Documentation

**Release Date**: TBD  
**Release Type**: Minor  
**Previous Release**: v7.5.13  
**Status**: In preparation

---

## 🎯 Release Summary

Release-facing documentation update for managed settings adoption (Issue #215). This release adds explicit migration guidance for teams moving from manual `selectedCategory` routing to managed top-level flow APIs.

---

## 🆕 What's New

### **Managed settings migration notes (Issue #215)**

- Added release/changelog guidance that calls out managed settings adoption as a first-class path.
- Linked guide: `Framework/docs/ManagedPlatformSettingsFlowGuide.md`.
- Linked compile-checked composition example: `Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation/ManagedPlatformSettingsFlowGuideExampleTests.swift`.

---

## ✅ Resolved GitHub issues (milestone v7.6.0)

The following closed issues were completed under milestone **v7.6.0** and are summarized here for release traceability.

### **Issue #209 — Managed platform settings flow**

Implemented the managed platform settings flow (pane registry and navigation) on top of `platformSettingsContainer_L4`, giving apps a structured path for settings panes without ad-hoc branching.

### **Issue #210 — SettingsPaneDescriptor and section builders**

Added `SettingsPaneDescriptor` and section-oriented builders so managed settings UIs stay consistent and easier to evolve without layout drift across platforms.

### **Issue #211 — DeviceType settings shell policy matrix**

Documented and tested the DeviceType settings shell policy matrix so behavior for each device class is explicit, test-backed, and aligned with `PlatformManagedSettingsTopLevelShellPolicy` routing.

### **Issue #212 — L1 sidebar + platformManagedSettingsTopLevel_L4**

Documented composition of Layer 1 sidebar entry points with `platformManagedSettingsTopLevel_L4`, including strict TDD coverage and updates to the managed flow guide.

### **Issue #213 — Escape hatches for non-uniform detail layouts**

Documented escape hatches for non-uniform settings detail layouts so teams that cannot use uniform pane templates still have a supported, documented integration path.

### **Issue #214 — Optional ManagedSettingsPaneList default sidebar**

Added an optional default sidebar for `ManagedSettingsPaneList` derived from descriptors, reducing boilerplate when the default list matches the pane registry.

### **Issue #207 — Accessibility hardening (overlay / focus / navigation)**

Delivered accessibility hardening for overlay, focus, and navigation transitions as part of the broader structured-settings workstream (#202 slice 5).

### **Issue #208 — Stress matrix (resize, localization, RTL, Dynamic Type)**

Added stress-style coverage (rapid resize, localization, RTL, Dynamic Type, persistence) to validate managed settings and related UI under realistic variation (#202 slice 6).

### **Issue #222 — Automatic compliance: anonymous modifier wrapper IDs**

Improved automatic compliance behavior by suppressing wrapper accessibility identifiers for fully anonymous modifiers, cutting noise in automated UI audits.

### **Issue #225 — Managed settings sub-pane stack policy override**

Added an explicit managed settings sub-pane stack policy override so apps can adjust stack behavior without abandoning the managed shell or reimplementing selection logic.

### **Issue #235 — DynamicFormView header vs large navigation titles**

Resolved DynamicFormView header and title hierarchy conflicts with large navigation titles by adding configurable header display modes and related layout controls, with tests and documentation aligned to consumer apps.

---

## ✅ Migration (consumers)

- Replace manual optional selection (`selectedCategory`) ownership with `PlatformManagedSettingsTopLevelState`.
- Use `platformManagedSettingsTopLevel_L4` as the managed shell entry point.
- When combining with Layer 1 sidebar callbacks, map sidebar keys to typed pane IDs and route through `PlatformManagedSettingsFlowLogic.selectTopLevelPane` so top-level selection and detail-depth reset stay synchronized.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.13.md](RELEASE_v7.5.13.md) — Previous patch (v7.5.13)  
- [`Framework/docs/ManagedPlatformSettingsFlowGuide.md`](../Framework/docs/ManagedPlatformSettingsFlowGuide.md) — Managed flow guide
