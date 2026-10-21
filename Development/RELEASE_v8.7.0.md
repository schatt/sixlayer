# SixLayer Framework v8.7.0 Release Documentation

**Release Date**: October 21, 2026  
**Release Type**: Minor  
**Previous Release**: v8.6.7  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.7.0 is a **minor** on v8.6.7. The consumer-facing addition is a seven-segment recognizer, `OCRProcessingMode.ssocr`. Existing OCR callers stay on the v8.6.7 Vision path because `OCRContext.processingMode` still defaults to `.accurate`.

The same cut fixes form hints for optional models, claims each Vision continuation once, stops the string catalog from rewriting itself on every build, and routes the remaining macOS UITest taps through `platformTap`.

The release script's unit gate passed macOS (`SLF-macOS-UnitTests`) and iOS (`SLF-iOS-UnitTests`) at `e57e1fead` before these notes were written. These notes do not re-run that suite.

---

## 🆕 New in this tag (since v8.6.7)

### Seven-segment OCR (#576)

`OCRProcessingMode.ssocr` (raw value `"ssocr"`, display name "Seven-segment") decodes a panel of digits and marks. It is not a Vision recognition level, and there is no combined mode.

`processImage` with `.ssocr` reads segments and does not create `VNRecognizeTextRequest`. `processStructuredExtraction` decodes the segments and, unless the caller passed `suppliedLabelFragments`, runs one Vision label pass. Vision does not supply the digit characters. If that label pass throws, the segment result is still returned. The 0.35 observation drop and `OCRResult.filtered(by:)` stay off this path.

`OCRRecognizedText` carries `text`, a Vision-normalized `boundingBox`, `confidence`, and `role` (`.segment` or `.label`). `extractedText`, `boundingBoxes`, and `OCRResult.confidence` come from segment fragments only. Same-row segments join with two spaces. Rows join with newlines, top to bottom. A wide gap splits groups on a row. A row break is an empty vertical run at least half the shorter band. Glyphs are `0–9`, `.`, `,`, `-`, and `:`. An occupied cell that is not a unique glyph is `_`. Empty ink is not a fragment.

`OCRContext.segmentDeskewMaximumDegrees` defaults to 3. Angle 0 wins unless another angle beats it by more than about 2 percent. Both ink polarities are read. A local threshold keeps a glare band from erasing digits. Thresholds scale with the panel: ink against the corner background, speck size against digit height, and a bridged span splits only when it is wider than twice the digits in that row.

Label binding is geometric. The decoder source does not name fuel-purchase fields. CarManager sale assignment stays in CarManager #1157, the review sheet in #1155, and retail-price bands in #1324.

### Optional form hints and one model-name stem (#581, #585)

`generateForm(for:initialData:)` looked up hints under `Optional<T>`, so a form built from an optional model rendered no fields. Lookup now uses the unwrapped model type. `DataIntrospectionEngine.hintsModelName(for:)` is the single stem for form and introspection paths. It takes the last component of the type name. It does not strip `Optional<>`; callers pass the unwrapped type.

`DataBinder` was public as a type while `init` and `bind` were not, so another module could not register fields for `generateForm(for:dataBinder:)`. `init(_:)`, `bind(_:to:)`, `bindKVC(_:)`, both `bindAuto` overloads, and `hasBinding(for:)` are now public.

### Vision resumes once (#563, #574, #578, #579)

`OCRService.performVisionOCR` trapped when Vision's completion and `VNImageRequestHandler.perform` both resumed the same continuation. A `VisionContinuationGate` lets the first claim win. `runVisionRequest` is that shared runner. `OCRService` sends its Vision OCR through it. Barcode detection and safe Vision OCR use the same single-resume path. The unused Vision wrapper that failed Swift 6 isolation is gone.

### String catalog (#577)

`Localizable.xcstrings` is curated. Entries use `extractionState: manual`, so a build no longer rewrites the catalog. The xcstrings guard runs in CI. The old `.lproj` completeness checker is retired.

