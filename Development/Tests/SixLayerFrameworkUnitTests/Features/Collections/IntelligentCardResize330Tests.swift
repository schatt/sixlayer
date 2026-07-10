import Testing
import SwiftUI
@testable import SixLayerFramework

/// Window/container resize layout for intelligent cards (GitHub #330).
/// Width-capped columns, grow/shrink within min/max, sparse height grow, dense max+scroll.
@Suite("Intelligent Card Resize #330")
struct IntelligentCardResize330Tests {

    // MARK: - Width-capped columns

    @Test func mac_narrowWidth_floorsToOneColumn_andCardWidthFits() {
        let screenWidth: CGFloat = 320
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 6,
            screenWidth: screenWidth,
            deviceType: .mac,
            contentComplexity: .moderate
        )
        let availableWidth = screenWidth - decision.padding * 2
        #expect(decision.columns == 1)
        #expect(decision.cardWidth <= availableWidth + 0.5)
    }

    @Test func pad_narrowWidth_doesNotForceTwoColumnsWhenWidthCannotFit() {
        let screenWidth: CGFloat = 400
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 8,
            screenWidth: screenWidth,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        let availableWidth = screenWidth - decision.padding * 2
        let minWidthForTwo = decision.cardWidth * 2 + decision.spacing
        #expect(decision.columns == 1 || minWidthForTwo <= availableWidth + 0.5)
        #expect(decision.cardWidth <= availableWidth + 0.5)
        #expect(decision.columns == 1)
    }

    @Test func mac_mediumWidth_allowsMultipleColumnsWhenBudgetFits() {
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 9,
            screenWidth: 900,
            deviceType: .mac,
            contentComplexity: .moderate
        )
        #expect(decision.columns >= 2)
        let availableWidth = 900 - decision.padding * 2
        let rowWidth = CGFloat(decision.columns) * decision.cardWidth
            + CGFloat(decision.columns - 1) * decision.spacing
        #expect(rowWidth <= availableWidth + 0.5)
    }

    @Test func mac_veryNarrowWidth_allowsCardWidthBelowLegacyMin200() {
        // padding*2 = 32 → available 168 < preferred min 200
        let screenWidth: CGFloat = 200
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 3,
            screenWidth: screenWidth,
            deviceType: .mac,
            contentComplexity: .simple
        )
        let availableWidth = screenWidth - decision.padding * 2
        #expect(decision.columns == 1)
        #expect(decision.cardWidth <= availableWidth + 0.5)
        #expect(decision.cardWidth < 200)
        #expect(availableWidth < 200)
    }

    // MARK: - Height grow / max + scroll

    @Test func mac_sparseTallViewport_growsCardHeightVersusShortViewport() {
        let tall = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 800,
            deviceType: .mac,
            contentComplexity: .moderate,
            viewportHeight: 900
        )
        let short = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 800,
            deviceType: .mac,
            contentComplexity: .moderate,
            viewportHeight: 400
        )
        #expect(tall.cardHeight > short.cardHeight + 0.5)
        #expect(tall.cardHeight <= 900 - tall.padding * 2 + 0.5)
    }

    @Test func mac_denseShortViewport_doesNotForceFitAllRowsIntoViewport() {
        let decision = determineIntelligentCardLayout_L2(
            contentCount: 10,
            screenWidth: 800,
            deviceType: .mac,
            contentComplexity: .moderate,
            viewportHeight: 360
        )
        let rows = Int(ceil(Double(10) / Double(decision.columns)))
        let forceFitPerRow = (360 - decision.padding * 2 - decision.spacing * CGFloat(max(0, rows - 1)))
            / CGFloat(rows)
        // Dense + short: keep readable height and scroll — do not squash to fit all rows.
        #expect(decision.cardHeight > forceFitPerRow + 0.5)
    }

    @Test func mac_verticalOnlyResize_updatesCardHeight() {
        let wideShort = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 1000,
            deviceType: .mac,
            contentComplexity: .moderate,
            viewportHeight: 350
        )
        let wideTall = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 1000,
            deviceType: .mac,
            contentComplexity: .moderate,
            viewportHeight: 800
        )
        #expect(wideTall.cardHeight > wideShort.cardHeight + 0.5)
    }

    @Test func phone_narrowWidth_stillUsesOneOrTwoColumnsWithoutRegression() {
        let narrow = determineIntelligentCardLayout_L2(
            contentCount: 5,
            screenWidth: 320,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        #expect(narrow.columns == 1)
        let wider = determineIntelligentCardLayout_L2(
            contentCount: 5,
            screenWidth: 430,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        #expect(wider.columns == 2)
    }
}
