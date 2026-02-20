# SixLayer Framework v7.5.6 Release Documentation

**Release Date**: February 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.5  
**Status**: In preparation

---

## 🎯 Release Summary

Patch release. Batch OCR target image field and text scoping (allowlist / `_ocrGroups`), plus optional host-triggered batch OCR binding. See Issue #188.

---

## 🆕 What's New

### **Batch OCR: target image field and scope (Issue #188)**
- **Target image field**: `processBatchOCR(image:targetImageFieldId:targetScope:)` — when `targetImageFieldId` is set and valid, the image is stored on that field; otherwise the first OCR-enabled image field.
- **Text scope**: When `targetScope` is set (`.fieldIds([String])` or `.group(String)`), only those field IDs receive this run's extracted text; when `nil` (or `.all`), behavior is unchanged.
- **OCR groups (Option B)**: `_ocrGroups` in .hints and `ocrGroups` on `DynamicFormConfiguration` — map group name to field IDs (e.g. `"front": ["firstName", "frontImage"], "back": ["expiryDate", "backImage"]`). Fields may appear in multiple groups. No reflection.
- **API**: `OCRTargetScope` (`.all`, `.fieldIds([String])`, `.group(String)`), `BatchOCRRequest`, `configuration.fieldIds(for: scope)`.
- **Host-triggered batch OCR**: Optional `batchOCRRequest: Binding<BatchOCRRequest?>?` on `DynamicFormView`; when the host sets it to a non-nil value, the form shows the image picker and runs batch OCR with that target and scope when the user selects an image (e.g. "Scan front" / "Scan back").

---

## ✅ Backward Compatibility

**Fully backward compatible** — optional parameters and new types only; no breaking API changes.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
