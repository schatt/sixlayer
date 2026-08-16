import Testing
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Explicit Count-Based Presentation (.countBased)")
open class ExplicitCountBasedPresentationTests: BaseTestClass {

    // MARK: - Basic Count-Based Functionality Tests

    /// BUSINESS PURPOSE: Verify that .countBased uses lowCount preference when count ≤ threshold
    @Test func testCountBasedUsesLowCountForSmallCollections() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        #expect(resolve(hints: hints, itemCount: 3) == .expandableCards)
    }

    /// BUSINESS PURPOSE: Verify that .countBased uses highCount preference when count > threshold
    @Test func testCountBasedUsesHighCountForLargeCollections() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        #expect(resolve(hints: hints, itemCount: 8) == .list)
    }

    // MARK: - Threshold Edge Cases

    /// BUSINESS PURPOSE: Verify exact threshold boundary behavior
    @Test func testCountBasedExactThresholdUsesLowCount() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .grid, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        #expect(resolve(hints: hints, itemCount: 5) == .grid)
    }

    /// BUSINESS PURPOSE: Verify threshold = 0 edge case
    @Test func testCountBasedThresholdZero() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 0),
            complexity: .moderate,
            context: .dashboard
        )

        #expect(resolve(hints: hints, itemCount: 1) == .list)
    }

    // MARK: - Preference Type Combinations

    /// BUSINESS PURPOSE: Verify all basic preference types work as lowCount/highCount
    @Test func testCountBasedPreferenceTypeMapping() {
        let cardsHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: cardsHints, itemCount: 2) == .expandableCards)

        let gridHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .grid, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: gridHints, itemCount: 2) == .grid)

        let masonryHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .masonry, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: masonryHints, itemCount: 2) == .masonry)

        let coverFlowHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .coverFlow, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: coverFlowHints, itemCount: 2) == .coverFlow)
    }

    // MARK: - Nested Automatic Preference

    /// BUSINESS PURPOSE: Verify nested .automatic in .countBased uses count-aware logic
    @Test func testCountBasedWithNestedAutomatic() {
        let lowAutoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .automatic, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: lowAutoHints, itemCount: 3) == .grid)

        let highAutoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .automatic, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: highAutoHints, itemCount: 8) == .grid)
    }

    // MARK: - Content Type Independence

    /// BUSINESS PURPOSE: media/navigation dataTypes ignore .countBased and use platform defaults
    @Test func testCountBasedWorksWithAllContentTypes() {
        let navHints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .navigation
        )
        #expect(resolve(hints: navHints, itemCount: 2) == .masonry)

        let mediaHints = PresentationHints(
            dataType: .media,
            presentationPreference: .countBased(lowCount: .grid, highCount: .masonry, threshold: 5),
            complexity: .moderate,
            context: .gallery
        )
        #expect(resolve(hints: mediaHints, itemCount: 2) == .expandableCards)
    }

    // MARK: - Empty Collection Edge Case

    /// BUSINESS PURPOSE: Verify empty collection uses lowCount (0 ≤ threshold)
    @Test func testCountBasedWithEmptyCollection() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        #expect(resolve(hints: hints, itemCount: 0) == .expandableCards)
    }

    // MARK: - Backward Compatibility

    /// BUSINESS PURPOSE: Verify existing preferences still work alongside .countBased
    @Test func testBackwardCompatibilityWithExistingPreferences() {
        let listHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: listHints, itemCount: 3) == .list)

        let autoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: autoHints, itemCount: 3) == .grid)
    }

    // MARK: - Complex Nested Scenarios

    /// BUSINESS PURPOSE: Verify nested countBased falls back and large thresholds stay on lowCount
    @Test func testComplexNestedCountBasedScenarios() {
        let nestedHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(
                lowCount: .countBased(lowCount: .cards, highCount: .grid, threshold: 1),
                highCount: .list,
                threshold: 5
            ),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: nestedHints, itemCount: 2) == .adaptive)

        let largeThresholdHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 100),
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: largeThresholdHints, itemCount: 10) == .expandableCards)
    }

    // MARK: - Helpers

    /// macOS/mac matrix so iOS and macOS lanes share the same countBased contract (#248).
    private func resolve(hints: PresentationHints, itemCount: Int) -> ItemCollectionPresentationStrategy {
        ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: itemCount,
            platform: .macOS,
            deviceType: .mac
        )
    }
}
