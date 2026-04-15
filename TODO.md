# TODO

**Current Release**: v7.5.13

## Current

- [ ] **#211** DeviceType settings shell policy: matrix tests + watch sub-pane stack policy + guide table on `b7.6.0`; remaining: audit `platformSettingsContainer_L4` managed-flow `default` branches per issue scope
- [x] **#224** Dynamic form inline header: `DynamicFormHeaderVisibility` + strict TDD (unit + ViewInspector); branch `b7.5.13` (issue commented)
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
- [ ] **#177** Fix remaining iOS ViewInspector/accessibility test failures — `AccessibilityIdentifierEdgeCaseTests` exactNamed paths green via `testingGeneratedIdentifier`; manual ID remains soft `if let` in disabled suite (harness nil)
- [ ] **#193** L4 UITests: `testL4_platformSheet_L4` green (sheet on `L4ContractSheetTrigger` + dismiss query under `app.sheets`); re-run full SLF-iOS-UITests for remaining L4 cases
- [x] **#197** (slice) Category A UI backfill: exactNamed, accessibilityLabel row, outer manual Group id + tests (commit/push; issue commented)
- [x] **#197** (slice) Global-off audit (`-CategoryAGlobalAutoOff`), empty identifierName row + UI tests
- [x] **#197** Checklist: canonical 83 resolutions filled; 662-row Consolidated dedup in VIEWINSPECTOR_CATEGORY_A_CONSOLIDATED_DEDUP.md + generator script (close #197 on branch when ready)
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
