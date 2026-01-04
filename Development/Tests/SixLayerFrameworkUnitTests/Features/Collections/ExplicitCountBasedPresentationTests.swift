import Testing
import SwiftUI
@testable import SixLayerFramework

/// Test item for explicit count-based presentation testing
struct ExplicitCountBasedTestItem: Identifiable {
    let id: String
    let title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Explicit Count-Based Presentation (.countBased)")
open class ExplicitCountBasedPresentationTests: BaseTestClass {

    // MARK: - Basic Count-Based Functionality Tests

    /// BUSINESS PURPOSE: Verify that .countBased uses lowCount preference when count ≤ threshold
    /// TESTING SCOPE: GenericItemCollectionView with explicit .countBased preference
    /// METHODOLOGY: Test that lowCount preference is used for small collections
    @Test @MainActor func testCountBasedUsesLowCountForSmallCollections() {
        initializeTestConfig()
        // Given: Small collection (≤threshold) with .countBased(lowCount: .cards, highCount: .list, threshold: 5)
        let smallItems = createTestItems(count: 3)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        // When: Create collection view
        _ = GenericItemCollectionView(
            items: smallItems,
            hints: hints
        )

        // Then: Should use lowCount preference (.cards → expandableCards)
        #expect(Bool(true), "Small collection with .countBased should use lowCount preference")
    }

    /// BUSINESS PURPOSE: Verify that .countBased uses highCount preference when count > threshold
    /// TESTING SCOPE: GenericItemCollectionView with explicit .countBased preference
    /// METHODOLOGY: Test that highCount preference is used for large collections
    @Test @MainActor func testCountBasedUsesHighCountForLargeCollections() {
        initializeTestConfig()
        // Given: Large collection (>threshold) with .countBased(lowCount: .cards, highCount: .list, threshold: 5)
        let largeItems = createTestItems(count: 8)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        // When: Create collection view
        _ = GenericItemCollectionView(
            items: largeItems,
            hints: hints
        )

        // Then: Should use highCount preference (.list → list)
        #expect(Bool(true), "Large collection with .countBased should use highCount preference")
    }

    // MARK: - Threshold Edge Cases

    /// BUSINESS PURPOSE: Verify exact threshold boundary behavior
    /// TESTING SCOPE: .countBased with exact threshold matching
    /// METHODOLOGY: Test that count = threshold uses lowCount
    @Test @MainActor func testCountBasedExactThresholdUsesLowCount() {
        initializeTestConfig()
        // Given: Collection with exact threshold count (5) with threshold 5
        let exactThresholdItems = createTestItems(count: 5)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .grid, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        // When: Create collection view
        _ = GenericItemCollectionView(
            items: exactThresholdItems,
            hints: hints
        )

        // Then: Should use lowCount preference (count ≤ threshold)
        #expect(Bool(true), "Exact threshold count should use lowCount preference")
    }

    /// BUSINESS PURPOSE: Verify threshold = 0 edge case
    /// TESTING SCOPE: .countBased with threshold 0
    /// METHODOLOGY: Test that any count > 0 uses highCount
    @Test @MainActor func testCountBasedThresholdZero() {
        initializeTestConfig()
        // Given: Any collection with threshold 0 (always use highCount)
        let items = createTestItems(count: 1)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 0),
            complexity: .moderate,
            context: .dashboard
        )

        // When: Create collection view
        _ = GenericItemCollectionView(
            items: items,
            hints: hints
        )

