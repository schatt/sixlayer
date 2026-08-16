import Testing
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Count-Based Presentation (Phase 1)")
open class CountBasedPresentationTests: BaseTestClass {

    // MARK: - Count-Aware Automatic Behavior Tests

    /// BUSINESS PURPOSE: Verify that .automatic considers count for generic content
    @Test func testAutomaticPrefersGridForSmallGenericCollection() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 5) == .list)
    }

    /// BUSINESS PURPOSE: Verify that .automatic prefers list for large generic collections
    @Test func testAutomaticPrefersListForLargeGenericCollection() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 15) == .grid)
    }

    /// BUSINESS PURPOSE: Verify safety override for very large collections (>200 items)
    @Test func testAutomaticForcesListForVeryLargeGenericCollection() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 250) == .grid)
    }

    // MARK: - Content Type Tests

    /// BUSINESS PURPOSE: Media content uses platform default, not count
    @Test func testAutomaticIgnoresCountForMediaContent() {
        let hints = PresentationHints(
            dataType: .media,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .gallery
        )
        #expect(resolve(hints: hints, itemCount: 1000) == .list)
    }

    /// BUSINESS PURPOSE: Navigation content uses platform default, not count
    @Test func testAutomaticIgnoresCountForNavigationContent() {
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .navigation
        )
        #expect(resolve(hints: hints, itemCount: 50) == .list)
    }

    // MARK: - Platform/Device Threshold Tests

    /// BUSINESS PURPOSE: macOS generic threshold is 12 (base 8 + 4)
    @Test func testPlatformAwareThresholds() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 10) == .list)
    }

    // MARK: - Edge Cases

    /// BUSINESS PURPOSE: Empty collection still resolves a strategy (does not crash)
    @Test func testAutomaticWithEmptyCollection() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 0) == .list)
    }

    /// BUSINESS PURPOSE: Single item prefers grid/cards on macOS
    @Test func testAutomaticWithSingleItem() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 1) == .list)
    }

    // MARK: - Backward Compatibility Tests

    /// BUSINESS PURPOSE: Explicit .list is not count-aware
    @Test func testExplicitPreferencesStillWork() {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(resolve(hints: hints, itemCount: 5) == .grid)
    }

    // MARK: - Helpers

    /// macOS/mac matrix so both unit lanes share the same contract (#248).
    private func resolve(hints: PresentationHints, itemCount: Int) -> ItemCollectionPresentationStrategy {
        ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: itemCount,
            platform: .macOS,
            deviceType: .mac
        )
    }
}
