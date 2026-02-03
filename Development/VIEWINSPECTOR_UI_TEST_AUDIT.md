# ViewInspector → UI test coverage audit (issue #178)

**Date:** 2026-02-02  
**Purpose:** Map existing UI test coverage to the 120 failing ViewInspector tests (categories A–E). Gaps require backfill.

---

## UI test setup

- **Targets:** `SixLayerFrameworkRealUITests_iOS`, `SixLayerFrameworkRealUITests_macOS` (sources: `SixLayerFrameworkRealUITests/` + `SixLayerFrameworkUITests/` excluding TestApp).
- **App under test:** `SixLayerFrameworkTestApp_iOS` / `_macOS` (sources: `SixLayerFrameworkUITests/TestApp/`).
- **TestApp shows:** Navigation to test views (Control, Text, Button, Platform Picker, Basic Compliance) and Layer 1–3 example categories (Data Presentation, Navigation, Photos, Security, OCR, Notifications, Internationalization, Data Analysis, Barcode). No forms, no IntelligentDetailView, no collection-with-callbacks.

---

## Existing UI tests (by file)

| File | What it tests |
|------|----------------|
| AccessibilityUITests | Control (direct `.accessibilityIdentifier`), Text/Button (framework-generated ID), Platform Picker IDs |
| BasicAutomaticComplianceUITests | Basic compliance identifier/label findable, Text/Image compliance, identifier sanitization (spaces, special chars) |
| Layer1AccessibilityUITests | Per–Layer 1 category: identifiers, labels, VoiceOver, Switch Control (Data Presentation, Navigation, Photo, Security, OCR, Notifications, Intl, Data Analysis) |
| Layer2AccessibilityUITests | OCR layout example views: identifiers, labels, traits, VoiceOver, Switch Control |
| Layer3AccessibilityUITests | OCR strategy example views: identifiers, labels, traits, VoiceOver, Switch Control |
| AccessibilityValuesUITests | Stateful elements have values; toggle/slider state changes |
| AccessibilityTraitsUITests | Interactive elements have correct traits |
| AccessibilityHintsUITests | Interactive elements accessible with hints |
| DynamicTypeSupportUITests | Platform functions support dynamic type |
| HighContrastSupportUITests | Platform functions support high contrast |
| VoiceOverCompatibilityUITests | Platform functions VoiceOver compatible |
| SwitchControlCompatibilityUITests | Platform functions Switch Control compatible |
| DesignSystemUITests | (in RealUITests target; not in UITests folder listing—verify in pbxproj) |
| BarcodeScanningUITests | (in RealUITests target) |

---

## Gap analysis (triage categories)

### A. Cannot read accessibility identifier (~80+ VI failures)

| Coverage | Notes |
|----------|--------|
| **Partial** | Basic compliance, Layer 1 example views, control/text/button, and basic sanitization are covered by UI tests. |
| **Gap** | No UI coverage for: edge cases (empty string, special chars, very long names, manual override, disable/enable mid hierarchy, multiple screen contexts, exactNamed*, config changes, nested named, unicode); persistence (deterministic, stable, no timestamps, persist across config resets); generation verification (manual overrides automatic, global config); AutomaticAccessibilityIdentifierTests (view-level opt-out, clipboard, named component); AutomaticAccessibilityLabelTests; GlobalDisableLocalEnableTests; LocalEnableOverrideTests; and ConsolidatedAccessibilityTests duplicates of the above. |

**Action:** Add UI test screens + tests that exercise the same scenarios (e.g. view with manual ID, view with opt-out, global disable + local enable) and assert via XCUIElement that identifiers are present/absent as required.

---

### B. View hierarchy / no text elements (~20+ VI failures)

| Coverage | Notes |
|----------|--------|
| **None** | TestApp does not show IntelligentDetailView, custom field views, or view-generation flows. No UI tests assert “view contains text X” or “detail view shows title/subtitle”. |

**Action:** Add TestApp screen(s) that present IntelligentDetailView (and any other views VI can’t traverse). Add UI tests that assert visible content (labels, static text) so B behaviors are covered by UI instead of VI.

---

### C. Callback not invoked (4 VI failures)

| Coverage | Notes |
|----------|--------|
| **None** | TestApp has no form (IntelligentFormView) or collection-with-selection. No UI tests tap submit/cancel or list item and assert callback/state. |

**Action:** Add TestApp screen(s) with form (submit/cancel) and/or collection with selection. Add UI tests that tap and assert side effect (e.g. state change, navigation) so callback behavior is covered.

---

### D. OCR / hasStructure / hasInterface (~5 VI failures)

| Coverage | Notes |
|----------|--------|
| **Partial** | Layer1/2/3 UI tests cover OCR *identifiers* on example views. They do not drive camera/overlay or disambiguation UI or assert “alternatives shown / selection reflected”. |

**Action:** Add UI tests that drive OCR flows (camera/overlay, disambiguation, selection) and assert outcomes, or document that those flows are not testable in current TestApp and need dedicated screens.

---

### E. Other (~10 VI failures)

| Item | Coverage | Action |
|------|----------|--------|
| testPlainSwiftUIRequiresExplicitEnable | None | Add UI test: view with explicit enable, assert identifier present. |
| testUITestCodeClipboardGeneration | None | Add UI test or fix env; ensure clipboard tested. |
| testViewLevelOptOutDisablesAutomaticIDs | None | Add UI test: view with opt-out, assert no automatic ID. |
| testShouldCropImage_Odometer | N/A (logic) | Fix VI or product; ensure covered by unit/UI. |
| Other identifier readback duplicates | Same as A | Backfill per A. |

---

## Summary

- **A (identifiers):** Partial UI coverage; large gap for edge cases, persistence, verification, automatic ID/label, global/local config. Backfill needed.
- **B (view structure/content):** No UI coverage. Need TestApp screens + UI tests for IntelligentDetailView and any other “no text elements” views.
- **C (callbacks):** No UI coverage. Need form + collection screens and UI tests that tap and assert.
- **D (OCR):** Partial (identifiers only). Need UI tests for overlay/disambiguation flows.
- **E:** Mostly uncovered; one-offs as above.

**Next:** Backfill UI tests for A and B first (biggest gaps); then C, D, E. Track each of the 120 VI tests as “fixed in VI” or “covered by UI test [name]” until resolved.
