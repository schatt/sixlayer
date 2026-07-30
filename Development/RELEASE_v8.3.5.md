# SixLayer Framework v8.3.5 Release Documentation

**Release Date**: July 30, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.4  
**Status**: Released

---

## 🎯 Release Summary

v8.3.5 is a **patch** release focused on:

1. **Form field layout** — framework-owned layouts honor `FieldDisplayHints` for preferred width, packing, and column alignment across DynamicForm, IntelligentForm, and GenericForm/ModalForm ([#385](https://github.com/schatt/sixlayer/issues/385)).
2. **Presentation sizing** — `PlatformPresentationSize` for cross-platform sheet/popover sizing, with remaining hard-coded frames routed through it ([#384](https://github.com/schatt/sixlayer/issues/384), [#386](https://github.com/schatt/sixlayer/issues/386)).
3. **Toolbar overflow Menu** — `PlatformToolbarActionsChrome` overflow uses `platformMenu`, with ViewInspector coverage ([#352](https://github.com/schatt/sixlayer/issues/352)).
4. **UITest MainActor hygiene** — TestKit / XCUI setUp-tearDown MainActor isolation and related deprecation warning cleanup ([#387](https://github.com/schatt/sixlayer/issues/387)).

---

## 🆕 Confirmed in v8.3.5 (implemented)

### **FieldDisplayHints layout (#385)**

- Width resolution: numeric → named band (platform table) → `expectedLength` × font metrics → flex; always `min(preferred, availableWidth)`.
- Pack preserves author order; same-type runs; tall/wideFlex isolated; checkbox/toggle stay intrinsic within claim.
- `PresentationHints.fieldHints[id]` wins over field `displayHints`.
- Shared production path: `FieldLayoutPackedSection.plan` (+ `packedFormControlLeadingInset`).
- APIs: `FieldDisplayWidthResolver`, `FieldLayoutPacker`, `FieldLayoutAligner`, `FieldLayoutPackedSection` / `FieldLayoutPackedSectionPlan`, `FieldLayoutControlSizing`, `PresentationHints.resolvedFieldDisplayHints`.

### **PlatformPresentationSize (#384, #386)**

- Cross-platform sheet/popover sizing via `PlatformPresentationSize`.
- Remaining 400×300-style hard-coded frames routed through the shared API.

### **Toolbar overflow Menu (#352)**

- Overflow path in `PlatformToolbarActionsChrome` wired through `platformMenu`.
- ViewInspector coverage for toolbar packing overflow Menu.

### **UITest / TestKit MainActor (#387)**

- `@MainActor` / `MainActor.assumeIsolated` for XCUI setUp/tearDown and TestKit navigators/resolvers.
- Related compile/deprecation cleanup in the UITest lane.

---

## ✅ Resolved GitHub issues (v8.3.5)

- **[Issue #385](https://github.com/schatt/sixlayer/issues/385)** — Form field layout honors `FieldDisplayHints` (width, pack, align).
- **[Issue #384](https://github.com/schatt/sixlayer/issues/384)** — `PlatformPresentationSize` for sheet/popover sizing.
- **[Issue #386](https://github.com/schatt/sixlayer/issues/386)** — Route remaining hard-coded frames through `PlatformPresentationSize`.
- **[Issue #387](https://github.com/schatt/sixlayer/issues/387)** — UITest/TestKit MainActor isolation and deprecation warnings.
- **[Issue #352](https://github.com/schatt/sixlayer/issues/352)** — Space-aware toolbar action packing (overflow Menu via `platformMenu`; VI coverage).
- **[Issue #391](https://github.com/schatt/sixlayer/issues/391)** — Prepare v8.3.5 release (docs / `--docs`).

---

## ⚠️ Migration / consumer notes

- **Forms:** Prefer `FieldDisplayHints` / presentation `fieldHints` for width and packing; `displayWidth == nil` is not treated as medium. `maxLength` remains validation-only (not a layout max-width).
- **Sheets / popovers:** Prefer `PlatformPresentationSize` (and related detent helpers) instead of raw hard-coded frame sizes.
- **SPM consumers** may bump to **v8.3.5** for field-layout and presentation-size behavior.

---

## 📚 References

- [RELEASE_v8.3.4.md](RELEASE_v8.3.4.md) — Previous patch (XCUI reliability / Vision hang footguns).
- [RELEASES.md](RELEASES.md) — Release history index.
- [FieldHintsGuide](../Framework/docs/FieldHintsGuide.md) / [FieldHintsCompleteGuide](../Framework/docs/FieldHintsCompleteGuide.md) — width bands and packing docs.
