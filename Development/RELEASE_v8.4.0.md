# SixLayer Framework v8.4.0 Release Documentation

**Release Date**: September 7, 2026  
**Release Type**: Minor  
**Previous Release**: v8.3.8  
**Status**: Released

---

## 🎯 Release Summary

v8.4.0 is a **minor** release focused on Layer 5 honesty: real iOS L5 behavior and tests, removal of documented-but-absent performance APIs, and deletion of placeholder Layer5 demo types. It also lands the first L5/L6 unit-coverage clusters spawned from the coverage inventory.

1. **Real iOS L5 coverage and behavior** — executing tests for haptics (#423); swipe direction and pull-to-refresh sequence (#424); `platformIOSLayout` no longer pretends to be keyboard-aware (#444).
2. **Stop advertising APIs that do not exist** — phantom L5 performance modifiers/types removed from current docs (#425).
3. **Remove 14 placeholder `Platform*Layer5` demo Views** — 0% coverage shells deleted rather than invented (#453). **Source-breaking** if you referenced those types.
4. **Unit-lane coverage inventory and first clusters** — L5/L6 inventory (#450); `#else` stub identity policy (#449); AccessibilityFeatures, Messaging/Resource, SplitView, and IntelligentCardExpansion unit gaps (#454–#457).

---

## 🆕 Confirmed in v8.4.0 (implemented)

### **iOS L5: haptics, swipe, pull-to-refresh (#423, #424)**

`platformIOSHapticFeedback` / `IOSHapticStyle` now have executing unit tests (#423). Remaining `PlatformIOSOptimizationsLayer5` APIs gained coverage and real helpers for swipe direction and the pull-to-refresh true→callback→false sequence (#424). Asserting that the system refresh control fires `onRefresh` remains an XCUI sentinel (#452, not in this release).

### **`platformIOSLayout` is not keyboard-aware (#444)**

Empty `keyboardAware` / `onReceive` hooks were a lie. The parameter and keyboard subscriptions are **removed**. Safe-area wrapping stays. Signature:

```swift
func platformIOSLayout(safeAreaInsets: Bool = true) -> some View
```

### **Phantom L5 performance APIs (#425)**

Docs, examples, and `DataIntrospection` no longer recommend `platformLazyLoading` or other modifiers/types that were never in `Framework/Sources`. `README_Layer5_Performance.md` points at real L5 paths (`PlatformIOSOptimizationsLayer5`, `Layer5-Platform/`). Remaining phantom names are do-not-call notes only.

### **Placeholder Layer5 demo Views removed (#453)**

Fourteen public demo-shell types with 0% unit coverage are **deleted** (Interpretation, Knowledge, Logging, Maintenance, Notification, Optimization, Orchestration, Organization, Privacy, Profiling, Recognition, Routing, Safety, Wisdom Layer5). Dependent ViewInspector/a11y tests and indexes were scrubbed. No replacement APIs.

### **Coverage inventory and unit clusters (#450, #449, #454–#457)**

- **#450** — platform L5/L6 unit-lane coverage inventory; spawned gap issues.
- **#449** — policy + tests: opposite-lane subject-type identity for `#else { self }` platform stubs.
- **#454** — `AccessibilityFeaturesLayer5` unit coverage (configs, enums, managers).
- **#455** — `PlatformMessagingLayer5` / `PlatformResourceLayer5` unit coverage.
- **#456** — `PlatformSplitViewOptimizationsLayer5` unit coverage.
- **#457** — IntelligentCardExpansion L5/L6 unit gap tests.

---

## ⚠️ Migration / consumer notes

### Deleted placeholder Layer5 types (#453)

If you imported or instantiated any of the 14 removed `Platform*Layer5` demo Views, delete those call sites. They had no real platform behavior. Do not expect replacements in this release. Real L5 work continues on v8.5.0 (#447, #451, #445).

### `platformIOSLayout(keyboardAware:)` (#444)

Remove the `keyboardAware` argument. Keyboard avoidance is not implemented; do not pass a flag that used to no-op.

### Phantom performance modifiers (#425)

Do not call `platformLazyLoading`, `platformMemoryOptimization`, or other documented-but-absent L5 performance APIs. They never existed in Sources. Use real L5 helpers in `PlatformIOSOptimizationsLayer5` / `Layer5-Platform/`.

### Not new in this tag

[#402](https://github.com/schatt/sixlayer/issues/402) and [#422](https://github.com/schatt/sixlayer/issues/422) are on the v8.4.0 milestone but already shipped in **v8.3.8**.

---

## ✅ Resolved GitHub issues (milestone v8.4.0)

### New in this tag

- **[Issue #423](https://github.com/schatt/sixlayer/issues/423)** — Add executing tests for `platformIOSHapticFeedback` (L5 iOS).
- **[Issue #424](https://github.com/schatt/sixlayer/issues/424)** — Cover remaining `PlatformIOSOptimizationsLayer5` APIs (L5 iOS).
- **[Issue #425](https://github.com/schatt/sixlayer/issues/425)** — Implement or remove documented L5 performance APIs that do not exist.
- **[Issue #444](https://github.com/schatt/sixlayer/issues/444)** — Implement or remove keyboard-aware behavior in `platformIOSLayout`.
- **[Issue #449](https://github.com/schatt/sixlayer/issues/449)** — Policy + tests: identity coverage for platform `#else` stubs.
- **[Issue #450](https://github.com/schatt/sixlayer/issues/450)** — Coverage inventory: platform L5/L6 first (spawn gap issues).
- **[Issue #453](https://github.com/schatt/sixlayer/issues/453)** — Remove or implement placeholder `Platform*Layer5` demo Views (0% unit coverage).
- **[Issue #454](https://github.com/schatt/sixlayer/issues/454)** — Unit-lane coverage for `AccessibilityFeaturesLayer5`.
- **[Issue #455](https://github.com/schatt/sixlayer/issues/455)** — Unit coverage for `PlatformMessagingLayer5` and `PlatformResourceLayer5`.
- **[Issue #456](https://github.com/schatt/sixlayer/issues/456)** — Unit-lane coverage for `PlatformSplitViewOptimizationsLayer5`.
- **[Issue #457](https://github.com/schatt/sixlayer/issues/457)** — Close IntelligentCardExpansion L5/L6 unit coverage gaps.
- **[Issue #462](https://github.com/schatt/sixlayer/issues/462)** — Prepare v8.4.0 minor release (docs / `--docs`).

### Already in v8.3.8 (still on this milestone)

- **[Issue #402](https://github.com/schatt/sixlayer/issues/402)** — Wire or remove orphan LayeredTestingSuite.
- **[Issue #422](https://github.com/schatt/sixlayer/issues/422)** — `RuntimeOptimization` host-resource strategy.

**Not in this release:** haptic API unification (#445), macOS L5 chrome (#451), FormLayoutDecision (#397), advanced field types (#403), secondary-platform host apps (#392–#394). Those track v8.5.0+ / Full Tests.

---

## 📚 References

- [RELEASE_v8.3.8.md](RELEASE_v8.3.8.md) — Previous patch.
- [AI_AGENT_v8.4.0.md](AI_AGENT_v8.4.0.md) — Agent notes for this minor.
- [RELEASES.md](RELEASES.md) — Release history index.
