# SixLayer Framework v8.6.0 Release Documentation

**Release Date**: September 28, 2026  
**Release Type**: Minor  
**Previous Release**: v8.5.1  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.6.0 is the next cut. Theme: forms product and primary-lane coverage (advanced field types, L5/L6 unit-lane clusters, thin pull-to-refresh XCUI sentinel). Epic #426 stays on Full Tests. Secondary-platform host apps stay on v8.7.0 / Full Tests.

Product highlights on `next` since v8.5.1:

1. **Advanced field types (#403, #522–#525)** — pure `FileUploadValidation`, drop/browse wired to allowed types and the system file importer, and `RichTextFormatting` / toolbar format actions.
2. **Form packing (#486)** — `GenericFormView` honors `FormStrategy.fieldLayout`.
3. **Modals / settings window (#507, #508)** — `platformAlert` / `platformConfirmationDialog` present; `platformDismissWindowSettings` no longer closes the key window on apply.
4. **macOS XCUI harness (#499, #510, #515–#521)** — TestApp host open, `platformTap`, SD150/smoke/Layer4 focus contracts, empty-collection focus platter.
5. **Primary-lane coverage (#452, #468–#470, #490, #491, #503, #512, #513)** — unit zeros, example Sources, honest a11y label tests, SPM lane hygiene, PTR sentinel.

Published release notes are not revised after a tag. Milestone issues that already shipped in an older tag, and were omitted from that tag's notes, are named here with the tag that contained them.

This file does not claim the suite was run for a release until the release script's test gate passes. Docs prep: [#535](https://github.com/schatt/sixlayer/issues/535), [#536](https://github.com/schatt/sixlayer/issues/536). Earlier draft: [#531](https://github.com/schatt/sixlayer/issues/531).

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

## 🆕 New in this tag (since v8.5.1) — on `next`, not yet tagged

### Advanced field types (#403)

Pure `FileUploadValidation` (type/size gates, `accepted(from:)`) plus ViewInspector coverage for rich-text edit presentation, suggestion pick, and `FileUploadArea` named accessibility identity. `RichTextEditorField(..., initiallyEditing:)` seeds edit mode for hosted observation. Drop acceptance filters through validation before `onFilesSelected`.

### File upload drop and browse (#525, #522)

- **#525** — Drop load identifiers follow `allowedTypes` via `FileUploadValidation.dropLoadTypes` / `resolvedType` / `fileInfo`. Empty `allowedTypes` keeps historical image+pdf probes.
- **#522** — Browse opens the system importer through `platformFileImporter`; `acceptedFiles(from:allowedTypes:maxFileSize:)` shares helpers with drop. `selectFiles` stubs removed.

### Rich text format actions (#523)

`RichTextFormatting.apply` for bold/italic/underline/bullet/numbered (markdown/`<u>` wraps on `String` storage). `RichTextToolbar(text:selectedText:)` mutates via the helper (breaking vs selectedText-only). Invalid `NSRange` is a no-op.

### Post-#403 hygiene (#524)

No soft-skip when the suggestion button is missing; one `handleDrop` path; one FileUploadArea accessibility observation host. Related cleanup off-milestone: [#530](https://github.com/schatt/sixlayer/issues/530) (unused `DispatchGroup` on the drop path).

### Form packing (#486)

`GenericFormView` packing uses `FormStrategy.fieldLayout` (closed after the v8.5.1 tag).

### Alerts and confirmation dialogs (#507)

`platformAlert(isPresented:title:actions:message:)` and `platformConfirmationDialog(...)` follow the caller's binding. Replaces the old `Alert.Button` signature that hardcoded `.constant(false)` and never presented. Source break for the unused old call shape.

### Settings window dismiss (#508)

`platformDismissWindowSettings()` / `(onClose:)` no longer close the macOS key window while the modifier is applied. Close runs from the Done control (`platformDismissWindowSettings.close`) or the caller action. Other platforms still return `self`.

### Accessibility label test honesty (#503)

`AutomaticAccessibilityLabelTests` and related localization asserts no longer pass on `!isEmpty` when the catalog returns the raw key (`FrameworkCatalogFixture` / #501 pattern).

### Unit-lane coverage (#468, #469, #470, #490, #491, #513)

- **#468** — Platform UI extension zeros (non-example).
- **#469** — Components Views and Navigation zeros.
- **#470** — `AccessibilityFeatures` and IntelligentCardExpansion L5/L6.
- **#490** — Remaining Framework example Sources (`ExampleHelpers`, `ExtensibleHints`).
- **#491** — Replace tautological DesignSystem UITest theming `XCTAssertNotNil` cases.
- **#513** — `PlatformGraphicsExtensions` and `PlatformOCRSafetyExtensions`. **#514** is the same filing (also closed completed).

### SixLayerTestKit platformTap (#510)

`XCUIElement.platformTap(numberOfTaps:numberOfTouches:)` and `PlatformXCUITapStrategy` for cross-platform XCUI multi-tap. **#511** is the same filing (also closed).

### SPM BaseTestClass lane hygiene (#512)

SwiftPM `PlatformManagedSettingsFlowLogicTests` no longer compiles Layer 4 files that need `BaseTestClass`. Those stay on the Xcode unit lane.

### macOS XCUI host and navigation (#499, #515, #516)

- **#499** — macOS CI UITests open the TestApp host (stale red after #497).
- **#515** — SD150 `typeText` / focus / integration toggle blur.
- **#516** — UITestNavigator macOS click for goToScreen / openSection / back. **#517** is a not-planned duplicate of #516.

### macOS Layer 4 UITests (#518)

Sheet, popover, navigation, and overlay contracts use macOS `click()` instead of `tap()`. Landed with #499. **#519** and **#520** are not-planned duplicates.

### Empty collection focus platter (#521)

Empty `platformPresentItemCollection_L1` no longer paints an off-center accent focus platter. Keyboard navigation on the collection container is identifier compliance only.

### Pull to refresh sentinel (#452)

XCUITest sentinel: `platformIOSPullToRefresh` fires `onRefresh`.

### Duplicate filings (not separate changes)

- **#526** — not-planned twin of #523.
- **#527** — not-planned twin of #522.

### Docs

- **#531** — Initial draft of these notes.
- **#535** — Closed-milestone coverage rewrite (remove stale open list).
- **#536** — Version-pointer bumps for the release-script gates (Current Release, AI_AGENT, README/Package badges).

---

## ⚠️ Migration / consumer notes

### File upload (#403, #522, #525)

`FileUploadArea` browse opens a system file importer. Drop and browse both honor `allowedTypes` / max size via `FileUploadValidation`. Call sites that relied on unrestricted drop loads or stub browse should verify allowed UTTypes and the `onFilesSelected` callback.

### Rich text toolbar (#523)

`RichTextToolbar` now requires a `text` binding and applies format wraps to that string. Update hosts that only passed `selectedText`.

### platformAlert / platformConfirmationDialog (#507)

Migrate off the old `Alert.Button` signature to `isPresented` + `title` + `actions` + `message`. The old call never presented.

### platformDismissWindowSettings (#508)

Do not assume applying the modifier closes a macOS settings window. Wire dismiss to the Done control or supply `onClose`.

### SixLayerTestKit platformTap (#510)

Prefer `platformTap` over raw `tap(withNumberOfTaps:)` when writing cross-platform XCUI helpers.

### Not in this cut

- Epic **#426** and Full Tests / secondary-platform host apps (v8.7.0 / Full Tests).
- Attributed-string / UITextView attribute path for rich text (optional follow-on; not filed as required for 8.6.0).

---

## ✅ Resolved GitHub issues (milestone v8.6.0)

### New since v8.5.1 (this cut)

- **[Issue #403](https://github.com/schatt/sixlayer/issues/403)** — Advanced field types: unit-testable validation + VI for interaction/a11y.
- **[Issue #452](https://github.com/schatt/sixlayer/issues/452)** — XCUITest sentinel: `platformIOSPullToRefresh` fires `onRefresh`.
- **[Issue #468](https://github.com/schatt/sixlayer/issues/468)** — Unit-lane coverage: Platform UI extension zeros (non-example).
- **[Issue #469](https://github.com/schatt/sixlayer/issues/469)** — Unit-lane coverage: Components Views + Navigation zeros.
- **[Issue #470](https://github.com/schatt/sixlayer/issues/470)** — Deepen unit coverage: AccessibilityFeatures + IntelligentCardExpansion L5/L6.
- **[Issue #486](https://github.com/schatt/sixlayer/issues/486)** — `GenericFormView` packing ignores `FormStrategy.fieldLayout`.
- **[Issue #490](https://github.com/schatt/sixlayer/issues/490)** — Remove or cover remaining Framework example Sources.
- **[Issue #491](https://github.com/schatt/sixlayer/issues/491)** — Replace tautological DesignSystemUITests theming `XCTAssertNotNil` cases.
- **[Issue #499](https://github.com/schatt/sixlayer/issues/499)** — macOS CI UITests fail to open TestApp host.
- **[Issue #503](https://github.com/schatt/sixlayer/issues/503)** — Accessibility label tests pass when localization returns the raw key.
- **[Issue #507](https://github.com/schatt/sixlayer/issues/507)** — `platformAlert` and `platformConfirmationDialog` never present.
- **[Issue #508](https://github.com/schatt/sixlayer/issues/508)** — `platformDismissWindowSettings` closes the key window from a view modifier.
- **[Issue #510](https://github.com/schatt/sixlayer/issues/510)** — SixLayerTestKit: `platformTap` for cross-platform XCUI multi-tap.
- **[Issue #511](https://github.com/schatt/sixlayer/issues/511)** — Twin of #510 (same change).
- **[Issue #512](https://github.com/schatt/sixlayer/issues/512)** — SPM PlatformManagedSettingsFlowLogicTests: `BaseTestClass` out of scope.
- **[Issue #513](https://github.com/schatt/sixlayer/issues/513)** — Unit-lane: PlatformGraphics + PlatformOCRSafety extensions.
- **[Issue #514](https://github.com/schatt/sixlayer/issues/514)** — Twin of #513 (same change).
- **[Issue #515](https://github.com/schatt/sixlayer/issues/515)** — macOS SD150 UITests: typeText fails — no keyboard focus.
- **[Issue #516](https://github.com/schatt/sixlayer/issues/516)** — macOS smoke UITest: openSection does not resolve detail marker.
- **[Issue #517](https://github.com/schatt/sixlayer/issues/517)** — Not-planned duplicate of #516.
- **[Issue #518](https://github.com/schatt/sixlayer/issues/518)** — macOS Layer4 UITests: sheet/popover/nav/overlay contracts.
- **[Issue #519](https://github.com/schatt/sixlayer/issues/519)** — Not-planned duplicate of #518.
- **[Issue #520](https://github.com/schatt/sixlayer/issues/520)** — Not-planned duplicate of #518.
- **[Issue #521](https://github.com/schatt/sixlayer/issues/521)** — macOS empty collection paints an off-center blue focus platter.
- **[Issue #522](https://github.com/schatt/sixlayer/issues/522)** — Wire system file picker for `FileUploadArea.selectFiles`.
- **[Issue #523](https://github.com/schatt/sixlayer/issues/523)** — Implement RichTextToolbar format actions.
- **[Issue #524](https://github.com/schatt/sixlayer/issues/524)** — Post-#403 hygiene: soft-skip + handleDrop DRY + FileUploadArea a11y host.
- **[Issue #525](https://github.com/schatt/sixlayer/issues/525)** — FileUploadArea drop: honor `allowedTypes` for load identifiers.
- **[Issue #526](https://github.com/schatt/sixlayer/issues/526)** — Not-planned duplicate of #523.
- **[Issue #527](https://github.com/schatt/sixlayer/issues/527)** — Not-planned duplicate of #522.
- **[Issue #531](https://github.com/schatt/sixlayer/issues/531)** — Draft v8.6.0 release notes.
- **[Issue #535](https://github.com/schatt/sixlayer/issues/535)** — Prepare v8.6.0 release notes (docs).
- **[Issue #536](https://github.com/schatt/sixlayer/issues/536)** — v8.6.0 release doc version bumps (script gates).

### Already shipped (still on this milestone)

- **[Issue #396](https://github.com/schatt/sixlayer/issues/396)** — CI after #381 (v8.3.6).
- **[Issue #409](https://github.com/schatt/sixlayer/issues/409)** — macOS unit `.xctest` after clean+test (v8.3.6).
- **[Issue #433](https://github.com/schatt/sixlayer/issues/433)** — Hung macOS ViewInspector kill/retry (v8.3.7).
- **[Issue #434](https://github.com/schatt/sixlayer/issues/434)** — Stall-wrapper EAGAIN crash (v8.3.7).
- **[Issue #436](https://github.com/schatt/sixlayer/issues/436)** — Cancel Layer 1 OCR on disappear (v8.3.7).
- **[Issue #458](https://github.com/schatt/sixlayer/issues/458)** — Layer 6 CrossPlatformOptimization + PlatformPerformance (v8.4.0).
- **[Issue #467](https://github.com/schatt/sixlayer/issues/467)** — Layer 4 component zeros (v8.5.1).
- **[Issue #471](https://github.com/schatt/sixlayer/issues/471)** — Numeric select-all on begin editing (v8.5.0).
- **[Issue #505](https://github.com/schatt/sixlayer/issues/505)** — Prepare v8.5.1 patch notes.
- **[Issue #506](https://github.com/schatt/sixlayer/issues/506)** — Twin of #505.

---

## 📚 References

- [RELEASE_v8.5.1.md](RELEASE_v8.5.1.md) — Previous release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [#531](https://github.com/schatt/sixlayer/issues/531) — Initial draft.
- [#535](https://github.com/schatt/sixlayer/issues/535) — Closed-milestone rewrite.
- [#536](https://github.com/schatt/sixlayer/issues/536) — Version-pointer / script-gate bumps.
