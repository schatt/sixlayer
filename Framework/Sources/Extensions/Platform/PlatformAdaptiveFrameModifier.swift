import SwiftUI

// MARK: - Adaptive Frame Sizing (#468)

/// Pure sizing map for ``AdaptiveFrameModifier`` (unit-lane observable).
public enum AdaptiveFrameSizing {
    public static func dimensions(for metrics: FormContentMetrics) -> (minWidth: CGFloat, minHeight: CGFloat) {
        let baseWidth: CGFloat = 500
        let baseHeight: CGFloat = 400
        let fieldWidthContribution: CGFloat = 25
        let sectionHeightContribution: CGFloat = 100
        let complexContentBonus: CGFloat = metrics.hasComplexContent ? 200 : 0

        let calculatedWidth = baseWidth + (CGFloat(metrics.fieldCount) * fieldWidthContribution)
        let calculatedHeight =
            baseHeight
            + (CGFloat(metrics.sectionCount) * sectionHeightContribution)
            + complexContentBonus

        let minWidth = max(500, min(900, calculatedWidth))
        let minHeight = max(400, min(1000, calculatedHeight))
        return (minWidth: minWidth, minHeight: minHeight)
    }
}

// MARK: - Adaptive Frame ViewModifier

/// ViewModifier for platform-adaptive frame sizing
/// Analyzes form content and applies appropriate dimensions
public struct AdaptiveFrameModifier: ViewModifier {
    @State private var calculatedWidth: CGFloat = 600
    @State private var calculatedHeight: CGFloat = 700

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: calculatedWidth, minHeight: calculatedHeight)
            .onPreferenceChange(FormContentKey.self) { metrics in
                let (width, height) = AdaptiveFrameSizing.dimensions(for: metrics)
                calculatedWidth = width
                calculatedHeight = height
            }
    }
}
