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

2. **`ConsolidatedAccessibilityTests.swift`:** Every `@Test` in that file MUST appear in the [Consolidated deduplication](#consolidatedaccessibilitytests-deduplication) inventory ([`VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md`](VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md)) with one of:
   - **`Dedup`** → a canonical row below (or another ViewInspector source named in the generated table), **or**
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
| `testEmptyStringParameters` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_emptyIdentifierName_sanitizedLabelInIdentifier` |
| `testSpecialCharactersInNames` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_specialCharsInLabel_hasIdentifier` |
| `testVeryLongNames` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_longIdentifierName_hasStablePrefixInIdentifier` |
| `testDisableEnableMidHierarchy` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_disableAutomatic_localSubtree_skipsBasicAutomaticIdentifier` |
| `testMultipleScreenContexts` | `Excluded: hosted stack / screen context; no Category A runtime row — Owner:@schatt` |
| `testExactNamedBehavior` | Excluded: asserts ExactNamedModifier.testingGeneratedIdentifier only — Owner:@schatt |
| `testExactNamedVsNamedDifference` | `Excluded: generator comparison only — Owner:@schatt` |
| `testExactNamedIgnoresHierarchy` | `Excluded: generator with mock hierarchy only — Owner:@schatt` |
| `testExactNamedMinimalIdentifier` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_exactNamed_minimalIdentifier` |
| `testConfigurationChangesMidTest` | `Excluded: mutates shared config after view build — Owner:@schatt` |
| `testNestedNamedCalls` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_nestedNamed_outerAndInner_haveIdentifiers` |
| `testUnicodeCharacters` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_unicodeText_hasAccessibilityIdentifier` |

### `Features/Accessibility/AccessibilityIdentifierPersistenceTests.swift`

| Test | Resolution |
|------|------------|
| `testAccessibilityIdentifiersArePersistentAcrossSessions` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersAreDeterministicForSameView` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersDontContainTimestamps` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersAreStableForUITesting` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersAreBasedOnViewStructure` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersAreTrulyPersistentForIdenticalViews` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |
| `testAccessibilityIdentifiersPersistAcrossConfigResets` | `Excluded: persistence/determinism via unit harness; not XCUI identifier queries — Owner:@schatt` |

### `Features/Accessibility/AccessibilityIdentifierGenerationVerificationTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticAccessibilityIdentifiersActuallyGenerateIDs` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_auditTitle_namedComponent` |
| `testNamedActuallyGeneratesIdentifiers` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_auditTitle_namedComponent` |
| `testAutomaticAccessibilityIdentifiersActuallyGenerateIdentifiers` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_midHierarchy_autoSiblingAndOptOut_identifiersPresent` |
| `testManualIdentifiersOverrideAutomaticGeneration` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_manualOnOuterGroup_overridesWrapper` |
| `testGlobalConfigActuallyControlsIdentifierGeneration` | `UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_basicAutomaticCompliance_doesNotEmitSuppressedName` |

### `Features/Accessibility/AutomaticAccessibilityIdentifierTests.swift`

| Test | Resolution |
|------|------------|
| `testGlobalConfigControlsAutomaticIdentifiers` | `Dedup:UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_basicAutomaticCompliance_doesNotEmitSuppressedName` |
| `testGlobalConfigSupportsCustomNamespace` | `Excluded: namespace/mode strings; not asserted on Category A audit — Owner:@schatt` |
| `testGlobalConfigSupportsGenerationModes` | `Excluded: namespace/mode strings; not asserted on Category A audit — Owner:@schatt` |
| `testAutomaticIDGeneratorCreatesStableIdentifiers` | `Excluded: generator API unit coverage — Owner:@schatt` |
| `testAutomaticIDGeneratorHandlesDifferentRolesAndContexts` | `Excluded: generator API unit coverage — Owner:@schatt` |
| `testAutomaticIDGeneratorHandlesNonIdentifiableObjects` | `Excluded: generator API unit coverage — Owner:@schatt` |
| `testManualAccessibilityIdentifiersOverrideAutomatic` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_manualOnOuterGroup_overridesWrapper` |
| `testViewLevelOptOutDisablesAutomaticIDs` | `Excluded: view-level opt-out; no dedicated Category A XCUI row — Owner:@schatt` |
| `testAutomaticIdentifiersIntegrateWithHIGCompliance` | `Excluded: HIG styling integration; VI/unit scope — Owner:@schatt` |
| `testLayer1FunctionsIncludeAutomaticIdentifiers` | `Excluded: L1 API smoke; not Category A XCUI — Owner:@schatt` |
| `testCollisionDetectionIdentifiesConflicts` | `Excluded: collision/debug unit — Owner:@schatt` |
| `testDebugLoggingCapturesGeneratedIDs` | `Excluded: debug logging contracts; not XCUI — Owner:@schatt` |
| `testDebugLoggingDisabledWhenTurnedOff` | `Excluded: debug logging contracts; not XCUI — Owner:@schatt` |
| `testDebugLogFormatting` | `Excluded: debug logging contracts; not XCUI — Owner:@schatt` |
| `testDebugLogClearing` | `Excluded: debug logging contracts; not XCUI — Owner:@schatt` |
| `testViewHierarchyTracking` | `Excluded: hierarchy tracking unit — Owner:@schatt` |
| `testUITestCodeGeneration` | `Excluded: UITest codegen helpers — Owner:@schatt` |
| `testUITestHelpers` | `Excluded: UITest codegen helpers — Owner:@schatt` |
| `testUITestCodeFileGeneration` | `Excluded: UITest codegen helpers — Owner:@schatt` |
| `testUITestCodeClipboardGeneration` | `Excluded: UITest codegen helpers — Owner:@schatt` |
| `testTrackViewHierarchyAutomaticallyAppliesAccessibilityIdentifiers` | `Excluded: hierarchy tracking unit — Owner:@schatt` |
| `testGlobalAutomaticAccessibilityIdentifiersWork` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_midHierarchy_autoSiblingAndOptOut_identifiersPresent` |
| `testIDGenerationUsesActualViewContext` | `Excluded: view-context stack unit — Owner:@schatt` |
| `testAutomaticAccessibilityIdentifiersWithNamedComponent` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_auditTitle_namedComponent` |

### `Core/Architecture/GlobalDisableLocalEnableTests.swift`

| Test | Resolution |
|------|------------|
| `testFrameworkComponentGlobalDisableLocalEnableGeneratesID` | `Excluded: task-local enable/disable; VI harness — Owner:@schatt` |
| `testGlobalEnableLocalDisableDoesNotGenerateID` | `Excluded: task-local enable/disable; VI harness — Owner:@schatt` |
| `testFrameworkComponentsRespectGlobalConfig` | `Dedup:UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_named_stillSurfacesIdentifier` |
| `testPlainSwiftUIRequiresExplicitEnable` | `Excluded: explicit-enable contract; unit/VI — Owner:@schatt` |

### `Layers/LocalEnableOverrideTests.swift`

| Test | Resolution |
|------|------------|
| `testGlobalDisableLocalEnable` | `Excluded: task-local enable; VI harness — Owner:@schatt` |
| `testNamedModifierAlwaysWorksRegardlessOfGlobalSettings` | `UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_named_stillSurfacesIdentifier` |
| `testNamedModifierAlwaysWorksEvenWhenGlobalConfigDisabled` | `Dedup:UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_named_stillSurfacesIdentifier` |

### `Features/Accessibility/AutomaticAccessibilityLabelViewInspectorTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticCompliance_AppliesAccessibilityLabel_WhenProvided` | `UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_accessibilityLabel_parameter_surfacesInLabel` |
| `testAutomaticCompliance_WorksWithoutAccessibilityLabel` | `Excluded: nil-label branch; no Category A XCUI row — Owner:@schatt` |
| `testAutomaticComplianceNamed_AppliesAccessibilityLabel_WhenProvided` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_accessibilityLabel_parameter_surfacesInLabel` |
| `testAutomaticComplianceNamed_WorksWithoutAccessibilityLabel` | `Excluded: nil-label branch; no Category A XCUI row — Owner:@schatt` |
| `testPlatformButton_AppliesAccessibilityLabel` | `Excluded: platformButton label; Layer 4 harness / VI — Owner:@schatt` |
| `testPlatformButton_AutoExtractsLabelFromParameter` | `Excluded: platformButton label extraction; VI — Owner:@schatt` |
| `testLabelFormatting_ThroughViewInspector` | `Excluded: localization/formatting; not XCUI identifier — Owner:@schatt` |
| `testAutomaticCompliance_DoesNotApplyEmptyLabel` | `Excluded: empty-label branch; VI — Owner:@schatt` |
| `testAutomaticCompliance_HandlesNilLabel` | `Excluded: nil-label branch; VI — Owner:@schatt` |

### `Features/Accessibility/AccessibilityIdentifierDisabledTests.swift`

| Test | Resolution |
|------|------------|
| `testAutomaticIDsDisabled_NoIdentifiersGenerated` | `Dedup:UI:AccessibilityIdentifierCategoryAGlobalOffUITests/testCategoryAGlobalOff_basicAutomaticCompliance_doesNotEmitSuppressedName` |
| `testManualIDsStillWorkWhenAutomaticDisabled` | `UI:ManualAccessibilityIdentifierHarnessUITests/testManualPlatformButtonIds_queryableViaXCUITest` |
| `testBreadcrumbModifiersStillWorkWhenAutomaticDisabled` | `Excluded: breadcrumb modifiers; VI — Owner:@schatt` |

### `Features/Accessibility/AccessibilityIdentifierGenerationTests.swift`

| Test | Resolution |
|------|------------|
| `testAccessibilityIdentifiersAreReasonableLength` | `Excluded: length/shape heuristics; VI/unit — Owner:@schatt` |
| `testAccessibilityIdentifiersDontDuplicateHierarchy` | `Excluded: hierarchy shape heuristics; VI/unit — Owner:@schatt` |
| `testAccessibilityIdentifiersAreSemantic` | `Excluded: semantic heuristics; VI/unit — Owner:@schatt` |
| `testAccessibilityIdentifiersWorkInComplexHierarchy` | `Excluded: complex hierarchy; VI/unit — Owner:@schatt` |
| `testAccessibilityIdentifiersIncludeLabelTextForStringLabels` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_specialCharsInLabel_hasIdentifier` |
| `testAccessibilityIdentifiersSanitizeLabelText` | `Dedup:UI:AccessibilityIdentifierCategoryAUITests/testCategoryA_emptyIdentifierName_sanitizedLabelInIdentifier` |

### `Features/Accessibility/AccessibilityIdentifiersDebugTests.swift`

| Test | Resolution |
|------|------------|
| `testDirectAutomaticAccessibilityIdentifiersWorks` | `Excluded: modifier smoke; VI — Owner:@schatt` |
| `testNamedModifierWorks` | `Excluded: modifier smoke; VI — Owner:@schatt` |
| `testAutomaticAccessibilityModifierWorks` | `Excluded: modifier smoke; VI — Owner:@schatt` |
| `testAutomaticAccessibilityExtensionWorks` | `Excluded: modifier smoke; VI — Owner:@schatt` |

### `Features/Accessibility/AccessibilityIdentifierConfigUserDefaultsTests.swift`

| Test | Resolution |
|------|------------|
| `testSaveToUserDefaultsSavesConfiguration` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |
| `testLoadFromUserDefaultsLoadsConfiguration` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |
| `testLoadFromUserDefaultsRespectsDefaultsWhenNoSavedConfig` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |
| `testConfigurationPersistenceAcrossAppLaunches` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |
| `testSaveToUserDefaultsSavesAllProperties` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |
| `testLoadFromUserDefaultsOnlyLoadsIfKeyExists` | `Excluded: UserDefaults API; not XCUI tree — Owner:@schatt` |

**Total canonical `@Test` rows:** 83

---

## `ConsolidatedAccessibilityTests.swift` deduplication

This file aggregates **662** `@Test` methods (full table, not inlined here).

**Authoritative table:** [`Development/VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md`](VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md)

**Rule:** Each consolidated test either **Dedup**s to the first matching ViewInspector source (same method name under `ViewInspectorTests/`, excluding the consolidated file) or is **Excluded** when the name exists only in the aggregate file.

**Regenerate after adding or renaming consolidated tests:**

```bash
python3 Development/scripts/generate_category_a_consolidated_dedup.py
```

---

## Out of scope for #197 (by design)

- **`Development/Tests/SixLayerFrameworkUnitTests/Features/Accessibility/AutomaticAccessibilityLabelTests.swift`** — pure formatting/localization unit tests without ViewInspector identifier readback; do **not** list here unless a specific method is tied to an iOS VI identifier failure.
- **Category B–E** failures — tracked under other issues / audit sections, not this checklist.

---

## Related UI test files (existing partial coverage)

Examples: `AccessibilityIdentifierCategoryAUITests.swift`, `AccessibilityIdentifierCategoryAGlobalOffUITests.swift`, `ManualAccessibilityIdentifierHarnessUITests.swift`. Reference these in `UI:…` cells when they cover a canonical row.