### macOS UITests and `platformTap` (#567, #568, #569, #570, #575, #580, #586, #587)

Host-identifier sheets, clipboard generation, Category C selection, and Category D overlay stayed idle because those suites still called `tap()` on macOS. They now activate with `platformTap`. The same helper covers the remaining macOS `tap()` call sites, including generated UI-test snippets that were still emitting `element.tap()`. #580 is the suite check after the #499 host-open fix; the idle failures were these tap sites.

### Retire script (#564)

`retire_wip_branch.sh` used to abort when one push URL had no `wip/` ref. A missing ref on one remote no longer stops worktree removal or deletion of the local `done/` branch.

### Already published on v8.6.7 (#560, #565)

The focused form editor (#560) and the v8.6.7 notes (#565) are on this milestone and already shipped in v8.6.7. They are not new in v8.7.0.

---

## ⚠️ Migration / consumer notes

No public signature removal. Set `OCRContext.processingMode = .ssocr` to opt into the segment decoder. Leaving the default keeps `.accurate` Vision OCR.

A consumer that constructs `DataBinder` from another module can now call `init` and `bind`. Hints files are looked up by the unwrapped model name, not `Optional<Model>`.

---

## ✅ Resolved GitHub issues

- **[Issue #576](https://github.com/schatt/sixlayer/issues/576)** — Seven-segment mode decodes multi-row panels.
- **[Issue #581](https://github.com/schatt/sixlayer/issues/581)** — Optional initial data looks up the unwrapped model name. `DataBinder` init and bind are public.
- **[Issue #585](https://github.com/schatt/sixlayer/issues/585)** — One hints model-name stem for forms and introspection.
- **[Issue #563](https://github.com/schatt/sixlayer/issues/563)** — `performVisionOCR` resumes its continuation once.
- **[Issue #574](https://github.com/schatt/sixlayer/issues/574)** — Barcode and safe Vision OCR resume once. The unused wrapper is removed.
- **[Issue #578](https://github.com/schatt/sixlayer/issues/578)** — Barcode and safe Vision OCR call the shared runner.
- **[Issue #579](https://github.com/schatt/sixlayer/issues/579)** — `OCRService` Vision OCR calls `runVisionRequest`.
- **[Issue #577](https://github.com/schatt/sixlayer/issues/577)** — The string catalog is curated and guarded in CI.
- **[Issue #567](https://github.com/schatt/sixlayer/issues/567)** — Host-identifier sheet content is reached with `platformTap`.
- **[Issue #568](https://github.com/schatt/sixlayer/issues/568)** — Clipboard generation is reached with `platformTap`.
- **[Issue #569](https://github.com/schatt/sixlayer/issues/569)** — Category C selection and form callbacks are reached with `platformTap`.
- **[Issue #570](https://github.com/schatt/sixlayer/issues/570)** — Category D overlay and disambiguation are reached with `platformTap`.
- **[Issue #575](https://github.com/schatt/sixlayer/issues/575)** — Remaining macOS UITest `tap()` calls go through `platformTap`.
- **[Issue #580](https://github.com/schatt/sixlayer/issues/580)** — macOS UITest check after the host-open fix.
- **[Issue #586](https://github.com/schatt/sixlayer/issues/586)** — Remaining XCUI `tap()` calls go through `platformTap`.
- **[Issue #587](https://github.com/schatt/sixlayer/issues/587)** — Snippet generators emit `platformTap`.
- **[Issue #564](https://github.com/schatt/sixlayer/issues/564)** — Retire continues when one push URL has no `wip/` ref.
- **[Issue #560](https://github.com/schatt/sixlayer/issues/560)** — Focused form editors. Shipped in v8.6.7.
- **[Issue #565](https://github.com/schatt/sixlayer/issues/565)** — v8.6.7 release notes. Shipped in v8.6.7.
- **[Issue #590](https://github.com/schatt/sixlayer/issues/590)** — These release notes.

---

**Next Release**: v8.7.1
