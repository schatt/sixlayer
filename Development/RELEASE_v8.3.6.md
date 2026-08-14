# SixLayer Framework v8.3.6 Release Documentation

**Release Date**: August 11, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.5  
**Status**: Released

---

## 🎯 Release Summary

v8.3.6 is a **patch** release focused on:

1. **OCR / Scan flags** — `applying(hints:)` no longer infers `supportsOCR` / `displayOCR` / `isCalculated` from `ocrHints` or `calculationGroups` ([#404](https://github.com/schatt/sixlayer/issues/404)).
2. **Named compliance host sentinel** — `NamedAutomaticComplianceModifier` attaches via `accessibilityHostIdentifier` so ExpandableCardCollectionView does not `unsafeBitCast` under iOS 27 ([#406](https://github.com/schatt/sixlayer/issues/406)).
3. **iOS unit-gate GeometryProxy SIGTRAP** — hosted a11y helpers skip ViewInspector `findAll` into `GeometryReader`; ViewInspector pinned to `0.10.4` ([#408](https://github.com/schatt/sixlayer/issues/408)).
4. **Test-lane / CI hygiene** — relocate VI-preferring suites ([#395](https://github.com/schatt/sixlayer/issues/395), [#381](https://github.com/schatt/sixlayer/issues/381)); keep hosted/ViewInspector tests out of the unit lane ([#412](https://github.com/schatt/sixlayer/issues/412)); macOS UITest deep-link launch ([#400](https://github.com/schatt/sixlayer/issues/400)); release-script clean/stamp/invoke follow-ups ([#405](https://github.com/schatt/sixlayer/issues/405), [#390](https://github.com/schatt/sixlayer/issues/390), [#409](https://github.com/schatt/sixlayer/issues/409), [#411](https://github.com/schatt/sixlayer/issues/411), [#413](https://github.com/schatt/sixlayer/issues/413)).

---

## 🆕 Confirmed in v8.3.6 (implemented)

### **`displayOCR` / stop inferring flags from hints (#404)**

`FieldDisplayHints.ocrHints` and `calculationGroups` are data only. Applying them does **not** flip field feature flags.

- New `DynamicFormField.displayOCR` (defaults to match `supportsOCR` when omitted).
- Optional hints-file keys: `"supportsOCR"`, `"displayOCR"`, `"isCalculated"`.
- Consumers that relied on inference must set flags explicitly (see Migration).

### **NamedAutomaticCompliance host sentinel (#406)**

Direct `accessibilityIdentifier` on GeometryReader/LazyVGrid content trapped under iOS 27 sim (`unsafeBitCast` size mismatch). Named compliance now uses the same host-sentinel pattern as `.named` / `.exactNamed` (#360 / #364).

### **ViewInspector GeometryReader walk (#408)**

Release-gate `SLF-iOS-UnitTests` mass-SIGTRAPed when `allAccessibilityIdentifiersInInspectedRecursive` called `findAll(ClassifiedView)` and ViewInspector 0.10.3 materialized `GeometryProxy` at 48/52 bytes (iOS 27 layout is 68+).

- Hosted platform identifier collection is preferred.
- Helper descendant `findAll` / `button()` search is skipped on that path.
- ViewInspector pinned to branch `0.10.4` (PR 421 size-agnostic allocation) for remaining walks.

### **Suite relocation and secondary-lane observation (#395, #381)**

VI-preferring / ComponentAccessibility suites moved after secondary-lane observation; non-ViewInspector suites moved out of `ViewInspectorTests` so tvOS/watchOS/visionOS unit lanes compile and run the shared sources. `ResponsiveGrid` uses named compliance for observable IDs.

### **macOS UITest deep-link launch (#400)**

Self-hosted CI macOS UITests failed to open hosts from deep-link launch args. Shared `SixLayerUITestCase` plus removal of a broken `/tmp` flock restore launch-arg routing.

### **Release script / Xcode 27 clean+test (#405, #409, #390, #411, #413)**

- #405 added clean-before-test on default DerivedData.
- #409 removes that clean: Xcode 27 races `clean` then `test` and reports the macOS `.xctest` executable missing (FB24278669).
- #411 keeps the unit gate as a single `rtk xcodebuild test` (do not split `build-for-testing` / `test-without-building`).
- #413 stops `simctl delete unavailable` before iOS unit tests; still creates the named simulator if it is missing.
- #390 adds per-platform last-pass stamps so a retry can skip a green lane.

### **Unit lane must not host SwiftUI (#412)**

Hosted / ViewInspector tests were running in `SLF-*-UnitTests`, so the unit gate paid run-loop hosting cost. Those sources live under `ViewInspectorTests/` and are excluded from the unit schemes.

### **Build / TestKit hygiene (#388, #389, #407, #371)**

- Remove leftover `Inspectable` from ViewInspectorTestKit smoke tests (#388).
- Eliminate macOS/iOS build-for-testing warnings (#389).
- Commit XcodeGen `project.pbxproj` regen (#407).
- iOS XCUI Layer5 `voiceOverEnabled` contract id + Category E clipboard timing (#371).

---

## ⚠️ Migration / consumer notes

### `applying(hints:)` — OCR / calculation flags no longer inferred (#404)

| Concern | Field flag | Hints override (optional) |
|---|---|---|
| Batch / receipt fill target | `supportsOCR` | `"supportsOCR": true/false` |
| Per-field Scan accessory | `displayOCR` (new; defaults to match `supportsOCR` when omitted at init) | `"displayOCR": true/false` |
| Calculated field | `isCalculated` | `"isCalculated": true/false` |
| Extraction keywords | `ocrHints` | `"ocrHints": […]` |
| Calculation formulas | `calculationGroups` | `"calculationGroups": […]` |

**Breaking for consumers that relied on inference:**
- Putting `ocrHints` in a `.hints` file (or `FieldDisplayHints`) no longer sets `supportsOCR = true` or shows the Scan button.
- Putting `calculationGroups` no longer sets `isCalculated = true`.

**Action:**
1. Set `supportsOCR` / `displayOCR` / `isCalculated` explicitly in code, **or** in the hints file with the matching optional keys.
2. CarManager station-style fields: `supportsOCR: true`, `displayOCR: false`, keep `ocrHints` for extraction; map/`trailingView` stays the only accessory.
3. Apps that previously got a Scan button “for free” from `ocrHints` alone must set `supportsOCR: true` (and leave `displayOCR` default, or set it explicitly).

See [OCRFieldHintsGuide.md](../Framework/docs/OCRFieldHintsGuide.md).

### ResponsiveGrid accessibility identifier shape (#395)

`ResponsiveGrid` now applies `.automaticCompliance(named: "ResponsiveGrid")` instead of anonymous `.automaticCompliance()`.

- **Why:** Anonymous compliance on `LazyVGrid` often yields no observable ID when cells are not materialized (secondary unit lanes / incomplete layout).
- **Consumer impact:** Generated accessibility identifiers for `ResponsiveGrid` now include the `ResponsiveGrid` name segment.
- **Action:** If UI tests or tooling matched anonymous / `main.ui.element`-style IDs for grid shells, update queries to the named form.

---

## ✅ Resolved GitHub issues (v8.3.6)

- **[Issue #408](https://github.com/schatt/sixlayer/issues/408)** — iOS release gate mass SIGTRAP in ViewInspector `GeometryProxy` during a11y ID recursion. Hosted collection preferred; ViewInspector `0.10.4`.
- **[Issue #413](https://github.com/schatt/sixlayer/issues/413)** — Release iOS unit gate: do not prune unavailable simulators (`simctl delete unavailable`).
- **[Issue #412](https://github.com/schatt/sixlayer/issues/412)** — Move hosted / ViewInspector tests out of the unit lane so `SLF-*-UnitTests` does not host SwiftUI.
- **[Issue #411](https://github.com/schatt/sixlayer/issues/411)** — Release unit gate: single `xcodebuild test`; do not split `build-for-testing` / `test-without-building`.
- **[Issue #409](https://github.com/schatt/sixlayer/issues/409)** — macOS release gate: `.xctest` executable missing after Xcode 27 clean+test; remove clean-before-test (FB24278669).
- **[Issue #407](https://github.com/schatt/sixlayer/issues/407)** — Commit XcodeGen `project.pbxproj` regen.
- **[Issue #406](https://github.com/schatt/sixlayer/issues/406)** — iOS: `NamedAutomaticComplianceModifier` `unsafeBitCast` crash on ExpandableCardCollectionView; host sentinel.
- **[Issue #405](https://github.com/schatt/sixlayer/issues/405)** — Release gate: `xcodebuild clean` before unit tests on default DerivedData (superseded for Xcode 27 by #409).
- **[Issue #404](https://github.com/schatt/sixlayer/issues/404)** — Split batch OCR (`supportsOCR`) from Scan accessory (`displayOCR`); stop inferring flags from `ocrHints` / `calculationGroups`.
- **[Issue #400](https://github.com/schatt/sixlayer/issues/400)** — macOS UITests: deep-link launch args fail to open hosts on self-hosted CI.
- **[Issue #395](https://github.com/schatt/sixlayer/issues/395)** — Relocate VI-preferring / ComponentAccessibility suites after secondary-lane observation; `ResponsiveGrid` named compliance.
- **[Issue #391](https://github.com/schatt/sixlayer/issues/391)** — Prepare v8.3.5 release (docs / `--docs`; recorded on this milestone).
- **[Issue #390](https://github.com/schatt/sixlayer/issues/390)** — Per-platform release unit-test gate stamps.
- **[Issue #389](https://github.com/schatt/sixlayer/issues/389)** — Eliminate macOS/iOS build-for-testing warnings.
- **[Issue #388](https://github.com/schatt/sixlayer/issues/388)** — Remove leftover Inspectable from ViewInspectorTestKit smoke tests.
- **[Issue #386](https://github.com/schatt/sixlayer/issues/386)** — Route remaining hard-coded 400×300 frames through `PlatformPresentationSize` (also in v8.3.5 notes).
- **[Issue #381](https://github.com/schatt/sixlayer/issues/381)** — Move non-ViewInspector suites out of ViewInspectorTests for secondary unit lanes.
- **[Issue #371](https://github.com/schatt/sixlayer/issues/371)** — iOS XCUI: Layer5 `voiceOverEnabled` contract id empty; Category E clipboard timing.

---

## 📚 References

- [RELEASE_v8.3.5.md](RELEASE_v8.3.5.md) — Previous patch.
- [RELEASES.md](RELEASES.md) — Release history index.
- [OCRFieldHintsGuide.md](../Framework/docs/OCRFieldHintsGuide.md) — OCR flag migration.
