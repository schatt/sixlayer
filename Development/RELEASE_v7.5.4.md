# SixLayer Framework v7.5.4 Release Documentation

**Release Date**: February 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.3  
**Status**: In preparation

---

## 🎯 Release Summary

Patch release with optional injected state for `FormWizardView` and `DynamicFormView`, `platformTextEditor(text:)` drop-in, concurrency and test stability fixes, and release/rule documentation updates.

---

## 🆕 What's New

### **Optional injected wizard state (Issue #187)**
- **FormWizardView** and **FormWizardStateEnvironmentKey**: Optional `wizardState` can be injected via environment for testing and previews.
- **FormWizardStateEnvironmentKey** made concurrency-safe with `nonisolated(unsafe)` and `FormWizardStateEnvironmentKey` Swift 6 isolation fix.
- **FormWizardViewInner** and **FormWizardView** are `ViewInspector.Inspectable` for TDD.

### **Optional injected form state and OCR image on photo field (Issues #186, #185)**
- **DynamicFormState** environment key for optional injected `formState`.
- **DynamicFormViewInner** is internal and `ViewInspector.Inspectable` for tests.
- Submit includes image when image field is set; batch OCR image stored on photo field.

### **platformTextEditor(text:) strict drop-in (Issue #164)**
- Added **platformTextEditor(text:)** strict drop-in overload for `TextEditor(text:)`.
- **PlatformDropInReplacementAudit.md** added for tracking drop-in status.

---

## 🔧 What's Fixed

### **Test and build stability**
- **testUserDefaultsStorageClear**: Use unique suite name for parallel safety.
- **testGetCardExpansionPlatformConfig_AllPlatforms**: `setTestHover(false)` for deterministic hoverDelay.
- **testGetCardExpansionPlatformConfig_iOS**: Set capability overrides for deterministic parallel run.
- **iOS a11y**: Longer run loop and ViewInspector deep ID search when platform returns nil; extra run loop and layout when forceLayout so a11y IDs propagate.
- **testFormWizardViewProvidesNavigationControls**: Match by label or a11y ID.
- **FormWizardView TDD**: Relax injected-state assertion for ViewInspector env propagation; use `withInspectedView`; make inner view internal for ViewInspector traversal.
- **DynamicFormView tests**: Use `withInspectedView` and `findAll(Button)` to find and tap Submit; use AnyView wrapper for inspection when view has environment modifier; assert only when submit ran.
- **macOS build**: Use `platformNavigationTitleDisplayMode_L4` in TestApp.

### **Release and rule documentation**
- Default test target set to **iOS_tests** for day-to-day testing; release script runs full suite (macOS + iOS).
- **commit-before-test** and **test-target-default** rules updated; release quality gate clarified (enforced by release script, not agent).

---

## ✅ Backward Compatibility

**Fully backward compatible** — optional environment injection and new overloads only; no breaking API changes.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [PlatformDropInReplacementAudit.md](../Framework/docs/PlatformDropInReplacementAudit.md) — Drop-in replacement audit (Issue #164)
