# Release v7.8.9 — Reduce Motion for platform animation APIs

**Date:** May 26, 2026  
**Issue:** [#298](https://github.com/schatt/sixlayer/issues/298)

## Summary

Framework-owned reduce-motion policy for shared animation APIs so consumers do not duplicate `@Environment(\.accessibilityReduceMotion)` gating.

## Added

- **`PlatformReduceMotionPreference`**: system reads (UIKit / AppKit), `@TaskLocal` test overrides, and `resolvedAnimation` helper.
- **`withPlatformAnimation`**: imperative `withAnimation` counterpart that no-ops animation when reduce motion is on.

## Changed

- **`platformAnimation`** (`PlatformAnimation` and Layer 4 overloads): applies `.animation(.none, …)` when reduce motion is enabled.
- **`higAnimationCategory`**: clears transaction animation when reduce motion is on.
- **`AutomaticHIGMotionPreferenceModifier`**: delegates to `ReducedMotionModifier` instead of a no-op pass-through.
- **`AccessibilityManager.isReduceMotionEnabled()`**: reads live policy (no permanent `false` stub).
- **`AccessibilitySystemState`**: populated from platform accessibility APIs, including reduce motion.
- **`VisualDesignSystem`**: macOS `reducedMotion` from `NSWorkspace.accessibilityDisplayShouldReduceMotion`.

## Tests

- `PlatformReduceMotionPreferenceTests`, `PlatformAnimationReduceMotionTests`, and updates to accessibility manager / HIG compliance tests.
