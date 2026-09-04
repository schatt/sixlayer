# Layer 5: Platform Technical Implementation

## Overview

Layer 5 applies platform-aware technical behavior (navigation chrome, gestures, haptics, accessibility, animation/layout helpers, split-view and navigation-stack tuning, card-expansion performance config). It does **not** ship generic View modifiers named `platformMemoryOptimization`, `platformRenderingOptimization`, `platformViewCaching`, `platformLazyLoading`, `platformPerformanceOptimized`, or similar — those names appeared only in older docs and are **not** in `Framework/Sources` (#425).

## File locations (actual)

| Area | Path |
|------|------|
| iOS View enhancements | `Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift` |
| Shared L5 platform components | `Framework/Sources/Layers/Layer5-Platform/` (e.g. split view / navigation stack optimizations, card expansion performance config, Messaging/Resource helpers) |

There is **no** `Shared/Views/Extensions/PlatformPerformanceExtensionsLayer5.swift`.

## iOS View APIs (`PlatformIOSOptimizationsLayer5`)

These exist as `extension View` (iOS) with non-iOS stubs where needed:

- `platformIOSNavigationBar(...)`
- `platformIOSToolbar(...)`
- `platformIOSSwipeGestures(...)`
- `platformIOSHapticFeedback(style:onTrigger:)` / `IOSHapticStyle`
- `platformIOSAccessibility(...)`
- `platformIOSAnimation(...)` / `IOSAnimationType`
- `platformIOSLayout(...)`
- `platformIOSPullToRefresh(...)`
- `platformIOSContextMenu(...)`

Coverage for haptics: **#423**. Remaining modifiers in that file: **#424**.

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
