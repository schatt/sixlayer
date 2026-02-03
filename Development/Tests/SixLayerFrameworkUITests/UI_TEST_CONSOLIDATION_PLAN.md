# UI Test Consolidation Plan: One Launch Instead of 11

**Goal:** Cut iOS UI test time from ~10 min to ~1–2 min by using **one app launch** and one test class (or two) instead of 11 classes × 11 launches.

**Highest impact:** Eliminate 10 of 11 launches (~5–8 minutes saved).

---

## Current State

- **11 test classes**, each with `setUpWithError` → `launchWithOptimizations()` → `waitForReady(5.0)`.
- **33 test methods** across those classes.
- TestApp: launch page with sections (Accessibility Tests buttons, L1 toggle, L2/L3/L4/L5/L6 links). Tapping a button/link pushes a new screen or replaces content.

---

## Target State

- **1 test class** (or 2 if we want a small split): one launch in `setUp`, all test methods run in the same app run.
- **Same 33 tests** (or equivalent coverage), implemented as methods that navigate to the required screen then assert.
- **No TestApp changes required for Phase 1**; we only change test structure.

---

## Phase 1: Consolidate Test Classes (No TestApp Changes)

### Step 1: Add one consolidated test class

- **File:** `ConsolidatedAccessibilityUITests.swift` (or rename existing `AccessibilityCompatibilityUITests` and expand it).
- **setUp:** Same as today: one `XCUIApplication()`, `launchWithOptimizations()`, `waitForReady(5.0)`. Single launch for the whole run.
- **tearDown:** `app = nil`.
- **UI interruption monitor:** Same as current classes (dismiss system dialogs).

### Step 2: Add navigation helpers

So each test can run in any order, each method ensures it’s on the right screen before asserting:

- `navigateToLaunchPage()` – tap back until navigation title is "UI Test Views" (or tap a known “back” / “main” control).
- `navigateToLayer2()` – from launch, tap "Layer 2 Layout Examples"; wait for "Layer 2 Examples" title.
- `navigateToLayer3()` – from launch, tap "Layer 3 Strategy Examples"; wait for "Layer 3 Examples" title.
- `navigateToTestView(_ testView: TestView)` – from launch, tap the corresponding "test-view-…" entry (e.g. Control Test, Button Test).
- `expandLayer1IfNeeded()` – from launch, tap "Show Layer 1 Examples" if needed, scroll to picker, wait for category picker (reuse current helper logic).

Reuse existing helpers from `Layer1AccessibilityUITests`, `Layer2AccessibilityUITests`, `Layer3AccessibilityUITests`, `XCUITestHelpers` (e.g. `findLaunchPageEntry`, `findElement(byIdentifier:…)`).

### Step 3: Move test logic into the consolidated class

- **L1 (1 method):** `testLayer1Examples_AccessibilityIdentifiersLabelsAndTraits` – start with `expandLayer1IfNeeded()`, then current L1 category loop and asserts (from `Layer1AccessibilityUITests`).
- **L2 (5 methods):** Start each with `navigateToLayer2()`, then current L2 asserts (identifiers, labels, traits, VoiceOver, Switch Control).
- **L3 (5 methods):** Start each with `navigateToLayer3()`, then current L3 asserts.
- **Accessibility (4 methods):** Control, Text, Button, Platform Picker – each starts with `navigateToTestView(.control)` etc., then current asserts from `AccessibilityUITests`.
- **BasicCompliance (7 methods):** Each navigates to the needed test view (Basic Compliance, or the view used for that test), then current asserts from `BasicAutomaticComplianceUITests`.
- **ViewInspectorBackfill (2 methods):** Navigate to Identifier Edge Case and Detail View Test, then current asserts.
- **Compatibility (4 methods):** VoiceOver, Dynamic Type, High Contrast, Switch Control – run on launch page (or one chosen screen); keep current logic from `AccessibilityCompatibilityUITests`.
- **Values (3 methods):** Navigate as needed, then current logic from `AccessibilityValuesUITests`.
- **Traits (1 method):** From `AccessibilityTraitsUITests`.
- **Hints (1 method):** From `AccessibilityHintsUITests`.

Name methods so it’s clear which area they cover (e.g. `testLayer1_AccessibilityIdentifiersLabelsAndTraits`, `testLayer2_AccessibilityIdentifiers`, …). No need to force execution order if every method navigates to the screen it needs first.

### Step 4: Remove or disable the 11 old classes

- **Option A:** Delete the 11 old test class files. The target then has only the consolidated class. **Recommended** once the consolidated run is green.
- **Option B:** Keep the files but remove the test methods (or mark them `@available(*, unavailable)` / rename so they don’t run). Use only if you want to keep the old structure visible during transition.

### Step 5: Verify and commit

- Run the iOS UI test target; all tests should pass with **one launch**.
- Commit in small steps (e.g. add consolidated class + helpers, then migrate one group of tests at a time, then remove old classes), so each step is green and reviewable.

---

## Phase 2 (Optional): Reorganize TestApp

- **Single “Accessibility” page:** One screen that shows all 7 test views (Control, Text, Button, Picker, Basic Compliance, Identifier Edge Case, Detail View) as sections or tabs so tests don’t need to go back to launch and tap a new button for each. Reduces navigation and can shorten runs a bit more.
- **L1 page:** Move L1 content to a dedicated “L1 Examples” destination (like L2/L3) if that simplifies navigation or layout; not required for consolidation.

---

## Risks and Mitigations

- **Flakiness:** One long run with many navigations can be more flaky. Mitigation: keep `waitForReady` and element waits; use navigation helpers that wait for a visible title or element before asserting.
- **Debugging:** A failure in the middle is in one big class. Mitigation: clear method names and MARK sections (e.g. `// MARK: - Layer 2`); consider `continueAfterFailure = true` only for local debugging if you want to see multiple failures in one run.
- **Merge conflicts:** Doing the consolidation on a branch and merging once green keeps main stable.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Add one test class with single launch in `setUp`. |
| 2 | Add navigation helpers (launch, L2, L3, test view, L1 expand). |
| 3 | Move all 33 test methods into that class; each method navigates to the right screen first. |
| 4 | Remove (or disable) the 11 old test classes. |
| 5 | Run iOS UI tests; confirm one launch and ~1–2 min total runtime. |

No TestApp changes are required for Phase 1; only test code and file layout change.
