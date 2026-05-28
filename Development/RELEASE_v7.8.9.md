# SixLayer Framework v7.8.9 Release Documentation

**Release Date**: May 28, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.8  
**Status**: Release prep (`b7/b7.8.9`)

---

## 🎯 Release Summary

v7.8.9 is a **patch** release that adds **Increase Contrast** support for subtitle/caption text ([#299](https://github.com/schatt/sixlayer/issues/299)). Hosts get view-scoped `.secondary` → `.primary` when `colorSchemeContrast == .increased`, without forcing root high-contrast modifiers or Darker System Colors detection.

---

## 🆕 Confirmed in v7.8.9 (implemented)

### **Increase Contrast readable secondary (#299)**

- **`PlatformContrastAccessibility.readableSecondary(contrast:)`** — pure helper for `ColorSchemeContrast`.
- **`View.platformForegroundReadableSecondary()`** — applies readable secondary foreground per text view.
- **`PlatformContrastAccessibilityTests`** — unit tests; increased vs standard differential catches constant stubs.
- **`RuntimeCapabilityDetection.isHighContrastEnabled`** — documented as **Darker System Colors** only.

**Usage:**

```swift
import SixLayerFramework

Text("Subtitle")
    .platformForegroundReadableSecondary()
```

---

## ✅ Resolved GitHub issues

- **[Issue #299](https://github.com/schatt/sixlayer/issues/299)** — `platformForegroundReadableSecondary` for Increase Contrast.

---

## ⚠️ Migration / consumer notes

- **CarManager:** Bump SPM to **`7.8.9`** after tag. Replace `foregroundColorReadableSecondary()` with `platformForegroundReadableSecondary()`; remove local `AccessibilityContrast` ([#403](https://github.com/schatt/CarManager/issues/403), [#488](https://github.com/schatt/CarManager/issues/488)).
- **No breaking changes** — additive public API only.
- **Do not** use `HighContrastEnabledView` / `isHighContrastEnabled` for Increase Contrast subtitle text.

---

## 🔗 References

- [RELEASE_v7.8.8.md](RELEASE_v7.8.8.md) — prior patch (Dynamic Type typography #295–#296).
- [RELEASES.md](RELEASES.md) — release history index.
- [colorSchemeContrast](https://developer.apple.com/documentation/swiftui/environmentvalues/colorschemecontrast)
