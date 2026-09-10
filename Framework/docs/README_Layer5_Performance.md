# Layer 5: Platform Technical Implementation

## Overview

Layer 5 applies platform-aware technical behavior (navigation chrome, gestures, haptics, accessibility, animation/layout helpers, split-view and navigation-stack tuning, card-expansion performance config). It does **not** ship generic View modifiers named `platformMemoryOptimization`, `platformRenderingOptimization`, `platformViewCaching`, `platformLazyLoading`, `platformPerformanceOptimized`, or similar — those names appeared only in older docs and are **not** in `Framework/Sources` (#425).

## File locations (actual)

| Area | Path |
|------|------|
| iOS View enhancements | `Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift` |
| macOS View enhancements | `Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSOptimizationsLayer5.swift` |
| Shared L5 platform components | `Framework/Sources/Layers/Layer5-Platform/` (e.g. split view / navigation stack optimizations, card expansion performance config, Messaging/Resource helpers) |

There is **no** `Shared/Views/Extensions/PlatformPerformanceExtensionsLayer5.swift`.

## iOS View APIs (`PlatformIOSOptimizationsLayer5`)

These exist as `extension View` (iOS) with non-iOS stubs where needed:

- `platformIOSNavigationBar(...)`
- `platformIOSToolbar(...)`
- `platformIOSSwipeGestures(...)`
- `platformIOSHapticFeedback(style:onTrigger:)` / `IOSHapticStyle` — **deprecated** (#445). App authors should use `View.platformHapticFeedback(_:)` / `PlatformHapticFeedback`. The L5 methods remain as thin `onChange` wrappers.
- `platformIOSAccessibility(...)`
- `platformIOSAnimation(...)` / `IOSAnimationType`
- `platformIOSLayout(...)`
- `platformIOSPullToRefresh(...)`
- `platformIOSContextMenu(...)`

Coverage for haptics: **#423** (L5 wrappers), **#445** (unified public surface). Remaining modifiers in that file: **#424**.

## macOS View APIs (`PlatformMacOSOptimizationsLayer5`)

These exist as `extension View` (macOS) with non-macOS identity stubs (#451 / #449):

- `platformMacOSWindowToolbar_L5()` — applies `presentedWindowToolbarStyle(.unified)` on macOS. Decision: `platformMacOSWindowToolbarChrome(for:)`. This is **not** Scene `windowToolbarStyle` (that cannot be a View modifier).
- `platformMacOSKeyboardFocus_L5()` — applies SwiftUI `.focusable()` on macOS. Decision: `platformMacOSKeyboardFocusChrome(for:)`. Deeper NavigationStack keyboard work stays on **#446**.

There is **no** `platformMacOSSidebarChrome_L5()` alias. Sidebar / split-column chrome already lives on the shared L5 helpers (`platformMacOSSplitViewOptimizations_L5()` / `platformSplitViewOptimizations_L5()`). A thin wrapper would be a tautological alias with no extra behavior (#447).

## Other L5 surfaces (examples)

- `platformSplitViewOptimizations_L5()` / platform-specific variants
- `platformNavigationStackOptimizations_L5()` / platform-specific variants
- `getCardExpansionPerformanceConfig()` / `CardExpansionPerformanceConfig`

Placeholder demo Views (`PlatformOptimizationLayer5`, `PlatformProfilingLayer5`, and siblings) were **removed** in **#453** — do not document or call them.

## What not to call

Do **not** document or call these — they are not implemented:

- `platformMemoryOptimization()`
- `platformRenderingOptimization()`
- `platformViewCaching()`
- `platformAnimationOptimization()`
- `platformCachingOptimization()`
- `platformLazyLoading` / `platformLazyLoading { }`
- `platformPerformanceOptimized(for:)`
- `platformMemoryOptimized(for:)`
- Phantom types from deleted orphan suites: `MemoryConfig`, `LazyLoadingConfig`, `ViewPerformanceMetrics`, `PerformanceOptimizationLevel`, `PerformanceCachingStrategy`, `PerformanceRenderingStrategy`

## Related documentation

- Architecture overview: [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- Parent cleanup: GitHub **#402**; tracker **#426**
