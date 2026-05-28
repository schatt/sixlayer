# SixLayer Framework v7.8.9 Release Documentation

**Release Date**: May 28, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.8  
**Status**: Release prep (`b7/b7.8.9`)

---

## 🎯 Release Summary

v7.8.9 is a **patch** release combining two accessibility slices:

1. **Reduce Motion** ([#298](https://github.com/schatt/sixlayer/issues/298)) — framework-owned policy for `platformAnimation`, `higAnimationCategory`, and imperative `withPlatformAnimation`.
2. **Increase Contrast** ([#299](https://github.com/schatt/sixlayer/issues/299)) — view-scoped `.secondary` → `.primary` for subtitle/caption text when `colorSchemeContrast == .increased`.

---

## 🆕 Confirmed in v7.8.9 (implemented)

### **Reduce Motion for animation APIs (#298)**

- **`PlatformReduceMotionPreference`**: system reads (UIKit / AppKit), `@TaskLocal` test overrides, `resolvedAnimation` helper.
- **`withPlatformAnimation`**: imperative `withAnimation` counterpart that no-ops animation when reduce motion is on.
- **`platformAnimation`** (Platform + Layer 4): `.animation(.none, …)` when reduce motion is enabled.
- **`higAnimationCategory`**: clears transaction animation when reduce motion is on.
- **`PlatformReduceMotionSubtreeModifier`**: shared subtree gating via `transaction.disablesAnimations`.
- **`AutomaticHIGMotionPreferenceModifier`** / **`ReducedMotionModifier`**: real behavior, not pass-through.
- **`AccessibilityManager.isReduceMotionEnabled()`** and **`AccessibilitySystemState`**: live system state.

**Usage:**

```swift
import SixLayerFramework

withPlatformAnimation(.easeInOut) {
    flag = true
}

Text("Animated")
    .platformAnimation(.easeInOut, value: count)
```

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

- **[Issue #298](https://github.com/schatt/sixlayer/issues/298)** — `platformAnimation` and motion APIs respect Reduce Motion.
- **[Issue #299](https://github.com/schatt/sixlayer/issues/299)** — `platformForegroundReadableSecondary` for Increase Contrast.

---

## ⚠️ Migration / consumer notes

- **CarManager:** Bump SPM to **`7.8.9`** after tag.
  - Reduce Motion: remove duplicate `PlatformAnimationSystemExtensions`; use framework APIs ([#438](https://github.com/schatt/CarManager/issues/438), [#488](https://github.com/schatt/CarManager/issues/488)).
  - Increase Contrast: replace `foregroundColorReadableSecondary()` with `platformForegroundReadableSecondary()`; remove local `AccessibilityContrast` ([#403](https://github.com/schatt/CarManager/issues/403)).
- **No breaking changes** — additive public API only.
- **Do not** use `HighContrastEnabledView` / `isHighContrastEnabled` for Increase Contrast subtitle text.

---

## 🔗 References

- [RELEASE_v7.8.8.md](RELEASE_v7.8.8.md) — prior patch (Dynamic Type typography #295–#296).
- [RELEASES.md](RELEASES.md) — release history index.
- [colorSchemeContrast](https://developer.apple.com/documentation/swiftui/environmentvalues/colorschemecontrast)
