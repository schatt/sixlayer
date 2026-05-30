import Foundation
import SwiftUI

/// Framework-owned system zoom / layout-scale policy for automatic HIG compliance (GitHub #303).
///
/// **Not pinch-to-zoom** — photo/scanner zoom is a separate product surface.
///
/// **Contract vs Dynamic Type:** typography scaling stays in ``AutomaticHIGTypographyScalingModifier``.
/// This type covers **layout resilience** when the effective UI scale increases (Display Zoom on device,
/// or task-local overrides in unit tests).
public enum PlatformSystemZoomPreference: Sendable {

    /// When non-`nil`, overrides ``layoutScaleFactor`` for the current task (unit tests).
    @TaskLocal public static var testLayoutScaleOverride: CGFloat?

    /// Effective layout scale (1.0 = standard). Values below 1.0 clamp to 1.0.
    public static var layoutScaleFactor: CGFloat {
        if let testLayoutScaleOverride {
            return max(1.0, testLayoutScaleOverride)
        }
        return max(1.0, layoutScaleFactorFromSystem)
    }

    /// Platform read for Display Zoom / system UI scaling. No reliable public API on most platforms — returns 1.0.
    public static var layoutScaleFactorFromSystem: CGFloat {
        1.0
    }

    /// Minimum readable body text point size per platform (HIG baseline at standard scale).
    public static func minimumReadableBodyPointSize(for platform: SixLayerPlatform) -> CGFloat {
        switch platform {
        case .iOS: return 17.0
        case .watchOS: return 16.0
        case .macOS: return 13.0
        case .tvOS: return 24.0
        case .visionOS: return 18.0
        }
    }

    /// Scales an interactive minimum touch target by the effective layout scale.
    public static func scaledTouchTargetMinimum(base: CGFloat, layoutScale: CGFloat? = nil) -> CGFloat {
        let scale = max(layoutScale ?? layoutScaleFactor, 1.0)
        guard base > 0 else { return base }
        return base * scale
    }

    /// Run `body` with a task-local layout-scale override (parallel-test safe).
    public static func withTestLayoutScale<T>(
        _ scale: CGFloat,
        _ body: () throws -> T
    ) rethrows -> T {
        try $testLayoutScaleOverride.withValue(scale, operation: body)
    }

    /// Whether layout-resilience spacing should apply for the given Dynamic Type step.
    public static func requiresLayoutResilience(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize || layoutScaleFactor > 1.0
    }

    /// Extra spacing applied when layout resilience is active.
    public static func layoutResilienceSpacing(
        dynamicTypeSize: DynamicTypeSize,
        layoutScale: CGFloat? = nil
    ) -> CGFloat {
        let scale = max(layoutScale ?? layoutScaleFactor, 1.0)
        guard requiresLayoutResilience(dynamicTypeSize: dynamicTypeSize) || scale > 1.0 else {
            return 0
        }
        return 4.0 * (scale - 1.0) + (dynamicTypeSize.isAccessibilitySize ? 2.0 : 0)
    }
}

private extension DynamicTypeSize {
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }
}

/// Applies layout resilience for system zoom / large accessibility content sizes (GitHub #303).
public struct PlatformSystemZoomSubtreeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init() {}

    public func body(content: Content) -> some View {
        let spacing = PlatformSystemZoomPreference.layoutResilienceSpacing(
            dynamicTypeSize: dynamicTypeSize
        )
        if spacing > 0 {
            content.padding(spacing)
        } else {
            content
        }
    }
}

/// Automatic-compliance chain modifier for system zoom layout resilience (GitHub #303).
public struct AutomaticHIGSystemZoomModifier: ViewModifier {
    let platform: SixLayerPlatform

    public init(platform: SixLayerPlatform) {
        self.platform = platform
    }

    public func body(content: Content) -> some View {
        content.modifier(PlatformSystemZoomSubtreeModifier())
    }
}

public extension View {
    /// Opt-in layout resilience for system zoom / enlarged UI (distinct from pinch-to-zoom).
    func platformSystemZoomAdaptiveLayout() -> some View {
        modifier(PlatformSystemZoomSubtreeModifier())
    }
}
