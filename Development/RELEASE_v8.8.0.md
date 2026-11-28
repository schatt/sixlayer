# SixLayer Framework v8.8.0 Release Documentation

**Release Date**: November 16, 2026
**Release Type**: Minor
**Previous Release**: v8.7.1
**Status**: Prepared for release gate

---

## 🎯 Release Summary

v8.8.0 is a **minor** on v8.7.1. It hardens seven-segment OCR on real and synthetic panels (glare, commas, edge chrome, crop geometry), adds Live Photo–aware camera/photo picker paths, exposes camera cancel, improves platform navigation/sheet/button APIs, and tightens agent quality-gate and CI hygiene.

Private real-photo fixtures stay outside the package (`Development/scripts/fetch-private-fixtures.sh`); CI uses `SIXLAYER_FIXTURES_TOKEN`.

---

## 🆕 New in this tag (since v8.7.1)

### Seven-segment OCR reliability

Segment decode and panel localization handle washed bezels, glare, pale commas, edge-flush glyphs, upright single-line crops, and adaptive ink thresholds. Synthetic and real-photo gates cover the regressions that landed on `next` after v8.7.1. An OCR lab CLI can bulk-check labeled image folders.

### Camera and photo capture

Photo picker and camera paths can return Live Photo motion. `platformCameraInterface_L4(onImageCaptured:)` exposes `onCancel`.

### Platform chrome and forms

`platformButton` gains systemImage and custom label overloads. macOS sheet/navigation stacks align with iOS NavigationStack wrapping. Forms can hide framework Submit chrome via `DynamicFormConfiguration.showsSubmitButton`. Draft Date / MultiDate round-trips are covered; pre-#672 `String(describing: Date)` drafts remain unrecoverable as Dates.

### Process and CI

`/2` quality gate must run before land on `next` and must surface in agent chat. CI simulator destinations, codesign retry, ViewInspector stalls, and snippet `platformTap` emission are tightened.

---

## ⚠️ Migration / consumer notes

No public signature removals intended. Opt into Live Photo capture/picker where new APIs are used. OCR callers that rely on private fixtures need `fetch-private-fixtures.sh` (and CI secret `SIXLAYER_FIXTURES_TOKEN`). Form drafts written before #672 with `String(describing: Date)` will not restore as `Date`.

---

## ✅ Resolved GitHub issues

