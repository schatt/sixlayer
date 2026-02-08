# SixLayer Framework v7.5.2 Release Documentation

**Release Date**: TBD  
**Release Type**: Patch  
**Previous Release**: v7.5.1  
**Status**: 📋 **PLANNED**

---

## 🎯 Release Summary

Patch release adding an optional debug flag for platformFrame min clamping diagnostics.

---

## 🆕 What's New

### **verboseMinClamping debug flag**

- **Static flag**: `PlatformFrameHelpers.verboseMinClamping: Bool` (default `false`).
- **Behavior**: When `true`, logs to the console whenever a requested `minWidth` or `minHeight` is reduced (clamped) to fit available space, e.g. `[PlatformFrameHelpers] minWidth clamped: <requested> → <clamped> (platform)`.
- **Purpose**: Opt-in debugging when a view’s minimum size is being capped by the framework; no logging by default.

**Files changed**: `Framework/Sources/Extensions/Platform/PlatformFrameHelpers.swift`

Tracked in [#183](https://github.com/schatt/sixlayer/issues/183).

---

## ✅ Backward Compatibility

**Fully backward compatible** — additive API only; default behavior unchanged.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [Issue #183](https://github.com/schatt/sixlayer/issues/183) — Tracking
