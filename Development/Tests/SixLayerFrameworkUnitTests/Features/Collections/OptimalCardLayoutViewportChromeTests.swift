import Testing
import SwiftUI
@testable import SixLayerFramework

/// Chrome-adjusted viewport for optimal card layout path (GitHub #308).
@Suite("Optimal Card Layout Viewport Chrome")
struct OptimalCardLayoutViewportChromeTests {

    @Test @MainActor func responsiveCardsView_ResolvesEffectiveViewportBeforeOptimalLayout() {
        let geometryHeight: CGFloat = 800
        let chrome = CardViewportHints(topChromeInset: 96, bottomChromeInset: 83)
        let withChrome = ResponsiveCardsView.optimalLayoutDecision(
            contentCount: 6,
            screenWidth: 390,
            geometryHeight: geometryHeight,
            viewportHints: chrome
        )
        let withoutChrome = ResponsiveCardsView.optimalLayoutDecision(
            contentCount: 6,
            screenWidth: 390,
            geometryHeight: geometryHeight,
            viewportHints: nil
        )
        #expect(withChrome.viewportHeight == 621)
        #expect(withoutChrome.viewportHeight == geometryHeight)
        #expect(withChrome.cardRowHeight < withoutChrome.cardRowHeight)
    }

    @Test @MainActor func responsiveCardsView_ZeroChromeInsetsMatchFullGeometryViewport() {
        let geometryHeight: CGFloat = 640
        let decision = ResponsiveCardsView.optimalLayoutDecision(
            contentCount: 6,
            screenWidth: 390,
            geometryHeight: geometryHeight,
            viewportHints: CardViewportHints()
        )
        #expect(decision.viewportHeight == geometryHeight)
    }

    @Test @MainActor func determineOptimalCardLayout_L2_RemainsBackwardCompatibleWithoutHints() {
        let decision = determineOptimalCardLayout_L2(
            contentCount: 6,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        #expect(decision.viewportHeight == nil)
        #expect(decision.cardRowHeight == 120)
    }
}
