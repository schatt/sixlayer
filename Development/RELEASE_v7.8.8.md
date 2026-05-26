# SixLayer Framework v7.8.8 Release Documentation

**Release Date**: May 26, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.7  
**Status**: Released

---

## 🎯 Release Summary

v7.8.8 is a **patch** release that completes the Dynamic Type typography stack ([#295](https://github.com/schatt/sixlayer/issues/295), [#294](https://github.com/schatt/sixlayer/issues/294), [#296](https://github.com/schatt/sixlayer/issues/296)): central `DynamicFontResolver`, design-token scaling, and scalable decorative/hero icon fonts. Downstream apps (e.g. CarManager [#493](https://github.com/schatt/CarManager/issues/493)) can replace fixed `.font(.system(size:))` with framework APIs.

---

## 🆕 Confirmed in v7.8.8 (implemented)

### **DynamicFontResolver (#295)**

- **`SixLayerTextStyle`**, **`DynamicFontResolver`**, **`@Environment(\.dynamicFontResolver)`**
- **`SixLayerContentSizeCategory`** (replaces conflicting `ContentSizeCategory` name; deprecated typealias retained)
- iOS: `UIFont.preferredFont`; macOS: baseline × `typographyScaleFactor`
- **`HIGTypographySystem`** delegates to the resolver

### **Design-token typography (#294)**

- **`AccessibilitySettings.preferredContentSize`**
- **`typographyScaleFactor`** from content size (1.0 when Dynamic Type off)
- **`SixLayerDesignSystem`** / high-contrast tokens use `DynamicFontResolver`; tokens refresh on accessibility changes (iOS `UIContentSizeCategory.didChangeNotification`)

### **Scalable system & decorative icons (#296)**

- **`Font.platformSystem(size:relativeTo:contentSize:)`** — scales with Dynamic Type (`UIFontMetrics` on iOS)
- **`Font.platformFixedSystem(size:)`** — non-scaling (overlays)
- **`View.platformDecorativeIconFont(designSize:relativeTo:)`** — empty-state / hero SF Symbols
- Framework audit: Layer1/Layer4/OCR/barcode call sites migrated; [`Framework/docs/TypographyMigration.md`](../Framework/docs/TypographyMigration.md)

---

## ✅ Resolved GitHub issues

- **[Issue #295](https://github.com/schatt/sixlayer/issues/295)** — Central `DynamicFontResolver` API  
- **[Issue #294](https://github.com/schatt/sixlayer/issues/294)** — `typographyScaleFactor` and token typography  
- **[Issue #296](https://github.com/schatt/sixlayer/issues/296)** — Scalable `platformSystem`, decorative icons, framework audit  

---

## ⚠️ Migration / consumer notes

- **`Font.platformSystem(size:)` now scales.** Use **`platformFixedSystem`** if you relied on a fixed point size.
- **Empty-state icons:** prefer **`platformDecorativeIconFont(designSize:)`** or **`platformSystem(size:relativeTo: .largeTitle)`** over raw `.font(.system(size:))`.
- **CarManager:** see [TypographyMigration.md](../Framework/docs/TypographyMigration.md) and bump SPM to **`7.8.8`** after tag.

---

## 🔗 References

- [RELEASE_v7.8.7.md](RELEASE_v7.8.7.md) — prior patch (`PlatformTabStrip` #292)  
- [RELEASES.md](RELEASES.md) — release history index  
