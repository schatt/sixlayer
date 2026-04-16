# TODO

**Current Release**: v7.6.0

## Current

- [x] **#232** `b7.6.0` release: verify iOS ViewInspector modal sheet chrome test no longer hangs after capping `accessibilityElementCount` enumeration in `AccessibilityTestUtilities.swift`
- [x] **#232 / #236** `FormDraftTests`: unique `UserDefaults` suite name per run so parallel clones do not race on `test_form_storage`
- [ ] **#232** Follow-up: fix failing confirmation-control expectation in `PlatformModalSheetNavigationChromeLayer4Tests.testPlatformModalSheetNavigationChrome_L4_ExposesConfirmationButton()` (assertion still fails with expected label `"Apply"`)
- [ ] **#233** Epic: Run full test suite for every platform (unit/view/ui)
  - [x] Build platform x layer matrix from existing schemes/targets (macOS, iOS, watchOS, tvOS, visionOS) — posted on #233 / pointer on #234, SHA `3032f6ce` branch `b7.6.0`
  - [ ] macOS: run Unit tests
  - [ ] macOS: run ViewInspector tests
  - [ ] macOS: run UI tests
  - [ ] iOS: run Unit tests
  - [ ] iOS: run ViewInspector tests
  - [ ] iOS: run UI tests
  - [ ] watchOS: run Unit + UI (ViewInspector **N/A** — no target on this platform); follow-up issues only for real failures or optional new coverage
  - [ ] tvOS: run Unit + UI (ViewInspector **N/A**)
  - [ ] visionOS: run Unit + UI (ViewInspector **N/A**)
  - [ ] For each distinct failure, create and link a GitHub issue under epic #233
  - [ ] Post consolidated pass/fail/missing matrix and log/xcresult evidence on #233

- [ ] **#226** Consumer-facing `SixLayerUITestNavigator` contract (stable screen selectors + reusable navigation helpers in `SixLayerTestKit`)
  - [ ] **#227** Define public UI test navigation contract types
  - [ ] **#228** Implement cross-platform contract element resolver
  - [ ] **#229** Add `SixLayerUITestNavigator` core primitives
  - [ ] **#230** Add optional contract assertion helpers and docs
  - [ ] **#231** Add consumer-style iOS/macOS smoke tests for navigator
- [x] **#211** DeviceType settings shell policy: matrix tests + watch sub-pane stack policy + guide table + explicit `PlatformManagedSettingsTopLevelShellPolicy` routing in `platformSettingsContainer_L4` (no silent iOS default fallthrough for `.car`)
- [x] **#212** Document L1 sidebar + `platformManagedSettingsTopLevel_L4` composition with strict TDD (red evidence comment posted; guide + compile-checked example updated)
- [x] **#215** CHANGELOG / release notes for managed settings migration retargeted to `v7.6.0` (`CHANGELOG.md`, `Development/RELEASE_v7.6.0.md`, `Development/RELEASES.md`)
- [x] **#225** Add managed settings sub-pane stack policy override (keep defaults, add explicit escape hatch without dropping to full manual shell)
- [x] **#224** Dynamic form inline header: `DynamicFormHeaderVisibility` + strict TDD (unit + ViewInspector); branch `b7.5.13` (issue commented)
- [x] **#235** Dynamic form navigation heading conflict: add `headerDisplayMode`/`showFormTitle`/`hostProvidesPrimaryHeading` + configurable top content padding; strict TDD red evidence posted and targeted tests green
- [x] Tart VM scripts (CarManager-style) in `Development/scripts/vm/` for macOS UI tests off-host (`vm_test.sh test-ui-macos`)

