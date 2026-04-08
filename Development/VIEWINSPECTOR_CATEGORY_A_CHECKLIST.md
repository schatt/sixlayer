# Category A checklist — accessibility identifier readback (issue #197)

**Purpose:** Concrete inventory of ViewInspector tests that fail on iOS when `.accessibilityIdentifier()` readback is unavailable (“Inspection unavailable: could not obtain accessibility identifier”), and tracking of how each is satisfied without leaving behavior untested.

**Policy reference:** `Development/VIEWINSPECTOR_IOS_TRIAGE.md` (Category A), `Development/VIEWINSPECTOR_UI_TEST_AUDIT.md`.

---

## Tight acceptance criteria (issue #197)

1. **Every row** in the [Canonical inventory](#canonical-inventory) below has exactly one **Resolution** (same column semantics in exported tables):
   - **`UI:<XCUITestClass>/<testName>`** — behavior covered by a named XCUITest (or subtest) that asserts identifier presence/absence via `XCUIElement`.
   - **`VI-iOS`** — ViewInspector readback fixed on iOS for that test; test passes on `SLF-iOS-ViewInspectorTests` without soft-failing on missing identifier.
   - **`Dedup:<Suite>/<testName>`** — satisfied solely because it is the same scenario as another row (document the canonical row).
   - **`Excluded:<short reason> | Owner:<github handle>`** — intentionally not covered by UI/VI (e.g. macOS-only, non-runtime contract). **Owner is mandatory.**

2. **`ConsolidatedAccessibilityTests.swift`:** Every `@Test` in that file MUST appear in the [Consolidated deduplication](#consolidatedaccessibilitytests-deduplication) section with one of:
   - **`Dedup`** → a canonical row below, **or**
   - its **own** `UI` / `VI-iOS` / `Excluded` line (same rules as (1)).

3. **No waiver language:** Phrases like “where feasible” do **not** apply. If a test is in the inventory, it gets one of the four resolutions above.

4. **Branch / merge:** Work may land on a release branch first; merge to `main` is part of release. Close #197 when (1)–(2) are satisfied on the branch that contains the checklist updates.

---

## Resolution column (fill as work proceeds)

| Value | Meaning |
|--------|--------|
| *(empty)* | Not done |
| `UI:…` | Named XCUITest covers the contract |
| `VI-iOS` | Fixed in ViewInspector on iOS |
| `Dedup:…` | Same as another listed test |
| `Excluded:… \| Owner:@…` | Documented opt-out with owner |

---

## Canonical inventory

Source files under `Development/Tests/SixLayerFrameworkUnitTests/ViewInspectorTests/` unless noted.

### `Features/Accessibility/AccessibilityIdentifierEdgeCaseTests.swift`

| Test | Resolution |
|------|------------|
| `testEmptyStringParameters` | |
| `testSpecialCharactersInNames` | |
| `testVeryLongNames` | |
| `testDisableEnableMidHierarchy` | |
| `testMultipleScreenContexts` | |
| `testExactNamedBehavior` | |
| `testExactNamedVsNamedDifference` | |
| `testExactNamedIgnoresHierarchy` | |
| `testExactNamedMinimalIdentifier` | |
| `testConfigurationChangesMidTest` | |
| `testNestedNamedCalls` | |
| `testUnicodeCharacters` | |

### `Features/Accessibility/AccessibilityIdentifierPersistenceTests.swift`

| Test | Resolution |
|------|------------|
| `testAccessibilityIdentifiersArePersistentAcrossSessions` | |
| `testAccessibilityIdentifiersAreDeterministicForSameView` | |
| `testAccessibilityIdentifiersDontContainTimestamps` | |
| `testAccessibilityIdentifiersAreStableForUITesting` | |
| `testAccessibilityIdentifiersAreBasedOnViewStructure` | |
| `testAccessibilityIdentifiersAreTrulyPersistentForIdenticalViews` | |
| `testAccessibilityIdentifiersPersistAcrossConfigResets` | |

### `Features/Accessibility/AccessibilityIdentifierGenerationVerificationTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticAccessibilityIdentifiersActuallyGenerateIDs` | |
| `testNamedActuallyGeneratesIdentifiers` | |
| `testAutomaticAccessibilityIdentifiersActuallyGenerateIdentifiers` | |
| `testManualIdentifiersOverrideAutomaticGeneration` | |
| `testGlobalConfigActuallyControlsIdentifierGeneration` | |

### `Features/Accessibility/AutomaticAccessibilityIdentifierTests.swift`

| Test | Resolution |
|------|------------|
| `testGlobalConfigControlsAutomaticIdentifiers` | |
| `testGlobalConfigSupportsCustomNamespace` | |
| `testGlobalConfigSupportsGenerationModes` | |
| `testAutomaticIDGeneratorCreatesStableIdentifiers` | |
| `testAutomaticIDGeneratorHandlesDifferentRolesAndContexts` | |
| `testAutomaticIDGeneratorHandlesNonIdentifiableObjects` | |
| `testManualAccessibilityIdentifiersOverrideAutomatic` | |
| `testViewLevelOptOutDisablesAutomaticIDs` | |
| `testAutomaticIdentifiersIntegrateWithHIGCompliance` | |
| `testLayer1FunctionsIncludeAutomaticIdentifiers` | |
| `testCollisionDetectionIdentifiesConflicts` | |
| `testDebugLoggingCapturesGeneratedIDs` | |
| `testDebugLoggingDisabledWhenTurnedOff` | |
| `testDebugLogFormatting` | |
| `testDebugLogClearing` | |
| `testViewHierarchyTracking` | |
| `testUITestCodeGeneration` | |
| `testUITestHelpers` | |
| `testUITestCodeFileGeneration` | |
| `testUITestCodeClipboardGeneration` | |
| `testTrackViewHierarchyAutomaticallyAppliesAccessibilityIdentifiers` | |
| `testGlobalAutomaticAccessibilityIdentifiersWork` | |
| `testIDGenerationUsesActualViewContext` | |
| `testAutomaticAccessibilityIdentifiersWithNamedComponent` | |

### `Core/Architecture/GlobalDisableLocalEnableTests.swift`

| Test | Resolution |
|------|------------|
| `testFrameworkComponentGlobalDisableLocalEnableGeneratesID` | |
| `testGlobalEnableLocalDisableDoesNotGenerateID` | |
| `testFrameworkComponentsRespectGlobalConfig` | |
| `testPlainSwiftUIRequiresExplicitEnable` | |

### `Layers/LocalEnableOverrideTests.swift`

| Test | Resolution |
|------|------------|
| `testGlobalDisableLocalEnable` | |
| `testNamedModifierAlwaysWorksRegardlessOfGlobalSettings` | |
| `testNamedModifierAlwaysWorksEvenWhenGlobalConfigDisabled` | |

### `Features/Accessibility/AutomaticAccessibilityLabelViewInspectorTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticCompliance_AppliesAccessibilityLabel_WhenProvided` | |
| `testAutomaticCompliance_WorksWithoutAccessibilityLabel` | |
| `testAutomaticComplianceNamed_AppliesAccessibilityLabel_WhenProvided` | |
| `testAutomaticComplianceNamed_WorksWithoutAccessibilityLabel` | |
| `testPlatformButton_AppliesAccessibilityLabel` | |
| `testPlatformButton_AutoExtractsLabelFromParameter` | |
| `testLabelFormatting_ThroughViewInspector` | |
| `testAutomaticCompliance_DoesNotApplyEmptyLabel` | |
| `testAutomaticCompliance_HandlesNilLabel` | |

### `Features/Accessibility/AccessibilityIdentifierDisabledTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticIDsDisabled_NoIdentifiersGenerated` | |
| `testManualIDsStillWorkWhenAutomaticDisabled` | |
| `testBreadcrumbModifiersStillWorkWhenAutomaticDisabled` | |

### `Features/Accessibility/AccessibilityIdentifierGenerationTests.swift`

| Test | Resolution |
|------|------------|
| `testAccessibilityIdentifiersAreReasonableLength` | |
| `testAccessibilityIdentifiersDontDuplicateHierarchy` | |
| `testAccessibilityIdentifiersAreSemantic` | |
| `testAccessibilityIdentifiersWorkInComplexHierarchy` | |
| `testAccessibilityIdentifiersIncludeLabelTextForStringLabels` | |
| `testAccessibilityIdentifiersSanitizeLabelText` | |

### `Features/Accessibility/AccessibilityIdentifiersDebugTests.swift`

| Test | Resolution |
|------|------------|
| `testDirectAutomaticAccessibilityIdentifiersWorks` | |
| `testNamedModifierWorks` | |
| `testAutomaticAccessibilityModifierWorks` | |
| `testAutomaticAccessibilityExtensionWorks` | |

### `Features/Accessibility/AccessibilityIdentifierConfigUserDefaultsTests.swift`

| Test | Resolution |
|------|------------|
| `testSaveToUserDefaultsSavesConfiguration` | |
| `testLoadFromUserDefaultsLoadsConfiguration` | |
| `testLoadFromUserDefaultsRespectsDefaultsWhenNoSavedConfig` | |
| `testConfigurationPersistenceAcrossAppLaunches` | |
| `testSaveToUserDefaultsSavesAllProperties` | |
| `testLoadFromUserDefaultsOnlyLoadsIfKeyExists` | |

**Total canonical `@Test` rows:** 83

---

## `ConsolidatedAccessibilityTests.swift` deduplication

This file aggregates many scenarios; several duplicate the suites above.

**Rule:** For each `@Test` method in `ConsolidatedAccessibilityTests.swift`, add a row here OR mark `Dedup` to a canonical test above.

| Consolidated test | Resolution |
|-------------------|------------|
| *(add rows as dedup work proceeds; optional: generate with `rg '@Test.*func test' ConsolidatedAccessibilityTests.swift`)* | |

**Mechanical export (for paste into this table):**

```bash
rg "@Test.*func (test\\w+)" Development/Tests/SixLayerFrameworkUnitTests/ViewInspectorTests/Features/Accessibility/ConsolidatedAccessibilityTests.swift -o --replace '$1' | sort -u
```

---

## Out of scope for #197 (by design)

- **`Development/Tests/SixLayerFrameworkUnitTests/Features/Accessibility/AutomaticAccessibilityLabelTests.swift`** — pure formatting/localization unit tests without ViewInspector identifier readback; do **not** list here unless a specific method is tied to an iOS VI identifier failure.
- **Category B–E** failures — tracked under other issues / audit sections, not this checklist.

---

## Related UI test files (existing partial coverage)

Examples: `AccessibilityIdentifierCategoryAUITests.swift`, `AccessibilityIdentifierCategoryAGlobalOffUITests.swift`, `ManualAccessibilityIdentifierHarnessUITests.swift`, `BasicAutomaticComplianceUITests.swift`. Reference these in `UI:…` cells when they cover a canonical row.
