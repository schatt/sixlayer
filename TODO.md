# TODO

**Current Release**: v6.6.3

## Current

- [x] Verify Xcode MCP (`mcpbridge-wrapper`) after restart: `GetTestList` + `tabIdentifier` works for sixlayer `windowtab1`
- [x] Fix Swift concurrency data-race warning in `AdvancedFieldTypes.handleDrop` (`newFiles` capture)
- [x] **#191** Make `ExpandableCardComponent` a single tappable accessibility button with explicit card label
- [x] **#192** Make accessibility identifier compliance tests robust via platform traversal + debug-log fallback
- [ ] **#177** Fix remaining iOS ViewInspector/accessibility test failures (TDD green phase; commit/push per go workflow)
- [ ] **#193** L4 UITests: iOS Form contract UI + ensureContractRoot/scroll fixes pushed; re-run SLF-iOS-UITests via MCP/CLI to confirm green
- [x] **#197** (slice) Category A UI backfill: exactNamed, accessibilityLabel row, outer manual Group id + tests (commit/push; issue commented)
- [x] **#197** (slice) Global-off audit (`-CategoryAGlobalAutoOff`), empty identifierName row + UI tests
- [x] Fix `ModalContainerTests.swift` missing closing brace (build error)
- [x] Fix Swift 6 actor-isolation errors in `DynamicFormTests.swift`
- [x] Fix Swift 6 actor-isolation errors in `LabeledContentDisplayFieldTests.swift`
- [x] **#202** Review issue details for nested sidebar overlap in host settings split UI
- [ ] **#202** Implement framework-level nested sidebar coordination policy (opt-in API + tests)
- [x] **#203** TDD: Add navigation layout resolver core with profile/policy types
- [x] **#204** TDD: Integrate resolver into `platformSettingsContainer_L4`
- [x] **#205** TDD: Resolver in `platformAppNavigation_L4` + parity with settings (`resolveAppNavigationShell`)
- [x] **#206** Compact fallback: automatic preset + overlay outer sidebar (`NavigationLayoutCompactPresentation`)
- [ ] Run `swift test` to confirm everything passes
- [x] Group current uncommitted changes in the v6.6.0 branch into small, logical commits
- [ ] Adjust development workflow to encourage committing early and often (small, cohesive commits per TDD cycle)
- [ ] SLFiOSViewInspectorTests: clear remaining compiler warnings (many files; ConsolidatedAccessibilityTests.swift is the bulk)
