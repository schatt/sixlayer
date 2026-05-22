# SixLayer Framework v7.8.5 Release Documentation

**Release Date**: May 21, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.4  
**Status**: Released

---

## 🎯 Release Summary

v7.8.5 is a **patch** release that **closes milestone v7.8.5** with full release-note coverage for all eight completed issues: **pump LCD structured OCR** (#282–#287), **Layer 4–6 XCUITest runtime stabilization** (#261), and **numeric form field display coercion** (#289). New framework code in this tag also includes **build hygiene** (deprecated `onChange` / `setOverrideTraitCollection` fixes, tautological test cleanup) and continued SD150/L4 test hardening.

Issues #282–#287 and #261 were implemented in earlier 7.8.x patches but were not yet listed in a single release document tied to this milestone; they are documented here per milestone closure.

---

## 🆕 Confirmed in v7.8.5 (implemented)

### **Stored numeric display coercion (#289)**

- `DynamicFormStoredNumericDisplay.displayString(fromStoredValue:defaultValue:)` — formats stored values for text fields without scientific notation for typical magnitudes.
- `DynamicFormField.numericTextBinding(in:)` — read/write binding: numeric types on read, `String` on write.
- `DynamicNumberField` / `DynamicIntegerField` wired to the helper; draft storage key behavior documented in `FormAutoSaveGuide.md`.

**Usage:**

```swift
// Prefill from Core Data / DTO — Int/Double/NSNumber render in the field
formState.setValue(42.5, for: "amount")

// User edits still store String
```

### **Label-anchored structured extraction (#282, #285)**

- `OCRLabelAnchoredExtraction` binds numeric fields using bidirectional hint regexes in separate hint-first and number-first passes (avoids alternation stealing digits on pump receipts).
- Per-line Vision recognition assignments merge over flat-text fallback; layout proximity scoring prefers line-local hints.
- `OCRService` delegates structured extraction to the label-anchoring module.

### **Joint decimal correction (#283, #284, #286, #287)**

- `OCRJointDecimalCorrection` discovers multiplication relationships from hints `calculationGroups` (not hard-coded field names).
- Joint search prefers candidates whose implied rate matches a printed price-per-gallon when present (#284).
- Identical ambiguous product/volume strings fail closed with adjustment messaging (#286).
- Locale-aware numeric parsing supports comma decimal separators (e.g. French `3,704` gallons) (#287).

### **Layer 4–6 XCUITest runtime stabilization (#261)**

- Shared L4 System scroll helpers, CloudKit/photo contract query simplification, SD150 secure-field and Form scroll budgets, fail-fast scroll/wait caps, and deeper Form scroll for L4 System sections.
- Integration Form flows: keyboard dismiss, paste/typeText paths for secure fields, integration toggle mirror polling, and CollectionView/Form scroll fallbacks when overlay hosts block table queries.

### **Tests and build hygiene**

- `DynamicFormStoredNumericDisplayTests`, `OCRPumpLabelAnchoredExtraction282Tests`, `OCRStructuredExtractionFollowups283Tests` (serialized).
- Layer 4 assistive tests: `traitOverrides.accessibilityContrast` instead of deprecated `setOverrideTraitCollection`.
- `AdvancedFieldTypes`: macOS 14+ zero-parameter `onChange` for date/time pickers.
- `Layer1PresentationTests`: removed tautological `#expect(true)` placeholders.

---

## ✅ Resolved / advanced GitHub issues

- **[Issue #289](https://github.com/schatt/sixlayer/issues/289)** — Dynamic number/integer fields show blank when `fieldValues` holds numeric types.
- **[Issue #282](https://github.com/schatt/sixlayer/issues/282)** — Label-anchored pump sale total and gallons (decimal placement).
- **[Issue #283](https://github.com/schatt/sixlayer/issues/283)** — Joint decimal correction derives fields from calculation groups, not hard-coded keys.
- **[Issue #284](https://github.com/schatt/sixlayer/issues/284)** — Printed price-per-gallon anchors joint decimal scoring.
- **[Issue #285](https://github.com/schatt/sixlayer/issues/285)** — Label anchoring uses Vision line layout and bounding boxes.
- **[Issue #286](https://github.com/schatt/sixlayer/issues/286)** — Fail closed when joint correction finds no valid pair.
- **[Issue #287](https://github.com/schatt/sixlayer/issues/287)** — Locale decimal separators and volume units for OCR volume parsing.
- **[Issue #261](https://github.com/schatt/sixlayer/issues/261)** — Layer 4/5/6 XCUITest runtime failures on iOS `SLF-iOS-AllTests`.

---

## ⚠️ Migration / consumer notes

- **Hosts prefilling forms:** You may keep storing `Int`/`Double`/`NSNumber` for number fields; display coercion runs on read. Prefer `String` when you control the mapping if you want exact user-entered text round-tripped.
- **OCR hints:** Ensure `calculationGroups` formulas use your entity field ids; joint correction reads relationships from those formulas. Bidirectional `ocrHints` should use the framework's split-arm regex shape.
- **Pump photos:** For Vision size filtering, see v7.8.4 `minimumTextHeight` (#288) if LCD lines are still dropped on full-resolution captures.
- **CarManager:** Bump SPM to `7.8.5` after tag when integrating framework changes.

---

## 🔗 References

- [RELEASE_v7.8.4.md](RELEASE_v7.8.4.md) — Vision `minimumTextHeight` (#288).
- [RELEASE_v7.8.3.md](RELEASE_v7.8.3.md) — Prior OCR patch narrative (subset of #282–#287).
- [RELEASE_v7.8.2.md](RELEASE_v7.8.2.md) — Prior UITest stabilization narrative (#261).
- [RELEASES.md](RELEASES.md) — Release history index.
