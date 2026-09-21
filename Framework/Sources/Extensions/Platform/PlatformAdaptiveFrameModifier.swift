import SwiftUI

// MARK: - Adaptive Frame Sizing (#468)

/// Pure sizing map for ``AdaptiveFrameModifier`` (unit-lane observable).
public enum AdaptiveFrameSizing {
    /// Deliberate wrong stub for #468 red — replaced after failing assertions.
    public static func dimensions(for metrics: FormContentMetrics) -> (minWidth: CGFloat, minHeight: CGFloat) {
        _ = metrics
        return (minWidth: 0, minHeight: 0)
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
