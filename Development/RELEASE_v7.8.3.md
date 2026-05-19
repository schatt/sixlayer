# SixLayer Framework v7.8.3 Release Documentation

**Release Date**: May 19, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.2  
**Status**: Released

---

## 🎯 Release Summary

v7.8.3 is a **patch** release focused on **pump LCD structured OCR**: label-anchored field binding (#282), calculation-group-driven joint decimal correction (#283–#287), printed price-per-gallon scoring (#284), Vision line layout preference (#285), fail-closed joint failure when no retail-plausible pair exists (#286), and locale-aware decimal parsing for volume fields (#287).

---

## 🆕 Confirmed in v7.8.3 (implemented)

### **Label-anchored structured extraction (#282, #285)**

- `OCRLabelAnchoredExtraction` binds numeric fields using bidirectional hint regexes split into separate hint-first and number-first passes (avoids alternation stealing digits on pump receipts).
- Per-line Vision recognition assignments merge over flat-text fallback; layout proximity scoring prefers line-local hints.
- `OCRService` delegates structured extraction to the label-anchoring module.

### **Joint decimal correction (#283, #284, #286, #287)**

- `OCRJointDecimalCorrection` discovers multiplication relationships from hints `calculationGroups` (not hard-coded field names).
- Joint search prefers candidates whose implied rate matches a printed price-per-gallon when present.
- Identical ambiguous product/volume strings fail closed with adjustment messaging and block per-field decimal override (#286).
- Locale-aware numeric parsing supports comma decimal separators (e.g. French `3,704` gallons).

### **Tests**

- `OCRPumpLabelAnchoredExtraction282Tests` and `OCRStructuredExtractionFollowups283Tests` (serialized) cover pump fixtures IMG5145, IMG4997, IMG5018 and follow-up scenarios.
- macOS capability runner: AssistiveTouch-vs-touch law gated to platforms that ship AssistiveTouch (release-suite stability).

---

## ✅ Resolved / advanced GitHub issues

- **[Issue #282](https://github.com/schatt/sixlayer/issues/282)** — Pump label-anchored OCR structured extraction.
- **[Issue #283](https://github.com/schatt/sixlayer/issues/283)** — Joint decimal correction uses calculation-group field names.
- **[Issue #284](https://github.com/schatt/sixlayer/issues/284)** — Printed PPG anchors joint decimal scoring.
- **[Issue #285](https://github.com/schatt/sixlayer/issues/285)** — Vision line layout for label anchoring.
- **[Issue #286](https://github.com/schatt/sixlayer/issues/286)** — Fail closed when joint correction finds no valid pair.
- **[Issue #287](https://github.com/schatt/sixlayer/issues/287)** — Locale decimal separators for OCR volume parsing.

---

## ⚠️ Migration / consumer notes

- **OCR hints**: Ensure `calculationGroups` formulas use your entity field ids (`totalCost`, `fuelCost`, `gallons`, `volume`, etc.); joint correction reads relationships from those formulas.
- **Pump receipts**: Bidirectional `ocrHints` patterns should use the framework's `(?i)((hint…)num)|(num…hint))` shape so split-arm extraction runs correctly.

---

## 🔗 References

- [RELEASE_v7.8.2.md](RELEASE_v7.8.2.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
