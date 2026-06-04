import Testing
import SwiftUI
@testable import SixLayerFramework

/// Card viewport host hints API and layout integration (GitHub #306).
@Suite("Card Viewport Host Hints")
struct CardViewportHostHintsTests {

    // MARK: - PresentationHints API

    @Test func presentationHintsDefaultsViewportHintsToNil() {
        let hints = PresentationHints()
        #expect(hints.viewportHints == nil)
    }

    @Test func cardViewportHintsDefaultsAreBackwardCompatible() {
        let hints = CardViewportHints()
        #expect(hints.topChromeInset == 0)
        #expect(hints.bottomChromeInset == 0)
        #expect(hints.maxCardHeight == nil)
        #expect(hints.preferFitInViewport == false)
    }

    // MARK: - L4 effective viewport resolution

    @Test @MainActor func effectiveCardCollectionViewportHeightSubtractsChromeInsets() {
        let geometryHeight: CGFloat = 800
        let viewportHints = CardViewportHints(topChromeInset: 96, bottomChromeInset: 83)
        let effective = PlatformFrameHelpers.effectiveCardCollectionViewportHeight(
            geometryHeight: geometryHeight,
            viewportHints: viewportHints
        )
        #expect(effective == 621)
    }

    @Test @MainActor func effectiveCardCollectionViewportHeightWithoutHintsMatchesFiniteGeometry() {
        let geometryHeight: CGFloat = 640
        let withoutHints = PlatformFrameHelpers.effectiveCardCollectionViewportHeight(
            geometryHeight: geometryHeight,
            viewportHints: nil
        )
        let finite = PlatformFrameHelpers.finiteViewportHeight(for: geometryHeight)
        #expect(withoutHints == finite)
    }

    @Test @MainActor func effectiveCardCollectionViewportHeightWithZeroInsetsMatchesFiniteGeometry() {
        let geometryHeight: CGFloat = 640
        let effective = PlatformFrameHelpers.effectiveCardCollectionViewportHeight(
            geometryHeight: geometryHeight,
            viewportHints: CardViewportHints()
        )
        #expect(effective == geometryHeight)
    }

    // MARK: - L2 maxCardHeight and preferFitInViewport

    @Test @MainActor func determineIntelligentCardLayout_L2_HonorsMaxCardHeight() {
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate,
            viewportHeight: 500,
            viewportHints: CardViewportHints(maxCardHeight: 140)
        )
        #expect(decision.cardHeight <= 140 + 0.5)
    }

    @Test @MainActor func determineIntelligentCardLayout_L2_PreferFitInViewportFalseSkipsViewportClampOnPhone() {
        let withoutFit = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate,
            viewportHeight: 500,
            viewportHints: CardViewportHints(preferFitInViewport: false)
        )
        let withLegacyPhoneClamp = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 390,
            deviceType: .phone,
            contentComplexity: .moderate,
            viewportHeight: 500
        )
        #expect(withoutFit.cardHeight > withLegacyPhoneClamp.cardHeight)
    }

    @Test @MainActor func determineIntelligentCardLayout_L2_PreferFitInViewportTrueClampsOnPad() {
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 2,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .moderate,
            viewportHeight: 360,
            viewportHints: CardViewportHints(preferFitInViewport: true)
        )
        let rows = (2 + decision.columns - 1) / decision.columns
        let perRowBudget = (360 - decision.padding * 2 - decision.spacing * CGFloat(max(0, rows - 1))) / CGFloat(rows)
        #expect(decision.cardHeight <= perRowBudget + 0.5)
    }
}
