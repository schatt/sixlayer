import Testing
import SwiftUI
@testable import SixLayerFramework

/// Content-aware minimum intelligent card height (#309).
@Suite("Intelligent Card Content-Aware Height")
struct IntelligentCardContentAwareHeightTests {

    @Test func contentAwareMinimumIntelligentCardHeight_IncreasesWithAccessibilityContentSize() {
        let large = contentAwareMinimumIntelligentCardHeight(
            cardWidth: 320,
            contentComplexity: .moderate,
            contentSizeCategory: .large
        )
        let accessibility = contentAwareMinimumIntelligentCardHeight(
            cardWidth: 320,
            contentComplexity: .moderate,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        #expect(accessibility > large)
    }

    @Test func contentAwareMinimumIntelligentCardHeight_IncreasesWithComplexity() {
        let simple = contentAwareMinimumIntelligentCardHeight(
            cardWidth: 320,
            contentComplexity: .simple,
            contentSizeCategory: .accessibilityLarge
        )
        let veryComplex = contentAwareMinimumIntelligentCardHeight(
            cardWidth: 320,
            contentComplexity: .veryComplex,
            contentSizeCategory: .accessibilityLarge
        )
        #expect(veryComplex > simple)
    }

    @Test @MainActor func determineIntelligentCardLayout_L2_AppliesContentFloorWhenViewportBudgetAllows() {
        let defaultDecision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .veryComplex,
            viewportHeight: 420,
            preferredContentSizeCategory: .large
        )
        let accessibilityDecision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .veryComplex,
            viewportHeight: 420,
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let floor = contentAwareMinimumIntelligentCardHeight(
            cardWidth: defaultDecision.cardWidth,
            contentComplexity: .veryComplex,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        #expect(accessibilityDecision.cardHeight >= floor - 0.5)
        #expect(accessibilityDecision.cardHeight > defaultDecision.cardHeight)
    }

    @Test @MainActor func determineIntelligentCardLayout_L2_LeavesTightViewportClampUnchanged() {
        let viewport: CGFloat = 220
        let defaultDecision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate,
            viewportHeight: viewport,
            preferredContentSizeCategory: .large
        )
        let accessibilityDecision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate,
            viewportHeight: viewport,
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        #expect(abs(accessibilityDecision.cardHeight - defaultDecision.cardHeight) < 0.5)
    }
}
