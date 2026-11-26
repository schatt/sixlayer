# SixLayer Framework v8.8.2 Release Documentation

**Release Date**: November 26, 2026  
**Release Type**: Patch  
**Previous Release**: v8.8.1  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.8.2 is a **patch** on v8.8.1. It carries the `next` integration line from v8.8.1 forward: the #562 stepper range fix, the #683 form-draft docs note, and the Display OCR training/lab extraction that moved lab tooling out of the Framework.

This file does not claim the test suite passed for this release until the release script's unit-test gate (macOS + iOS) passes. Tests are run by `Development/scripts/release-process.sh`, not pre-run by the agent.

---

## 🆕 New in this tag (since v8.8.1)

### DynamicStepperField range and display fixes — Issue #562

`DynamicStepperField` no longer traps on inverted or non-finite range bounds:

- Inverted `expectedRange` (for example `40:-20`) and inverted metadata `min`/`max` are ordered before building the `ClosedRange`.
- Non-finite (`nan`, `inf`) bounds fall back to the metadata or default range instead of trapping.
- The displayed value uses a shared, non-trapping formatter (`platformStepperValueText`) instead of `Int(...)` conversion, so non-finite values render as an em dash rather than crashing.

Merged from `wip/683-562-draft-docs-stepper-range` into `next` (`f2487c44c`).

### Legacy form-draft `Data` note — Issue #683

`Framework/docs/FormAutoSaveGuide.md` documents that form drafts saved before tagged `Data` encoding (#674) cannot be restored: they contain `String(describing:)` output, not base64. Docs only; no code change. Duplicate issue #682 was closed in favor of #683.

### Display OCR training and lab code moved out of the Framework — Issues #701, #702, #703, #706, #707

- The Display OCR training UI, lab evaluation, and bulk-check types were removed from `SixLayerFramework` and moved to the `display-ocr-lab` project (#706). The Framework `project.yml` no longer defines the lab targets or schemes.
- The runtime panel model still loads at runtime; the Create ML training API was dropped from the Framework.
- Training UI: two-pane layout, async decode, row-draw feedback, quieter SevenSegmentOCR traces (#702).
- Training schemes run as Release (#703).
- BulkCheck entry renamed away from `main.swift` (#701).
- xcstrings `Decode failed` / `Decoded` keys marked as manual (#707).

### Display OCR normalized box restored — runtime geometry

`DisplayOCRNormalizedBox` is restored as the runtime OCR geometry type, with unit tests for panel locator load and normalized box behavior.

---

## ⚠️ Migration / consumer notes

- The Display OCR training and lab types shipped in v8.8.0 and were removed in this tag. The maintainer confirmed there are no external consumers of these types; no migration path is provided. Lab tooling lives in `display-ocr-lab`.
- No other public API changes are called out for this patch beyond the fixes above.

---

## 🧪 Known open issues (not fixed in this tag)

- [Issue #709](https://github.com/schatt/sixlayer/issues/709) — `#550` presentation suite is not discovered in the iOS unit lane.
- [Issue #710](https://github.com/schatt/sixlayer/issues/710) — Layer 4 gauge `Int` labels can trap.
- [Issue #711](https://github.com/schatt/sixlayer/issues/711) — Layer 6 `Int` conversions (suspected trap; unverified).

---

## 📚 References

- Previous: [RELEASE_v8.8.1.md](RELEASE_v8.8.1.md)
- Prep: [Issue #712](https://github.com/schatt/sixlayer/issues/712)
- Related: [Issue #562](https://github.com/schatt/sixlayer/issues/562), [Issue #683](https://github.com/schatt/sixlayer/issues/683), [Issue #682](https://github.com/schatt/sixlayer/issues/682) (duplicate), [Issue #706](https://github.com/schatt/sixlayer/issues/706), [Issue #702](https://github.com/schatt/sixlayer/issues/702)
