# SixLayer Framework v7.5.8 Release Documentation

**Release Date**: February 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.7  
**Status**: In preparation

---

## 🎯 Release Summary

Patch release. Always show camera/library tabbed UI when both sources are available so the user can switch from either view (Resolves Issue #190). Optional debug logging and verification doc for camera-drop behavior.

---

## 🆕 What's New

### **Photo capture: camera/library selector always present (Issue #190)**
- **Tabbed UI when both available**: When the device has both camera and photo library, `platformPhotoCapture_L1` always shows the tabbed interface (Camera | Library). User can switch from camera to library or library to camera without leaving the flow.
- **Initial tab**: Respects `context.userPreferences.preferredSource` so the first tab shown can be camera or library.
- **Layer 3**: `selectPhotoCaptureStrategy_L3` returns `.both` whenever both capabilities exist (no longer returns `.camera` or `.photoLibrary` alone in that case).
- **Layer 4**: `platformPhotoSourceTabbed_L4` accepts optional `initialSource: PhotoSource` to open on the preferred tab.
- **Verification**: Optional env var `SLF_DEBUG_PHOTO_CAPTURE=1` logs delegate callbacks (DEBUG builds) to confirm behavior when the system camera becomes unstable. See `Development/docs/Issue190_PhotoCapture_Verification.md`.

---

## ✅ Backward Compatibility

**Fully backward compatible** — behavioral change only when both camera and library are available (previously single-source could be shown; now tabbed is always shown). No API removals or breaking changes.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [Issue190_PhotoCapture_Verification.md](docs/Issue190_PhotoCapture_Verification.md) — Manual verification steps for camera-drop behavior
