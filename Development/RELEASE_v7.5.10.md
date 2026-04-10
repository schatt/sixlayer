# SixLayer Framework v7.5.10 Release Documentation

**Release Date**: April 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.9  
**Status**: Released

---

## 🎯 Release Summary

Patch release following **v7.5.9**. Cross-platform correctness and test-harness improvements: Layer 4 navigation toolbar placement on macOS, Core Location authorization mapping for tests, macOS SwiftUI hosting for accessibility verification, and related test utility fixes.

---

## 🆕 What's New

### **Layer 4 navigation: toolbar placement (macOS build)**

- **`Layer4OuterSidebarOverlayHost`**: Uses `platformToolbarPlacement(.trailing)` instead of `ToolbarItemPlacement.navigationBarTrailing`, which is unavailable on macOS. Preserves iOS trailing bar placement (including XCUITest visibility expectations) while using an AppKit-appropriate placement on macOS.

### **Location authorization: platform mapping**

- **`CLAuthorizationStatus.platformLocationAuthorizationStatus`**: New extension in `PlatformLocationExtensions.swift` maps system authorization to `PlatformLocationAuthorizationStatus` without referencing iOS-only cases (e.g. `authorizedWhenInUse`) at call sites.
- **`CLLocationManager.platformAuthorizationStatus`**: Delegates to the new mapping for a single source of truth.
- **Tests**: `LocationServiceTests` assert via the platform enum so macOS unit tests compile and stay aligned with framework abstractions.

### **Test hosting and accessibility traversal (macOS)**

- **`TestSetupUtilities.hostRootPlatformView` (AppKit)**: Hosts SwiftUI in an `NSWindow`, orders front, drains the run loop, retains controller and window, and rebinds `AccessibilityIdentifierConfig` task-local during host—mirroring the UIKit path so `automaticCompliance` and platform a11y IDs are observable in unit tests.
- **`findAllAccessibilityIdentifiersFromPlatformView` (AppKit)**: Traverses `accessibilityChildren()` and reads `NSAccessibilityElement.accessibilityIdentifier()` where present.

### **Accessibility: container compliance vs nested manual IDs (Resolves Issue #217)**

- **`BasicAutomaticComplianceModifier` / `OptionalAccessibilityContainModifier`**: Container-style `automaticCompliance` only applies `accessibilityElement(children: .contain)` when needed so XCTest can still see nested manual identifiers under container automatic compliance (Category A audit #197). See [Issue #217](https://github.com/schatt/6layer/issues/217).

### **Miscellaneous test fixes**

- **`PlatformManagedSettingsTopLevelStateTests`**: Use `let` for bindings where the compiler indicated no `var` mutation.
- **AppKit**: `NSHostingController.view` is non-optional; hosting code uses `let root = hosting.view`. `NSAccessibilityElement` identifiers use `accessibilityIdentifier()` with optional binding.

---

## ✅ Backward Compatibility

**Fully backward compatible** — additive API on `CLAuthorizationStatus`, internal/test harness changes, and Layer 4 toolbar placement routing only. No intentional public API removals.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.9.md](RELEASE_v7.5.9.md) — Previous patch (v7.5.9)
