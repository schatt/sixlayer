# SixLayer Framework v7.7.0 Release Documentation

**Release Date**: April 24, 2026  
**Release Type**: Minor  
**Previous Release**: v7.6.2  
**Status**: Released

---

## 🎯 Release Summary

v7.7.0 introduces a new **VisionKit live data scanner path** (Issue #252) alongside the existing camera/photo APIs, with Layer 4 presentation helpers, app-provided top banner messaging, and scanner lifecycle callbacks. It also completes namespaced runtime capability work (Issue #253), including new `Network`, `Media`, `Pasteboard`, and `Accessibility` namespaces.

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

## ✅ Runtime capability namespace completion (Issue #253)

Completed in this release:
- `RuntimeCapabilityDetection.Photos`, `Vision`, `Files` finalized and documented.
- Additional namespaced surfaces added: `Network`, `Media`, `Pasteboard`, `Accessibility`.
- Override hooks + `clearAllCapabilityOverrides()` teardown coverage across namespaces.
- Layer 4 scanner callsites aligned to namespaced scanner availability checks.

---

## ✅ Resolved GitHub issues

- **Issue #252** — VisionKit `DataScannerViewController` path added alongside existing photo/camera flow.
- **Issue #253** — Runtime capability namespacing completed (Photos / Vision / Files + Network / Media / Pasteboard / Accessibility).
- **Issue #247** — Internal test harness stability improvements included in release process.
- **Issue #246** — Release-process/reporting updates included for this milestone.

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
