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

Framework-owned form surfaces now resolve preferred field width and pack/align controls from `FieldDisplayHints` instead of ignoring or hard-coding layout:

- Width resolution: numeric → named band (platform table) → `expectedLength` × font metrics → flex; always `min(preferred, availableWidth)`.
- Pack preserves author order; same-type runs; tall/wideFlex isolated; checkbox/toggle stay intrinsic within claim.
- Size is the field slot; controls do not stretch beyond claim when marked intrinsic.
- `PresentationHints.fieldHints[id]` wins over field `displayHints` when both are present.
- Shared production path: `FieldLayoutPackedSection.plan` (+ `packedFormControlLeadingInset`, currently 0 for label-above).
- Surfaces wired: DynamicForm, IntelligentForm, GenericForm/ModalForm (including DataField / CustomFieldView paths).
- APIs: `FieldDisplayWidthResolver`, `FieldLayoutPacker`, `FieldLayoutAligner`, `FieldLayoutPackedSection` / `FieldLayoutPackedSectionPlan`, `FieldLayoutControlSizing`, `PresentationHints.resolvedFieldDisplayHints`, plus layout-pack bridges on `DynamicFormField` / `DataField`.
- Docs: FieldHintsGuide / FieldHintsCompleteGuide / AI_AGENT_v4.8.0 named width bands aligned to the platform table.

### **PlatformPresentationSize (#384, #386)**

- Introduces unified cross-platform presentation sizing via `PlatformPresentationSize` (`.small` / `.medium` / `.large` / `.exact(width:height:)`).
- Wired through L4 sheets/popovers, extension sheets, UIPatterns, and Layer 3 modal layout decisions.
- Follow-up (#386) routes remaining hard-coded 400×300-style frames through the shared API so sheet/popover chrome stays consistent.

### **Toolbar overflow Menu (#352)**

- Completes space-aware toolbar action packing: overflow path in `PlatformToolbarActionsChrome` uses `platformMenu` (SwiftUI `Menu` on iOS).
- Adds ViewInspector coverage for toolbar packing overflow Menu so packing behavior is observed without relying only on XCUI.

### **UITest / TestKit MainActor (#387)**

- Clears Swift 6 / Xcode MainActor isolation and deprecation warnings in TestApp hosts, SixLayerFrameworkUITests, and SixLayerTestKit.
- Applies `@MainActor` / `MainActor.assumeIsolated` for XCUI setUp/tearDown and TestKit navigators/resolvers.
- Keeps production API unchanged; scope is test/host compile hygiene.

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