- [x] UITest app Layer 1 Data Presentation: fix leading text clipping (`platformFrame` topLeading + `ScrollView` on examples)
- [x] **#218** `platformFormContainer` owns `Form` on macOS (parity with iOS; avoid nested `Form`)
- [x] **#220** No-header `platformSectionContainer` → `Section`; inset chrome → `platformGroupedInsetContainer` (milestone v7.5.12)
- [x] **#194** Default dynamic form localization keys from accessibility identifier segment + env resolver (`DynamicFormFieldLocalizationResolver`), metadata `localizationKeyBase` / `accessibilityIdentifierName` / form `localizationNamespace`
- [x] Verify Xcode MCP (`mcpbridge-wrapper`) after restart: `GetTestList` + `tabIdentifier` works for sixlayer `windowtab1`
- [x] Fix Swift concurrency data-race warning in `AdvancedFieldTypes.handleDrop` (`newFiles` capture)
- [x] **#191** Make `ExpandableCardComponent` a single tappable accessibility button with explicit card label
- [x] **#192** Make accessibility identifier compliance tests robust via platform traversal + debug-log fallback
- [x] **#209** Managed settings flow — closed on GitHub (acceptance criteria checked); optional follow-up: result-builder / richer pane tree
- [x] **#210** Add `SettingsPaneDescriptor` + section builders (stable order, duplicate-ID invariant, `SettingsSectionData` mapping) with MCP-verified unit tests
- [x] **#214** Optional `ManagedSettingsPaneList` from descriptors with strict TDD (red evidence posted; MCP targeted tests green after refactor)
- [x] **#213** Document escape hatches for non-uniform settings detail layouts (`platformSettingsContainer_L4` + arbitrary `detail` composition patterns)
- [ ] **#177** Fix remaining iOS ViewInspector/accessibility test failures — `AccessibilityIdentifierEdgeCaseTests` exactNamed paths green via `testingGeneratedIdentifier`; manual ID remains soft `if let` in disabled suite (harness nil)
- [ ] **#193** L4 UITests: `testL4_platformSheet_L4` green (sheet on `L4ContractSheetTrigger` + dismiss query under `app.sheets`); re-run full SLF-iOS-UITests for remaining L4 cases
- [x] **#197** (slice) Category A UI backfill: exactNamed, accessibilityLabel row, outer manual Group id + tests (commit/push; issue commented)
- [x] **#197** (slice) Global-off audit (`-CategoryAGlobalAutoOff`), empty identifierName row + UI tests
- [x] **#197** Checklist: canonical 83 resolutions filled; 662-row Consolidated dedup in VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md + generator script (close #197 on branch when ready)
- [x] **#198** Category B UI backfill: `-OpenDetailViewCategoryB` TestApp host + XCUITests covering IntelligentDetailView default content, custom-field rendering text, and nil-value visible content
- [x] **#199** Category C UI backfill: TestApp callback host (`-OpenCategoryCCallbacks`) + strict TDD MCP runs (red evidence posted; green + post-refactor passing)
- [x] **#200** Category D OCR UI backfill: dedicated TestApp OCR flow screen + UI tests for disambiguation alternatives, selection result reflection, and overlay presentation outcome
- [x] **#201** Category E UI backfill: `-OpenCategoryEOneOffs` host + strict TDD complete for explicit-enable, opt-out, clipboard UI flow, and odometer alias crop behavior (red logs posted on issue)
- [x] Fix `ModalContainerTests.swift` missing closing brace (build error)
- [x] Fix Swift 6 actor-isolation errors in `DynamicFormTests.swift`
- [x] Fix Swift 6 actor-isolation errors in `LabeledContentDisplayFieldTests.swift`
- [x] **#202** Nested sidebar overlap / resolver slices (#203–#208); closed via `gh` (branch `b7.6.0`, merge to `main` pending)
- [x] **#203** TDD: Add navigation layout resolver core with profile/policy types
- [x] **#204** TDD: Integrate resolver into `platformSettingsContainer_L4`
- [x] **#205** TDD: Resolver in `platformAppNavigation_L4` + parity with settings (`resolveAppNavigationShell`)
- [x] **#206** Compact fallback: automatic preset + overlay outer sidebar (`NavigationLayoutCompactPresentation`)
- [x] **#207** Accessibility hardening: overlay close semantics + modal/restore UI contract tests
- [x] **#208** Stress matrix (slice 6): `NavigationLayoutStressMetrics`, Dynamic Type + long-form minimum detail width, split-axis width helper, Codable presentation, deterministic resize churn, app/settings stress parity (`swift test --filter NavigationLayoutResolverTests`)
- [x] Run `swift test` (NavigationLayoutResolverTests) to confirm slice passes
- [x] Group current uncommitted changes in the v6.6.0 branch into small, logical commits
- [ ] Adjust development workflow to encourage committing early and often (small, cohesive commits per TDD cycle)
- [ ] SLFiOSViewInspectorTests: clear remaining compiler warnings (many files; ConsolidatedAccessibilityTests.swift is the bulk)
