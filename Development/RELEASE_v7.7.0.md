# SixLayer Framework v7.7.0 Release Documentation

**Release Date**: TBD  
**Release Type**: Minor  
**Previous Release**: v7.6.2  
**Status**: In preparation

---

## 🎯 Release Summary

v7.7.0 introduces a new **VisionKit live data scanner path** (Issue #252) alongside the existing camera/photo APIs, with Layer 4 presentation helpers, app-provided top banner messaging, and scanner lifecycle callbacks. This release is also expected to ship with namespaced runtime capability work (Issue #253), which is still being finalized.

---

## 🆕 Confirmed in v7.7.0 (implemented)

### **Live scanner API surface (Issue #252)**

- Added new Layer 4 scanner entry points (in addition to existing photo/camera paths):
  - `platformDataScannerContent_L4(...)`
  - `platformDataScannerInterface_L4(...)`
  - `platformDataScannerInterface_L4AsSheet(...)`
  - `platformDataScannerInterface_L4AsFullScreenCover(...)`
- Added scanner configuration and types:
  - `PlatformDataScannerConfiguration`
  - `PlatformDataScannerDataKind` (plain/filtered text and barcode symbology selection)
  - quality, highlight, guidance, pinch-to-zoom, high-frame-rate tracking, region-of-interest, and presentation style options.

### **Runtime behavior + callbacks**

- iOS VisionKit hosting based on `DataScannerViewController`.
- Item callbacks for:
  - tap
  - add/update/remove recognized items
  - scanner became unavailable.
- Session control surface includes:
  - `startScanning()`
  - `stopScanning()`
  - `capturePhoto()`.

### **Presentation + UX requirements**

- Supports both sheet and full-screen presentation semantics, with helper APIs.
- Supports app-provided top message banner over scanner content.
- Includes macOS presentation fallback behavior where native full-screen cover APIs differ.

### **Tests + examples**

- Added Layer 4 API signature coverage for scanner APIs.
- Added scanner-focused Layer 4 tests.
- Added Test App Layer 4 example card demonstrating sheet and full-screen scanner flows.

---

## 🔄 In-flight for v7.7.0 (co-shipped scope)

### **Runtime capability namespace completion (Issue #253)**

The release plan is to ship #252 and #253 together. Final #253 details are still under active development; this document will be finalized when namespaced capability scope is complete.

Planned direction:
- Use namespaced runtime capability accessors (e.g. under `RuntimeCapabilityDetection.Photos`) for scanner availability gating.
- Avoid duplicate ad-hoc capability checks in Layer 4 scanner call sites.

---

## ✅ Resolved GitHub issues (target)

- **Issue #252** — VisionKit `DataScannerViewController` path added alongside existing photo/camera flow.
- **Issue #253** — Runtime capability namespacing (Photos / Vision / Files) targeted to co-ship with this release.

---

## ⚠️ Migration / consumer notes (draft)

- Existing `platformCameraInterface_L4` and `platformPhotoPicker_L4` flows remain available.
- New scanner APIs are additive and intended for live text/code acquisition workflows.
- Consumers should select scanner vs camera/photo picker based on UX intent:
  - **scanner** for recognized text/barcodes and item interactions,
  - **camera/photo picker** for full image capture/selection.

---

## 🔗 References

- [RELEASE_v7.6.2.md](RELEASE_v7.6.2.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