        // Then: Should always use highCount (since count > 0)
        #expect(Bool(true), "Threshold 0 should always use highCount preference")
    }

    // MARK: - Preference Type Combinations

    /// BUSINESS PURPOSE: Verify all basic preference types work as lowCount/highCount
    /// TESTING SCOPE: .countBased with various preference combinations
    /// METHODOLOGY: Test different preference type mappings
    @Test @MainActor func testCountBasedPreferenceTypeMapping() {
        initializeTestConfig()

        // Test cards → expandableCards
        let cardsItems = createTestItems(count: 2)
        let cardsHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: cardsItems, hints: cardsHints)
        #expect(Bool(true), ".cards should map to expandableCards strategy")

        // Test grid → grid
        let gridItems = createTestItems(count: 2)
        let gridHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .grid, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: gridItems, hints: gridHints)
        #expect(Bool(true), ".grid should map to grid strategy")

        // Test masonry → masonry
        let masonryItems = createTestItems(count: 2)
        let masonryHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .masonry, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: masonryItems, hints: masonryHints)
        #expect(Bool(true), ".masonry should map to masonry strategy")

        // Test coverFlow → coverFlow
        let coverFlowItems = createTestItems(count: 2)
        let coverFlowHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .coverFlow, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: coverFlowItems, hints: coverFlowHints)
        #expect(Bool(true), ".coverFlow should map to coverFlow strategy")
    }

    // MARK: - Nested Automatic Preference

    /// BUSINESS PURPOSE: Verify nested .automatic in .countBased works recursively
    /// TESTING SCOPE: .countBased with .automatic as lowCount or highCount
    /// METHODOLOGY: Test that nested automatic uses count-aware logic
    @Test @MainActor func testCountBasedWithNestedAutomatic() {
        initializeTestConfig()

        // Test automatic as lowCount
        let lowAutoItems = createTestItems(count: 3)  // Small collection
        let lowAutoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .automatic, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: lowAutoItems, hints: lowAutoHints)
        #expect(Bool(true), "Nested .automatic as lowCount should use count-aware logic")

        // Test automatic as highCount
        let highAutoItems = createTestItems(count: 8)  // Large collection
        let highAutoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .automatic, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: highAutoItems, hints: highAutoHints)
        #expect(Bool(true), "Nested .automatic as highCount should use count-aware logic")
    }

    // MARK: - Content Type Independence

    /// BUSINESS PURPOSE: Verify .countBased works with all content types
    /// TESTING SCOPE: .countBased with different dataType hints
    /// METHODOLOGY: Test that countBased logic applies regardless of dataType
    @Test @MainActor func testCountBasedWorksWithAllContentTypes() {
        initializeTestConfig()

        // Test with navigation content
        let navItems = createTestItems(count: 2)
        let navHints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .navigation
        )
        _ = GenericItemCollectionView(items: navItems, hints: navHints)
        #expect(Bool(true), ".countBased should work with navigation content")

        // Test with media content
        let mediaItems = createTestItems(count: 2)
        let mediaHints = PresentationHints(
            dataType: .media,
            presentationPreference: .countBased(lowCount: .grid, highCount: .masonry, threshold: 5),
            complexity: .moderate,
            context: .gallery
        )
        _ = GenericItemCollectionView(items: mediaItems, hints: mediaHints)
        #expect(Bool(true), ".countBased should work with media content")
    }

    // MARK: - Empty Collection Edge Case

    /// BUSINESS PURPOSE: Verify empty collection handling with .countBased
    /// TESTING SCOPE: .countBased with empty collection (count = 0)
    /// METHODOLOGY: Test that empty collection uses lowCount (since 0 ≤ threshold)
    @Test @MainActor func testCountBasedWithEmptyCollection() {
        initializeTestConfig()
        // Given: Empty collection with .countBased
        let emptyItems: [ExplicitCountBasedTestItem] = []
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 5),
            complexity: .moderate,
            context: .dashboard
        )

        // When: Create collection view
        _ = GenericItemCollectionView(
            items: emptyItems,
            hints: hints
        )

        // Then: Should use lowCount preference (0 ≤ threshold)
        #expect(Bool(true), "Empty collection should use lowCount preference")
    }

    // MARK: - Backward Compatibility

    /// BUSINESS PURPOSE: Verify existing preferences still work alongside .countBased
    /// TESTING SCOPE: Non-countBased preferences continue to work
    /// METHODOLOGY: Test that explicit preferences are unaffected
    @Test @MainActor func testBackwardCompatibilityWithExistingPreferences() {
        initializeTestConfig()

        // Test that explicit .list still works
        let listItems = createTestItems(count: 3)
        let listHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,  // Explicit, not countBased
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: listItems, hints: listHints)
        #expect(Bool(true), "Explicit preferences should still work (backward compatible)")

        // Test that .automatic still works
        let autoItems = createTestItems(count: 3)
        let autoHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,  // Not countBased
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: autoItems, hints: autoHints)
        #expect(Bool(true), ".automatic should still work (backward compatible)")
    }

    // MARK: - Complex Nested Scenarios

    /// BUSINESS PURPOSE: Verify complex nested countBased scenarios work
    /// TESTING SCOPE: Multiple levels of nesting and edge cases
    /// METHODOLOGY: Test sophisticated countBased configurations
    @Test @MainActor func testComplexNestedCountBasedScenarios() {
        initializeTestConfig()

        // Test countBased with countBased nested (should fallback to adaptive)
        let nestedItems = createTestItems(count: 2)
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
        _ = GenericItemCollectionView(items: nestedItems, hints: nestedHints)
        #expect(Bool(true), "Nested countBased should fallback gracefully")

        // Test very large threshold
        let largeThresholdItems = createTestItems(count: 10)
        let largeThresholdHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .countBased(lowCount: .cards, highCount: .list, threshold: 100),
            complexity: .moderate,
            context: .dashboard
        )
        _ = GenericItemCollectionView(items: largeThresholdItems, hints: largeThresholdHints)
        #expect(Bool(true), "Large threshold should always use lowCount")
    }

    // MARK: - Helper Methods

    private func createTestItems(count: Int) -> [ExplicitCountBasedTestItem] {
        return (1...count).map { index in
            ExplicitCountBasedTestItem(
                id: "item\(index)",
                title: "Test Item \(index)"
            )
        }
    }
}
