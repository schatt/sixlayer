# SixLayer Framework v8.5.0 Release Documentation

**Release Date**: September 17, 2026  
**Release Type**: Minor  
**Previous Release**: v8.4.0  
**Status**: Released

---

## 🎯 Release Summary

v8.5.0 is a **minor** release focused on honest iOS/macOS L5/L6 public APIs: unified haptics, real macOS L5 chrome, keyboard-first NavigationStack, split/nav consolidation, FormLayoutDecision wiring, form select-all opt-in, and unit-lane honesty for example Sources and Layer1 semantic zeros.

1. **Unified haptic surface** — one app-facing `platformHapticFeedback` API; deprecate L5 duplicates (#445).
2. **Real macOS L5 chrome** — `PlatformMacOSOptimizationsLayer5` with toolbar/sidebar/keyboard adapters (#451).
3. **macOS NavigationStack keyboard-first** — real L6 keyboard navigation (#446).
4. **Split/nav consolidation** — shared L5/L6 sidebar-sheet and overlay-detail chrome helpers (#447).
5. **FormLayoutDecision** — `selectFormStrategy_AddFuelView_L3` uses FormLayoutDecision instead of a hardcode (#397).
6. **Select-all on begin editing** — per-form opt-in across DynamicForm / L1 / IntelligentFormView (#472).
7. **Honesty / coverage** — move or remove 0% example Sources (#465); Layer1 semantic unit suites (#466); retire-script hygiene for local `done/` branches (#459).

---

## 🆕 Confirmed in v8.5.0 (implemented)

### **Unified haptics (#445)**

Primary View API: `View.platformHapticFeedback(_:)` / `PlatformHapticFeedback`, backed by `SixLayerHaptic.resolvedFeedback` + `SixLayerHaptic.trigger` (capability-gated). `platformIOSHapticFeedback` / `IOSHapticStyle` remain as deprecated thin wrappers.

### **PlatformMacOSOptimizationsLayer5 (#451)**

Real macOS L5 adapters for toolbar / sidebar / keyboard chrome (paired with stub-identity policy from earlier releases).

### **macOS NavigationStack L6 keyboard-first (#446)**

Keyboard-first navigation behavior on the macOS NavigationStack L6 path.

### **Split/nav L5/L6 consolidation (#447)**

Pure chrome decisions in `platformSidebarSheetChrome(for:)` / `platformOverlayDetailChrome(for:)`; L6 apply uses compile-time `#if os`. FormSelectAll parallel-safe AppKit hosting corrected (no suite serialization).

### **FormLayoutDecision for AddFuelView L3 (#397)**

`selectFormStrategy_AddFuelView_L3` consumes `FormLayoutDecision` instead of a hardcoded strategy.

### **Select all on begin editing (#472)**

Per-form opt-in so DynamicForm, L1, and IntelligentFormView can select field contents when editing begins.

### **Example/demo Sources honesty (#465)**

Obsolete `FormUsageExample` deleted. Platform UI/color/HIG/LiquidGlass examples moved to `Framework/Examples/`. Theming product APIs kept with unit-lane coverage.

### **Layer1 semantic unit coverage (#466)**

Unit suites for Security, Notification, Internationalization, OCR disambiguation, and DataFrame analysis L1 (release unit schemes execute them).

### **Retire-script local `done/` hygiene (#459)**

After retire, unused local `done/` branches are dropped; remotes keep history.

---

## ⚠️ Migration / consumer notes

### Deprecated iOS haptic wrappers (#445)

Prefer `platformHapticFeedback(_:)`. `platformIOSHapticFeedback` / `IOSHapticStyle` still compile but are deprecated.

### Example types moved (#465)

If you imported `PlatformUIExamples`, `PlatformColorExamples`, `AppleHIGComplianceExamples`, or `LiquidGlassExampleUsage` from the framework module, copy from `Framework/Examples/` instead — they are no longer in Sources.

### Not in this release

Coverage deepeners and remaining example zeros (#467–#470, #490, #491), datetime stack (#481), and secondary-platform hosts track later milestones (v8.6.0+ / Full Tests).

---

## ✅ Resolved GitHub issues (milestone v8.5.0)

- **[Issue #397](https://github.com/schatt/sixlayer/issues/397)** — `selectFormStrategy_AddFuelView_L3` should use FormLayoutDecision.
- **[Issue #445](https://github.com/schatt/sixlayer/issues/445)** — Unify iOS haptic APIs into one public surface.
- **[Issue #446](https://github.com/schatt/sixlayer/issues/446)** — macOS NavigationStack L6: real keyboard-first navigation.
- **[Issue #447](https://github.com/schatt/sixlayer/issues/447)** — Consolidate split-view and NavigationStack platform behavior in L5/L6 helpers.
- **[Issue #451](https://github.com/schatt/sixlayer/issues/451)** — Add `PlatformMacOSOptimizationsLayer5` with real toolbar/sidebar/keyboard adapters.
- **[Issue #459](https://github.com/schatt/sixlayer/issues/459)** — Drop unused local `done/` branches after retire; keep remotes.
- **[Issue #465](https://github.com/schatt/sixlayer/issues/465)** — Remove or cover Framework example/demo Sources (0% unit lane).
- **[Issue #466](https://github.com/schatt/sixlayer/issues/466)** — Unit-lane coverage: Layer1 semantic zeros.
- **[Issue #472](https://github.com/schatt/sixlayer/issues/472)** — Per-form opt-in: select all on begin editing.

---

## 📚 References

- [RELEASE_v8.4.0.md](RELEASE_v8.4.0.md) — Previous minor.
- [AI_AGENT_v8.5.0.md](AI_AGENT_v8.5.0.md) — Agent notes for this minor.
- [RELEASES.md](RELEASES.md) — Release history index.
