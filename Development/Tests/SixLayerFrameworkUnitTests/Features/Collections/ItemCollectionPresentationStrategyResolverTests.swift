import Testing
@testable import SixLayerFramework

@Suite("Item collection presentation strategy resolver")
struct ItemCollectionPresentationStrategyResolverTests {
    @Test func resolveListPreferenceUsesListLayout() {
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse
        )
        let strategy = ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: 5,
            platform: .iOS,
            deviceType: .phone
        )
        #expect(strategy == .list)
    }

    @Test func resolveCardsPreferenceUsesExpandableCards() {
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .browse
        )
        let strategy = ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: 3,
            platform: .macOS,
            deviceType: .mac
        )
        #expect(strategy == .expandableCards)
    }

    @Test func resolveLargeAutomaticCollectionUsesList() {
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .browse
        )
        let strategy = ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: 500,
            platform: .iOS,
            deviceType: .phone
        )
        #expect(strategy == .list)
    }

    @Test func resolveCountBasedUsesThreshold() {
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .countBased(
                lowCount: .grid,
                highCount: .list,
                threshold: 10
            ),
            complexity: .moderate,
            context: .browse
        )
        let low = ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: 5,
            platform: .iOS,
            deviceType: .phone
        )
        let high = ItemCollectionPresentationStrategyResolver.resolve(
            hints: hints,
            itemCount: 20,
            platform: .iOS,
            deviceType: .phone
        )
        #expect(low == .grid)
        #expect(high == .list)
    }
}
