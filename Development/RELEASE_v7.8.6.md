# SixLayer Framework v7.8.6 Release Documentation

**Release Date**: May 24, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.5  
**Status**: Released

---

## 🎯 Release Summary

v7.8.6 is a **patch** release that ships **Vision OCR text-discovery bounding boxes** in `OCROverlayView` ([#291](https://github.com/schatt/sixlayer/issues/291)). CarManager pump and receipt OCR preview flows can now show yellow discovery boxes aligned to aspect-fit images without duplicating geometry helpers in the app.

---

## 🆕 Confirmed in v7.8.6 (implemented)

### **OCR overlay bounding boxes (#291)**

- **`OCRBoundingBoxLayout`** — pure geometry helpers mapping Vision normalized rects (bottom-left origin) → image pixels (top-left) → aspect-fit container coordinates.
- **`OCROverlayView`** — draws configurable yellow stroke/fill boxes over the image when `result.boundingBoxes` is non-empty; shows **"No text regions detected"** when boxes are empty but box display is enabled.
- **`OCROverlayConfiguration`** — `showBoundingBoxes` (default `true`) and `highlightColor` (default `.yellow`).
- **`convertBoundingBoxToImageCoordinates` / tap detection** — use Vision Y-flip via `OCRBoundingBoxLayout`.

**Usage:**

```swift
OCROverlayView(
    image: processedImage,
    result: ocrResult, // boundingBoxes from Vision
    configuration: OCROverlayConfiguration(
        showBoundingBoxes: true,
        highlightColor: .yellow
    )
)
```

### **Tests**

- **`OCRBoundingBoxLayoutTests`** — SPM target runnable via `swift test --filter OCRBoundingBoxLayoutTests` (Vision flip, aspect-fit frame, pixel→container scaling).
- **`OCROverlayTests`** — Vision coordinate conversion and tap detection updated for normalized rects.

---

## ✅ Resolved GitHub issues

- **[Issue #291](https://github.com/schatt/sixlayer/issues/291)** — Render Vision text-discovery bounding boxes in `OCROverlayView`.

---

## ⚠️ Migration / consumer notes

- **CarManager:** Bump SPM to **`7.8.6`** after tag. Ensure `OCRResult.boundingBoxes` carries Vision-normalized rects from the framework OCR pipeline.
- **Exploratory tag `7.8.6` on old `wip/328-ocr-boxes` branch was not a release** — use this official tag only.

---

## 🔗 References

- [RELEASE_v7.8.5.md](RELEASE_v7.8.5.md) — prior patch (numeric form display #289).
- [RELEASES.md](RELEASES.md) — release history index.
- Consumer: CarManager [#328](https://github.com/schatt/CarManager/issues/328) / OCR overlay.
