# SixLayer Framework v7.5.13 Release Documentation

**Release Date**: April 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.12  
**Status**: Released

---

## 🎯 Release Summary

Patch release following **v7.5.12**. Adds **Layer 4 modal sheet navigation chrome** ([Issue #223](https://github.com/schatt/sixlayer/issues/223)), **explicit dynamic form inline header visibility** and trimming ([Issue #224](https://github.com/schatt/sixlayer/issues/224)), and **optional toolbar accessibility identifiers** for form actions ([Issue #221](https://github.com/schatt/sixlayer/issues/221)). Strict TDD rules now require **deliberately red** evidence and, for issue-driven work, a **short red excerpt** on the GitHub issue (with timestamp).

---

## 🆕 What's New

### **Modal sheet navigation chrome (Issue #223)**

- **`platformModalSheetNavigationChrome_L4`**: Wraps sheet content in `platformNavigation_L4`, applies `platformNavigationTitle_L4` / `platformNavigationTitleDisplayMode_L4`, and trailing confirmation toolbar (`platformToolbarWithConfirmationAction`).
- **Leading toolbar overload**: Optional `leadingToolbar` (e.g. Reset) before confirmation.
- **Tests**: `PlatformModalSheetNavigationChromeLayer4Tests`.

### **Dynamic form header vs navigation title (Issue #224)**

- **`DynamicFormHeaderVisibility`**: `.visible` (default) vs `.hidden` so hosts can avoid duplicating `navigationTitle` with the form’s top title/description block.
- **`DynamicFormHeaderVisibility.resolvedInlineHeaderTexts`**: Trims title and description; whitespace-only or empty `description` does not reserve a subtitle row when visible.
- **`DynamicFormConfiguration.formHeaderVisibility`** carried through `applyingHints` and `FormBuilder.build`.
- **Tests**: `DynamicFormTests` + `DynamicFormViewTests` (hidden header).

### **platformFormToolbar optional accessibility identifiers (Issue #221)**

- Optional identifiers for Save/Cancel (and related) toolbar controls to support UI tests and accessibility.

### **Process / rules**

- **Strict TDD** (`.cursor/rules/strict-tdd-definition.mdc`, `MANDATORY_TESTING_RULES.md`): Deliberately red phase must prove tests detect failure; GitHub issue red log (excerpt + timestamp) when work maps to an issue.

---

## ✅ Migration (consumers)

- **Sheets with toolbars (iOS)**: Prefer `platformModalSheetNavigationChrome_L4` (or keep manual `platformNavigation_L4`) so Done/Apply appears in the nav bar.
- **Dynamic forms + `navigationTitle`**: Set `formHeaderVisibility: .hidden` when the bar owns the headline; use `description: nil` (not `""`) for no subtitle when the inline header is visible.
- **Managed settings adoption**: For migration from manual `selectedCategory` wiring to the managed shell, use `PlatformManagedSettingsTopLevelState` with `platformManagedSettingsTopLevel_L4` and follow the guide: [ManagedPlatformSettingsFlowGuide.md](../Framework/docs/ManagedPlatformSettingsFlowGuide.md). For a compile-checked composition example (including Layer 1 sidebar usage), see `Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation/ManagedPlatformSettingsFlowGuideExampleTests.swift`.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.12.md](RELEASE_v7.5.12.md) — Previous patch (v7.5.12)
