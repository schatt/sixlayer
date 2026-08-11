# SixLayer Framework v8.3.6 Release Documentation

**Release Date**: TBD  
**Release Type**: Patch (planned)  
**Previous Release**: v8.3.5  
**Status**: Draft — accumulate notes while landing milestone work; finalize at release prep.

---

## 🎯 Release Summary

v8.3.6 is a **patch** release. Entries below are seeded as issues land; expand before tagging.

Notable consumer-facing change: **#404** — `applying(hints:)` no longer infers `supportsOCR` / `displayOCR` / `isCalculated` from `ocrHints` or `calculationGroups` (see Migration notes).

---

## ⚠️ Migration / consumer notes

### `applying(hints:)` — OCR / calculation flags no longer inferred (#404)

`FieldDisplayHints.ocrHints` and `calculationGroups` are data only. Applying them **does not** flip field feature flags.

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
- **Consumer impact:** Generated accessibility identifiers for `ResponsiveGrid` now include the `ResponsiveGrid` name segment (e.g. `…ResponsiveGrid…`) instead of relying solely on child content IDs.
- **Action:** If UI tests or tooling matched anonymous / `main.ui.element`-style IDs for grid shells, update queries to the named form.

Commit: `663eb97c` on `wip/395-relocate-vi-preferring-suites` (lands with #395).

---

## ✅ Resolved GitHub issues (v8.3.6)

- **[Issue #404](https://github.com/schatt/sixlayer/issues/404)** — Split batch OCR (`supportsOCR`) from Scan accessory (`displayOCR`); stop inferring flags from `ocrHints` / `calculationGroups`. *(close when LRC complete)*
- **[Issue #395](https://github.com/schatt/sixlayer/issues/395)** — Relocate VI-preferring / ComponentAccessibility suites after secondary-lane observation; `ResponsiveGrid` named compliance for observable IDs. *(close when LRC complete)*

*(Add further closed milestone issues here as they land.)*

---

## 📚 References

- [RELEASE_v8.3.5.md](RELEASE_v8.3.5.md) — Previous patch.
- [RELEASES.md](RELEASES.md) — Release history index.
