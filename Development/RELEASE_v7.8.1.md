# SixLayer Framework v7.8.1 Release Documentation

**Release Date**: May 14, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.0  
**Status**: In preparation

---

## 🎯 Release Summary

v7.8.1 is a **patch** release focused on **structured OCR** correctness and defaults (**#279**), additional **PlatformImage** EXIF writers for capture date and orientation (extends **#275**), **Layer 4** accessibility identifiers and **XCUITest** contract stability, **agent workflow** documentation for issue-linked `wip/` branches (**#280**), and small **Layer 4** compile / isolation fixes (including **`platformPrint_L4`**).

---

## 🆕 Confirmed in v7.8.1 (implemented)

### **Structured OCR extraction (Issue #279)**

- Inclusive Vision pass behavior, uncategorized extractions on structured OCR, optional inference, and forwarding of OCR context fields in Layer 2 layouts.
- Unit coverage for inclusive defaults and uncategorized builder paths.

### **PlatformImage EXIF writers (extends Issue #275)**

- Adds EXIF **capture date** and **orientation** writers with tests alongside existing EXIF configuration work.

### **Layer 4 accessibility and UITest contracts**

- Stable accessibility identifiers for **CloudKit** account/progress/sync surfaces, **photo picker**, and L4 **contract** controls used by UI tests.
- Broad UITest helper improvements (scrolling, Form materialization, secure fields, keyboard handling, query fallbacks) and CI checkout/upload-artifact updates.

### **Agent / development process documentation (Issue #280)**

- Issue-linked **`wip/`** worktree checklist and cross-links to mandatory `wip/` policy for GitHub-issue-scoped work.

### **Layer 4 maintenance**

- Isolates **`platformPrint_L4`** in view modifiers; fixes stray / duplicate `#endif` issues in photo/scanner supporting views.

---

## ✅ Resolved GitHub issues

- **[Issue #279](https://github.com/schatt/sixlayer/issues/279)** — OCR: avoid dropping recognized text unless developer opts into strict filtering; inclusive defaults and structured-OCR fixes.
- **[Issue #280](https://github.com/schatt/sixlayer/issues/280)** — Development docs: issue-linked `wip/` worktree checklist for agents.
- **[Issue #275](https://github.com/schatt/sixlayer/issues/275)** — Follow-on: EXIF capture date and orientation writers (see v7.8.0 release for primary EXIF feature set).

---

## ⚠️ Migration / consumer notes

- **OCR**: If you relied on implicit dropping of low-confidence or uncategorized text, review **#279** behavior and opt into stricter filtering only where intended.
- **UI tests**: Prefer **source-owned** accessibility identifiers added in this release rather than broad tree scans when targeting CloudKit, pickers, and L4 contract controls.

---

## 🔗 References

- [RELEASE_v7.8.0.md](RELEASE_v7.8.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
