# SixLayer Framework v8.6.0 Release Documentation

**Release Date**: Not tagged  
**Release Type**: Minor  
**Previous Release**: v8.5.1  
**Status**: Draft (not a release cut)

---

## 🎯 Release Summary

v8.6.0 is the next cut. Theme: forms product and primary-lane coverage (advanced field types, L5/L6 unit-lane clusters, thin pull-to-refresh XCUI sentinel). Epic #426 stays on Full Tests. Secondary-platform host apps stay on v8.7.0 / Full Tests.

Published release notes are not revised after a tag. Milestone issues that already shipped in an older tag, and were omitted from that tag's notes, are named here with the tag that contained them.

This file does not tag, bump the version, or claim the suite was run for a release.

---

## 📦 Already shipped (omitted from that tag's notes)

### Shipped in v8.3.6

- **[#396](https://github.com/schatt/sixlayer/issues/396)** — CI failures after the #381 merge (ViewInspector `TestDataItem`, destinations, UITests). Closed 2026-08-02, before the v8.3.6 tag (2026-08-15).
- **[#409](https://github.com/schatt/sixlayer/issues/409)** — macOS release gate: unit-test `.xctest` executable missing after Xcode 27 clean+test. Named in the v8.3.6 notes as a fix; the issue itself had no milestone until this cut.

### Shipped in v8.3.7

- **[#433](https://github.com/schatt/sixlayer/issues/433)** — Kill and retry a hung macOS ViewInspector `xcodebuild` in self-hosted CI.
- **[#434](https://github.com/schatt/sixlayer/issues/434)** — Stall-wrapper crash on drain-time `EAGAIN` after tests had already passed.
- **[#436](https://github.com/schatt/sixlayer/issues/436)** — Cancel Layer 1 OCR work when the hosting view disappears.

v8.3.7 notes mention these three. The issues had no milestone until this cut.

### Shipped in v8.4.0

- **[#458](https://github.com/schatt/sixlayer/issues/458)** — Layer 6 coverage for `CrossPlatformOptimization` and `PlatformPerformance`. Closed 2026-09-07, before the v8.4.0 tag (2026-09-08). Not named in the v8.4.0 notes.

### Shipped in v8.5.0

- **[#471](https://github.com/schatt/sixlayer/issues/471)** — Numeric fields select their entire contents on begin editing. Closed 2026-09-10, before the v8.5.0 tag. v8.5.0 notes name the select-all opt-in as #472 and do not name #471.

### Shipped in v8.5.1

- **[#467](https://github.com/schatt/sixlayer/issues/467)** — Unit-lane coverage for Layer 4 component zeros. Closed 2026-09-21T17:17:06Z, the same moment as the v8.5.1 GitHub release. The v8.5.1 notes still say it was in progress and not in that tag.
- **[#505](https://github.com/schatt/sixlayer/issues/505)** — Prepare the v8.5.1 patch notes (`--docs`).
- **[#506](https://github.com/schatt/sixlayer/issues/506)** — Not-planned twin of #505. Not a separate change.

---

## 🆕 On `next` since v8.5.1 (not yet tagged)

### Forms

- **[#486](https://github.com/schatt/sixlayer/issues/486)** — `GenericFormView` packing uses `FormStrategy.fieldLayout`. Closed 2026-09-21, after the v8.5.1 tag.
- **[#524](https://github.com/schatt/sixlayer/issues/524)** — Post-#403 hygiene: no soft-skip when the suggestion button is missing, one `handleDrop` path, one FileUploadArea accessibility observation.

### Unit-lane coverage

- **[#468](https://github.com/schatt/sixlayer/issues/468)** — Platform UI extension zeros (non-example).
- **[#469](https://github.com/schatt/sixlayer/issues/469)** — Components Views and Navigation zeros.
- **[#470](https://github.com/schatt/sixlayer/issues/470)** — `AccessibilityFeatures` and IntelligentCardExpansion L5/L6.
- **[#490](https://github.com/schatt/sixlayer/issues/490)** — Remaining Framework example Sources (`ExampleHelpers`, `ExtensibleHints`). Closed after the v8.5.1 tag.
- **[#491](https://github.com/schatt/sixlayer/issues/491)** — Replace tautological DesignSystem UITest theming `XCTAssertNotNil` cases.
- **[#513](https://github.com/schatt/sixlayer/issues/513)** — Unit-lane `PlatformGraphicsExtensions` and `PlatformOCRSafetyExtensions`. #514 is the same filing, also closed completed.

### macOS UI

- **[#518](https://github.com/schatt/sixlayer/issues/518)** — Layer 4 sheet, popover, navigation, and overlay UITests: macOS `click()` instead of `tap()`. Landed with #499. #519 and #520 are not-planned duplicates.
- **[#521](https://github.com/schatt/sixlayer/issues/521)** — Empty `platformPresentItemCollection_L1` no longer paints an off-center accent focus platter. Keyboard navigation on the collection container is identifier compliance only.

### Pull to refresh

- **[#452](https://github.com/schatt/sixlayer/issues/452)** — XCUITest sentinel: `platformIOSPullToRefresh` fires `onRefresh`.

---

## 🚧 Still open (not in the cut until done)

- **[#403](https://github.com/schatt/sixlayer/issues/403)** — Advanced field types. Reopened. Validation and hosted interaction landed; the follow-ups below are still open.
- **[#525](https://github.com/schatt/sixlayer/issues/525)** — `FileUploadArea` drop still loads only image/pdf identifiers and ignores broader `allowedTypes`.
- **[#526](https://github.com/schatt/sixlayer/issues/526)** — `RichTextToolbar` bold/italic/underline (and list formats) are still placeholders. #523 is the shorter duplicate and stays closed.
- **[#527](https://github.com/schatt/sixlayer/issues/527)** — `FileUploadArea.selectFiles()` is still a stub; Browse does not open a system picker. #522 is the shorter duplicate and stays closed.
- **[#503](https://github.com/schatt/sixlayer/issues/503)** — Accessibility label tests still pass when localization returns the raw key.

---

## 📚 References

- [RELEASE_v8.5.1.md](RELEASE_v8.5.1.md) — Previous release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [#531](https://github.com/schatt/sixlayer/issues/531) — This draft.
