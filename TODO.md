# TODO

**Current Release**: v6.6.3

## Current

- [x] Verify Xcode MCP (`mcpbridge-wrapper`) after restart: `GetTestList` + `tabIdentifier` works for sixlayer `windowtab1`
- [x] Fix Swift concurrency data-race warning in `AdvancedFieldTypes.handleDrop` (`newFiles` capture)
- [x] **#191** Make `ExpandableCardComponent` a single tappable accessibility button with explicit card label
- [x] **#192** Make accessibility identifier compliance tests robust via platform traversal + debug-log fallback
- [ ] **#209** Managed settings flow — done: L4 APIs, `selectTopLevelPane`, guide, Layer4 README + Framework README, compile-checked example; GitHub issue commented with progress; pending: optional result-builder, maintainer acceptance / close when ready
- [ ] **#177** Fix remaining iOS ViewInspector/accessibility test failures — `AccessibilityIdentifierEdgeCaseTests` exactNamed paths green via `testingGeneratedIdentifier`; manual ID remains soft `if let` in disabled suite (harness nil)
- [ ] **#193** L4 UITests: table-first scroll + nav identifier tap (Form/table); re-run SLF-iOS-UITests to confirm green
- [x] **#197** (slice) Category A UI backfill: exactNamed, accessibilityLabel row, outer manual Group id + tests (commit/push; issue commented)
- [x] **#197** (slice) Global-off audit (`-CategoryAGlobalAutoOff`), empty identifierName row + UI tests
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
