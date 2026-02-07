# SixLayer Framework v7.5.0 Release Documentation

**Release Date**: February 6, 2026  
**Release Type**: Minor  
**Previous Release**: v7.4.2  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Minor release with documentation updates, test infrastructure improvements, release process refinements, and issue resolutions. See GitHub milestone v7.5.0 for full issue details.

---

## 📋 Resolved Issues

Closed issues for this release (see [milestone v7.5.0](https://github.com/schatt/6layer/milestone/19)):

- ** [#176](https://github.com/schatt/6layer/issues/176) — Add optional hints parameter to `platformPresentModalForm_L1`**  
  Added optional `hints: PresentationHints?` so developers can customize form complexity, preferences, and other hint properties while staying backward compatible.

- ** [#175](https://github.com/schatt/6layer/issues/175) — Auto-generate identifierName for interactive elements**  
  Automatic identifier generation for all interactive elements that have enough information (labels/titles) to build meaningful identifiers (e.g. platformButton from label, platformTextField from placeholder).

- ** [#174](https://github.com/schatt/6layer/issues/174) — View extensions for text modifiers**  
  Added `View` extensions that mirror Text-specific modifiers (`.bold()`, `.italic()`, `.font()`, `.fontWeight()`, etc.) so they can be chained after `.basicAutomaticCompliance()` and other modifiers that return `some View`.

- ** [#173](https://github.com/schatt/6layer/issues/173) — Consolidate generateIdentifier variants**  
  Refactored three separate `generateIdentifier` implementations (AutomaticComplianceModifier, NamedAutomaticComplianceModifier, and a free function) into one shared implementation to remove duplication and keep behavior consistent.

- ** [#172](https://github.com/schatt/6layer/issues/172) — Lightweight compliance for basic SwiftUI types**  
  Introduced `.basicAutomaticCompliance()` for basic types (Text, Image, etc.) that applies only accessibility identifier/label and skips view-level HIG features (touch targets, margins, focus indicators), so simple views get identifiers without extra layout changes.

- ** [#171](https://github.com/schatt/6layer/issues/171) — Missing .automaticCompliance() in platform container functions**  
  Fixed several `platform*` container functions that did not apply `.automaticCompliance()`, so all platform* functions now consistently apply automatic accessibility.

- ** [#168](https://github.com/schatt/6layer/issues/168) — Complete accessibility for Layer 3 platform* methods**  
  Brought every Layer 3 `platform*_L3` method up to full accessibility support (labels, hints, identifiers, traits), with at least one RealUI test app example and documentation for each.

- ** [#167](https://github.com/schatt/6layer/issues/167) — Complete accessibility for Layer 2 platform* methods**  
  Same as above for Layer 2: full accessibility support, RealUI examples, and docs for every `platform*_L2` method.

- ** [#166](https://github.com/schatt/6layer/issues/166) — Complete accessibility for Layer 1 platform* methods**  
  Same for Layer 1: full accessibility support, RealUI examples, and docs for every `platform*_L1` method.

- ** [#165](https://github.com/schatt/6layer/issues/165) — Complete accessibility for all platform* methods**  
  Parent effort: ensured every `platform*` method has full accessibility support, at least one RealUI usage, and documentation (addressed via #166, #167, #168).

- ** [#163](https://github.com/schatt/6layer/issues/163) — Picker segments missing automatic accessibility identifiers**  
  Fixed bug where `.automaticCompliance()` on a Picker only set an identifier on the picker itself; individual segments in the `ForEach` now receive identifiers so segments are accessible to VoiceOver and UI tests.

- ** [#162](https://github.com/schatt/6layer/issues/162) — Multiple .platform* functions missing parameters**  
  Fixed multiple `.platform*` functions that were missing parameters compared to SwiftUI’s native modifiers, restoring the drop-in replacement promise.

- ** [#161](https://github.com/schatt/6layer/issues/161) — platformFrame missing alignment parameter**  
  Added the missing `alignment` parameter to `platformFrame()` so it matches SwiftUI’s `.frame()` modifier and can be used as a drop-in replacement.

- ** [#160](https://github.com/schatt/6layer/issues/160) — Remove environment dependencies from AutomaticCompliance**  
  Removed `@Environment` use from `AutomaticComplianceModifier` and `NamedAutomaticComplianceModifier`, eliminating the `EnvironmentAccessor` wrapper and fixing the bug in #159.

- ** [#159](https://github.com/schatt/6layer/issues/159) — accessibilityIdentifier not on tappable button in platformNavigationButton_L4**  
  Fixed bug where `.accessibilityIdentifier()` was applied to the container instead of the tappable button in `platformNavigationButton_L4`; the identifier is now on the actual button for UI tests and VoiceOver.

- ** [#157](https://github.com/schatt/6layer/issues/157) — Automatic label extraction from view content**  
  Platform* helpers now automatically derive accessibility labels from their parameters (placeholder text, button labels, toggle titles, etc.) with localization support.

- ** [#156](https://github.com/schatt/6layer/issues/156) — Layer 1 hints integration for accessibility labels**  
  Integrated the hints system with Layer 1 semantic functions (`platformPresentFormData_L1` and related) so `DynamicFormField.label` is used automatically for accessibility labels.

- ** [#155](https://github.com/schatt/6layer/issues/155) — Add label parameters to generic platform functions**  
  Added optional `label` parameter to generic platform functions (`platformButton`, `platformTextField`, `platformToggle`, `platformSecureField`, `platformTextEditor`) to support explicit accessibility labels.

- ** [#154](https://github.com/schatt/6layer/issues/154) — Automatically generate accessibility labels for VoiceOver**  
  Framework now applies both accessibility identifiers (testing) and accessibility labels (VoiceOver/users). Labels are generated from view content and parameters so assistive technologies get meaningful names (addressed via #155, #156, #157).

- ** [#153](https://github.com/schatt/6layer/issues/153) — Fix accessibility identifier detection in real UI tests**  
  Fixed real UI tests (AccessibilityRealUITests) where identifiers were missing or empty when views were in actual windows; removed unsafe forced cast and corrected detection so `.automaticCompliance()`-generated identifiers are found at runtime.

---

## ✅ Backward Compatibility

**Fully backward compatible** — no breaking API changes in this release.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
- [AI_AGENT_v7.5.0.md](AI_AGENT_v7.5.0.md) — AI agent guide for this version
