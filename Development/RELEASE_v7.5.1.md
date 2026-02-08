# SixLayer Framework v7.5.1 Release Documentation

**Release Date**: February 7, 2026  
**Release Type**: Patch (platformFrame min constraint clamping)  
**Previous Release**: v7.5.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Patch release fixing a bug where `platformFrame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)` did not clamp **minWidth** or **minHeight** on iOS, watchOS, tvOS, or visionOS when they exceeded the available screen/window size. On those platforms, an oversized min could cause layout overflow or clipping. Min constraints are now capped at 90% of available space on all platforms, matching macOS behavior.

---

## 🔧 What's Fixed

### **platformFrame: Clamp min constraints on iOS and other platforms**

#### **Issue**

- **macOS**: Min was already clamped via `clampFrameSize()` (capped at 90% of visible frame).
- **iOS / watchOS / tvOS / visionOS**: Min was passed through unchanged. A `minWidth` or `minHeight` larger than the display could cause overflow or clipping.

#### **Solution**

In `PlatformFrameHelpers.clampFrameConstraints()`:

- **iOS**: `minWidth` and `minHeight` are now clamped to at most 90% of the window size from `getMaxFrameSize()`.
- **watchOS / tvOS / visionOS**: Same 90% cap applied to min constraints using each platform's `getMaxFrameSize()`.

#### **Files Changed**

- `Framework/Sources/Extensions/Platform/PlatformFrameHelpers.swift`

Fixes [#182](https://github.com/schatt/sixlayer/issues/182).

---

## ✅ Backward Compatibility

**Fully backward compatible** — no API changes. Only behavior change: oversized min values are now clamped instead of causing overflow on non-macOS platforms.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [Issue #182](https://github.com/schatt/sixlayer/issues/182) — Bug report and resolution
