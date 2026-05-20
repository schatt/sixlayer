# SixLayer Framework v7.8.4 Release Documentation

**Release Date**: May 20, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.3  
**Status**: Released

---

## 🎯 Release Summary

v7.8.4 is a **patch** release focused on **Vision OCR sensitivity for pump LCD digits on full-resolution photos** (#288): configurable `minimumTextHeight` per `OCRContext`, with a pump-friendly framework default of **0.003** (replacing the prior effective **0.01** threshold that dropped small LCD lines before structured extraction).

---

## 🆕 Confirmed in v7.8.4 (implemented)

### **Configurable Vision `minimumTextHeight` (#288)**

- `OCRVisionDefaults.minimumTextHeight` = `0.003` (fraction of image height).
- `OCRContext.visionMinimumTextHeight` — per-request override (e.g. `0.01` for receipt-style documents).
- Applied in `OCRService`, `SafeVisionOCRView` (`PlatformOCRSafetyExtensions`), and Layer2 OCR context copies.

**Usage:**

```swift
let pump = OCRContext(entityName: "FuelPurchase") // default 0.003

let receipt = OCRContext(
    entityName: "Expense",
    visionMinimumTextHeight: 0.01
)
```

### **Tests**

- `OCRVisionMinimumTextHeight288Tests` — default and custom override.

---

## ✅ Resolved / advanced GitHub issues

- **[Issue #288](https://github.com/schatt/sixlayer/issues/288)** — Vision `minimumTextHeight` drops pump LCD digits on full-resolution photos.

---

## ⚠️ Migration / consumer notes

- **Pump photos:** Default `OCRContext()` now uses `0.003`; client-side downscale is no longer required solely to satisfy Vision’s size filter.
- **Receipts / dense documents:** Pass `visionMinimumTextHeight: 0.01` if the lower default adds unwanted small-text noise.
- **Decimal misreads** (e.g. `406` vs `$40.61`) remain in joint decode / locale parsing (#283–#287), not this release.
- **CarManager:** Bump SPM to `7.8.4` after tag; tracked as schatt/CarManager#377.

---

## 🔗 References

- [RELEASE_v7.8.3.md](RELEASE_v7.8.3.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
