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

## ✅ Migration (consumers)

- Replace manual optional selection (`selectedCategory`) ownership with `PlatformManagedSettingsTopLevelState`.
- Use `platformManagedSettingsTopLevel_L4` as the managed shell entry point.
- When combining with Layer 1 sidebar callbacks, map sidebar keys to typed pane IDs and route through `PlatformManagedSettingsFlowLogic.selectTopLevelPane` so top-level selection and detail-depth reset stay synchronized.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.13.md](RELEASE_v7.5.13.md) — Previous patch (v7.5.13)  
- [`Framework/docs/ManagedPlatformSettingsFlowGuide.md`](../Framework/docs/ManagedPlatformSettingsFlowGuide.md) — Managed flow guide
