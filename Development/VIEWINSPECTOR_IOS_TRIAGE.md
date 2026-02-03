# ViewInspector iOS Test Failures – Triage

**Canonical source:** [GitHub issue #178](https://github.com/schatt/sixlayer/issues/178) — triage and policy are posted there; this file is a local copy for reference.

**Run date:** 2026-02-02  
**Target:** SLF-iOS-ViewInspectorTests  
**Result:** 1896 tests, **187 issues** across **120 unique failing tests**

---

## Testing policy (mandatory)

**Chain:** Unit → ViewInspector → UI/xctest.

- If **unit tests** cannot test something, it is tested via **ViewInspector**.
- If **ViewInspector** cannot test something (e.g. readback or traversal fails on iOS), it **must** be tested via **UI tests** (xcuitest).
- **At no point is "can't test, relax" acceptable.** Every aspect of the framework must be tested somewhere.

So: for every failing ViewInspector test that cannot be fixed (e.g. because VI cannot read identifiers or traverse the hierarchy on iOS), we must **add or verify UI test coverage** for that behavior. No exceptions.

---

## Summary by category

| Category | What VI can't do (iOS) | Count (approx) | Required action |
|----------|------------------------|----------------|-----------------|
| A. Cannot read accessibility identifier | Read back `.accessibilityIdentifier()` | ~80+ | Add/verify UI tests that assert identifiers (e.g. `XCUIElement` by `accessibilityIdentifier`) |
| B. View hierarchy / no text elements | Traverse to find Text/structure | ~20+ | Add/verify UI tests that assert content (labels, text, hierarchy) |
| C. Callback not invoked (tap/simulation) | Reliably trigger callbacks via tap | 4 | Fix VI tap or add UI tests that tap and assert callback/state |
| D. OCR / hasStructure / hasInterface | See structure of OCR/overlay views | ~5 | Add UI tests that drive OCR flows and assert outcomes |
| E. Other (clipboard, config, one-off) | Mixed | ~10 | Per case: fix VI or add UI test |

---

## A. Inspection unavailable: could not obtain accessibility identifier

**What’s happening:** ViewInspector on iOS often cannot read back `.accessibilityIdentifier()` from the SwiftUI hierarchy. Tests that set identifiers and assert by inspecting get nil/failure.

**Affected suites (examples):**
- AccessibilityIdentifierEdgeCaseTests (e.g. `testEmptyStringParameters`, `testSpecialCharactersInNames`, `testManualIDOverride`, `testNestedNamedCalls`, `testUnicodeCharacters`)
- AccessibilityIdentifierPersistenceTests ("Failed to generate ID for view")
- AccessibilityIdentifierGenerationVerificationTests
- AutomaticAccessibilityIdentifierTests (e.g. `testAutomaticAccessibilityIdentifiersWithNamedComponent`)
- Many in ConsolidatedAccessibilityTests that duplicate the above

**Required action:**
- For each behavior that *must* be verified (identifiers present, stable, semantic, edge cases): **add or verify UI tests** that launch the app, build the same views, and assert via `XCUITest` (e.g. `app.buttons["expectedIdentifier"]`, or query by `accessibilityIdentifier`) that the identifiers are present and correct.
- Optionally keep the ViewInspector tests on **macOS** only (where readback works) as additional coverage; iOS coverage for identifier behavior is then provided by UI tests.

---

## B. View inspection returned no text elements / View inspection not available

**What’s happening:** ViewInspector cannot traverse the hierarchy to find `Text` or expected structure in some views (e.g. `IntelligentDetailView`, custom containers).

**Affected tests (examples):**
- ViewGenerationTests: `testIntelligentDetailViewGeneration`, `testIntelligentDetailViewWithCustomFieldView`, `testIntelligentDetailViewWithHints`
- View Generation Verification: `testIntelligentDetailViewGeneratesProperStructure`, `testIntelligentDetailViewWithDifferentHints`, `testIntelligentDetailViewWithCustomFieldView`, `testIntelligentDetailViewWithNilValues`
- BaseTestClass-based checks using `verifyViewContainsText` that get "View inspection returned no text elements"

**Required action:**
- For each behavior (detail view content, layout strategy, custom field view, nil handling): **add or verify UI tests** that display the same views and assert content is present (e.g. by accessibility label, static text, or visible hierarchy). No behavior should be left untested because VI can’t traverse on iOS.

---

## C. Callback not invoked (tap / submit simulation)

**What’s happening:** Tests simulate tap or form submit and expect a callback; the callback is not invoked (ViewInspector tap/simulation may not trigger on iOS).

**Affected tests:**
- `FormCallbackFunctionalTests`: `testIntelligentFormViewOnCancelCallbackInvoked`, `testIntelligentFormViewOnUpdateCallbackInvoked`
- `IntelligentFormViewTests`: `testUpdateButtonCallsOnSubmitWhenProvided`, `testUpdateButtonDoesNothingWhenOnSubmitIsEmpty`
- `CollectionViewCallbackTests`: `testListCollectionViewOnItemSelectedCallback`
- `Layer1CallbackFunctionalTests`: `testPlatformPresentItemCollectionL1WithEnhancedHintsCallbacks`

**Required action:**
- **Option 1:** Fix ViewInspector test (e.g. trigger action programmatically and assert on state instead of relying on simulated tap).
- **Option 2:** Add **UI tests** that perform the real tap/submit in the running app and assert that the callback effect occurs (e.g. state change, navigation, or side effect). All four behaviors must be covered by VI or UI.

---

## D. OCR / hasStructure / hasInterface

**What’s happening:** ViewInspector cannot see the structure or “interface” of OCR overlay / disambiguation views.

**Affected tests (examples):**
- OCRComponentsTDDTests: `testOCROverlayViewRendersCameraInterface`, `testOCROverlayViewProcessesImageWithOCR`, `testOCRDisambiguationViewRendersDisambiguationUI`, `testOCRDisambiguationViewDisplaysAllAlternatives`, `testOCRDisambiguationViewHandlesNoDisambiguationNeeded`
- OCRDisambiguationTests: `testOCRDisambiguationViewRendersAlternativesAndHandlesSelection`, `testOCRDisambiguationViewShowsConfidenceLevels`

**Required action:**
- **Add UI tests** that drive the OCR flows (camera/overlay, disambiguation, selection) and assert outcomes (e.g. alternatives shown, selection reflected). ViewInspector cannot be the only coverage for these; UI tests are required where VI cannot see the structure.

---

## E. Other (one-off or mixed)

- **testPlainSwiftUIRequiresExplicitEnable**: Add UI test that verifies explicit-enable behavior (e.g. identifier present when enabled).
- **testUITestCodeClipboardGeneration**: Add UI test or fix environment (clipboard in test runner); ensure clipboard behavior is tested somewhere.
- **testViewLevelOptOutDisablesAutomaticIDs**: Same as A — add UI test that verifies no automatic ID when disabled.
- **testShouldCropImage_Odometer**: Fix test expectation or product logic; then ensure cropping behavior is covered by unit or UI test.
- **testAccessibilityEnhancedViewModifier**, **testManualIDOverride**, **testMultipleScreenContexts**, etc.: Identifier readback — add/verify UI tests for these behaviors (same as A).

---

## Required next steps (no “relax” options)

1. **Audit UI test targets**  
   Identify which behaviors already have UI test coverage (e.g. SLF-iOS-UITests, SLF-macOS-UITests) and which do not.

2. **Backfill UI tests for A and B**  
   For every identifier and view-structure behavior that ViewInspector cannot assert on iOS: add or extend UI tests that assert the same contract (identifiers present, content visible, structure correct).

3. **Callbacks (C)**  
   Either fix the ViewInspector tests (programmatic trigger + state assertion) or add UI tests that tap/submit and assert callback behavior. All four must be covered.

4. **OCR / structure (D)**  
   Add UI tests for OCR overlay, disambiguation, and selection so that coverage does not depend on ViewInspector being able to see those views.

5. **E (one-offs)**  
   For each: fix the VI test or add a UI test; no behavior left untested.

6. **Tracking**  
   Maintain a checklist (e.g. in this doc or a TODO) mapping each failing VI test to either “fixed in VI” or “covered by UI test [name]” until the 120 failures are resolved by real coverage.

---

## Unique failing test count (for tracking)

- **120** unique test names fail (some record multiple issues).
- **187** total issues in the run.
- Resolution = either fix the ViewInspector test on iOS or add/verify UI test coverage for that behavior. No “inconclusive” or “relax” outcome.