- **[Issue #233](https://github.com/schatt/sixlayer/issues/233)** — Run Full Test Suite for Every Platform. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #399](https://github.com/schatt/sixlayer/issues/399)** — CI: ensure tvOS/watchOS/visionOS simulator destinations for unit AllTests. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #460](https://github.com/schatt/sixlayer/issues/460)** — watchOS: hosted identifier config ignores Environment when TaskLocal is missing. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #461](https://github.com/schatt/sixlayer/issues/461)** — ViewInspector CI stalls: iOS BarcodeScanning + macOS LocalEnableOverride. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #463](https://github.com/schatt/sixlayer/issues/463)** — Coverage inventory remesasure (post #450/#453–#458). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #588](https://github.com/schatt/sixlayer/issues/588)** — UI-test snippet generators still emit element.tap(). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #595](https://github.com/schatt/sixlayer/issues/595)** — rescannedRowCropMatchesPriceBandGeometry fails (got garbage / "8") on #591 B and combined tips. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #598](https://github.com/schatt/sixlayer/issues/598)** — OCR: washed bezel synthetic (bezelDarkerThanTheGlassKeepsWashedDigits) red on next @ c3abcf9be. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #599](https://github.com/schatt/sixlayer/issues/599)** — OCR: require a segment run, and size each washed row from stride. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #602](https://github.com/schatt/sixlayer/issues/602)** — OCRSevenSegment576Tests failures still red on next. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #604](https://github.com/schatt/sixlayer/issues/604)** — OCR: use a stricter core when the loose mask floods. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #610](https://github.com/schatt/sixlayer/issues/610)** — macOS UITest first launch stays Running Background. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #611](https://github.com/schatt/sixlayer/issues/611)** — macOS CI codesign fails on SixLayerFramework.cstemp after xcodebuild retry. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #612](https://github.com/schatt/sixlayer/issues/612)** — OCR: readingSpan drops glyphs when the crop is already the display. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #620](https://github.com/schatt/sixlayer/issues/620)** — Core Data save failure rolls back the whole context. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #625](https://github.com/schatt/sixlayer/issues/625)** — OCR: a tight single LCD line is read upside down. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #631](https://github.com/schatt/sixlayer/issues/631)** — OCR decimal locale may use EXIF GPS region as an optional guide. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #632](https://github.com/schatt/sixlayer/issues/632)** — OCR joint decimal correction still strips or rewrites commas by hand. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #635](https://github.com/schatt/sixlayer/issues/635)** — platformButton: systemImage and custom label ViewBuilder overloads. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #636](https://github.com/schatt/sixlayer/issues/636)** — platformSheet: align macOS NavigationStack wrapping with iOS. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #637](https://github.com/schatt/sixlayer/issues/637)** — Simple platformNavigationStack without L3 strategy. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #638](https://github.com/schatt/sixlayer/issues/638)** — platformNavigation_L4 / modal sheet chrome: wrap NavigationStack on macOS. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #639](https://github.com/schatt/sixlayer/issues/639)** — platformSheet alias vs sizes overload: navigation chrome divergence. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #640](https://github.com/schatt/sixlayer/issues/640)** — DynamicFormConfiguration: showsSubmitButton to hide framework Submit chrome. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #641](https://github.com/schatt/sixlayer/issues/641)** — OCR: zero-margin glyph crop of an upright LCD line should read that line. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #642](https://github.com/schatt/sixlayer/issues/642)** — AI_AGENT_QUICK_REFERENCE: platformMapView_L4 still documents region: API. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #643](https://github.com/schatt/sixlayer/issues/643)** — Require /2 quality gate before closing GitHub issues. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #644](https://github.com/schatt/sixlayer/issues/644)** — OCR: commaTail second row 30 becomes 3.0 (pitch mark). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #645](https://github.com/schatt/sixlayer/issues/645)** — OCR: glare fixture reads 3:1.25 instead of 31.25. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #646](https://github.com/schatt/sixlayer/issues/646)** — OCR: filledInk splits 51.07 into 5 and 1.07. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #647](https://github.com/schatt/sixlayer/issues/647)** — OCR: lowSegmentScore reads 8. instead of 8_2 / 17.740. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #648](https://github.com/schatt/sixlayer/issues/648)** — OCR: paddedCanvas / thickStrokes / strokeSized still red or pathological. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #649](https://github.com/schatt/sixlayer/issues/649)** — OCR: taller crop of top sealed LCD line should read that line. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #650](https://github.com/schatt/sixlayer/issues/650)** — Display OCR training hangs after photo-library load (full-res digitPanelRegion). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #651](https://github.com/schatt/sixlayer/issues/651)** — OCR: isotropic pad around top sealed LCD line breaks the read. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #652](https://github.com/schatt/sixlayer/issues/652)** — macOS build: MainActor / Sendable / redundant-public diagnostics. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #653](https://github.com/schatt/sixlayer/issues/653)** — macOS: DisplayOCRTraining suggest path — unnecessary nonisolated(unsafe) / await. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #654](https://github.com/schatt/sixlayer/issues/654)** — Display OCR training: Decode hangs on full-res panel crop (localRange). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #655](https://github.com/schatt/sixlayer/issues/655)** — Display OCR training: choosing Documents lists unrelated folders as Missing image. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #656](https://github.com/schatt/sixlayer/issues/656)** — /2 quality gate must run before landing on next. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #657](https://github.com/schatt/sixlayer/issues/657)** — /2 gate: surface verdicts in agent chat, not only GitHub. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #658](https://github.com/schatt/sixlayer/issues/658)** — OCR: clean 51.07  17.740 row reads volume as 17,740 (comma). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #659](https://github.com/schatt/sixlayer/issues/659)** — OCR: scale-4 strokeSized / thickStrokes still misread. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #660](https://github.com/schatt/sixlayer/issues/660)** — OCR: glareAndBothPolarities / glare colon red again on next. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #661](https://github.com/schatt/sixlayer/issues/661)** — OCR: marksStay 8_2 alone decodes empty; 1,234.56 loses comma. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #662](https://github.com/schatt/sixlayer/issues/662)** — OCR: filledInk fixture regresses to 51.0 on next. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #663](https://github.com/schatt/sixlayer/issues/663)** — Quality gate: other direction of a threshold is a real input. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #664](https://github.com/schatt/sixlayer/issues/664)** — OCR: replace hard <80 peel ink cut with adaptive darkness. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #668](https://github.com/schatt/sixlayer/issues/668)** — Photo picker: use the Photos picker everywhere and return Live Photo motion. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #669](https://github.com/schatt/sixlayer/issues/669)** — Camera interface: capture Live Photos with a custom capture view. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #670](https://github.com/schatt/sixlayer/issues/670)** — OCR: paleCommaDoesNotAskTheCorner reads 11.234.561 instead of 1,234.56. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #671](https://github.com/schatt/sixlayer/issues/671)** — DataIntrospection SwiftData test is an empty soft-skip with a false @Model claim. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #675](https://github.com/schatt/sixlayer/issues/675)** — Form drafts saved before #672 still hold String(describing: Date) that will not restore as Date. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #676](https://github.com/schatt/sixlayer/issues/676)** — AnyCodable array-of-Date (MultiDate drafts) round-trip is untested. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #677](https://github.com/schatt/sixlayer/issues/677)** — OCR lab: CLI bulk pass/fail check for labeled image folders. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #678](https://github.com/schatt/sixlayer/issues/678)** — OCR hints: regional fraction-digit / numeric format priors (distinct from fieldAverages). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #679](https://github.com/schatt/sixlayer/issues/679)** — OCR: make fieldAverages deviation threshold configurable (stop hardcoding 50%). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #681](https://github.com/schatt/sixlayer/issues/681)** — Expose onCancel on platformCameraInterface_L4(onImageCaptured:). Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.
- **[Issue #684](https://github.com/schatt/sixlayer/issues/684)** — OCR: prove edge-flush real 1 survives isEdgeChromeStrip geometry gate. Shipped on the v8.8.0 milestone; see the issue Final Record for decisions and tests.

---

**Next Release**: v8.8.1
