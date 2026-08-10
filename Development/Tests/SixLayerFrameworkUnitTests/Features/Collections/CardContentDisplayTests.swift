import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: Card components (simple/list/masonry) surface CardDisplayable item data.
 *
 * TESTING SCOPE: Item wiring (`cardTitle` / icon / subtitle), layoutDecision retention,
 * hostability. Rendered title/icon tree text → VI/XCUI (#403).
 *
 * METHODOLOGY: Unit contracts — no Bool(true) non-optional theater (#382).
 */
@Suite("Card Content Display", HostedViewTestIsolationTrait())
open class CardContentDisplayTests: BaseTestClass {

    struct TestItem: Identifiable, CardDisplayable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let description: String?
        let icon: String?
        let color: Color?

        var cardTitle: String { title }
        var cardSubtitle: String? { subtitle }
        var cardDescription: String? { description }
        var cardIcon: String? { icon }
    }

    @MainActor
    func createCardTestItems() -> [TestItem] {
        [
            TestItem(title: "Test Item 1", subtitle: "Subtitle 1", description: "Description 1", icon: "star.fill", color: Color.blue),
            TestItem(title: "Test Item 2", subtitle: "Subtitle 2", description: "Description 2", icon: "heart.fill", color: Color.red),
            TestItem(title: "Test Item 3", subtitle: nil, description: "Description 3", icon: nil, color: Color.green)
        ]
    }

    @MainActor
    private func expectHostable<V: View>(_ view: V, _ label: String) {
        #expect(
            PlatformContainerStructureAssertions.isHostable(view),
            "\(label) should be hostable (#382)"
        )
    }

    // MARK: - SimpleCardComponent

    @Test @MainActor func testSimpleCardComponentDisplaysItemTitle() {
        initializeTestConfig()
        let item = createCardTestItems()[0]
        let layoutDecision = createLayoutDecision()
        let sut = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        #expect(sut.item.cardTitle == "Test Item 1")
        #expect(sut.layoutDecision.columns == layoutDecision.columns)
        expectHostable(sut, "SimpleCardComponent title")
    }

    @Test @MainActor func testSimpleCardComponentDisplaysItemIcon() {
        initializeTestConfig()
        let item = createCardTestItems()[0]
        let sut = SimpleCardComponent(
            item: item,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        #expect(sut.item.cardIcon == "star.fill")
        expectHostable(sut, "SimpleCardComponent icon")
    }

    @Test @MainActor func testSimpleCardComponentHandlesMissingIcon() {
        initializeTestConfig()
        let item = createCardTestItems()[2]
        let sut = SimpleCardComponent(
            item: item,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        #expect(sut.item.cardIcon == nil)
        #expect(sut.item.cardTitle == "Test Item 3")
        expectHostable(sut, "SimpleCardComponent missing icon")
    }

    @Test @MainActor func testSimpleCardComponentDisplaysTitleAndDescription() {
        initializeTestConfig()
        let item = createCardTestItems()[0]
        let sut = SimpleCardComponent(
            item: item,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        #expect(sut.item.cardTitle == "Test Item 1")
        #expect(sut.item.cardDescription == "Description 1")
        expectHostable(sut, "SimpleCardComponent description")
    }

    @Test @MainActor func testSimpleCardComponentExpandedContentData() {
        initializeTestConfig()
        let item = createCardTestItems()[1]
        let sut = SimpleCardComponent(
            item: item,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        #expect(sut.item.cardTitle == "Test Item 2")
        #expect(sut.item.cardSubtitle == "Subtitle 2")
        expectHostable(sut, "SimpleCardComponent expanded data")
    }

    // MARK: - ListCardComponent

    @Test @MainActor func testListCardComponentDisplaysTitleAndSubtitle() {
        initializeTestConfig()
        let item = createCardTestItems()[0]
        let sut = ListCardComponent(item: item, hints: PresentationHints())
        #expect(sut.item.cardTitle == "Test Item 1")
        #expect(sut.item.cardSubtitle == "Subtitle 1")
        expectHostable(sut, "ListCardComponent")
    }

    @Test @MainActor func testListCardComponentHandlesMissingSubtitle() {
        initializeTestConfig()
        let item = createCardTestItems()[2]
        let sut = ListCardComponent(item: item, hints: PresentationHints())
        #expect(sut.item.cardSubtitle == nil)
        #expect(sut.item.cardTitle == "Test Item 3")
        expectHostable(sut, "ListCardComponent missing subtitle")
    }

    // MARK: - MasonryCardComponent

    @Test @MainActor func testMasonryCardComponentDisplaysTitle() {
        initializeTestConfig()
        let item = createCardTestItems()[0]
        let sut = MasonryCardComponent(item: item, hints: PresentationHints())
        #expect(sut.item.cardTitle == "Test Item 1")
        expectHostable(sut, "MasonryCardComponent")
    }

    // MARK: - Generic items

    @Test @MainActor func testCardComponentsWorkWithGenericDataItem() {
        initializeTestConfig()
        let layoutDecision = createLayoutDecision()
        let item = GenericDataItem(title: "Generic 1", subtitle: "Subtitle 1", data: ["type": "test"])
        let simple = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        let list = ListCardComponent(item: item, hints: PresentationHints())
        let masonry = MasonryCardComponent(item: item, hints: PresentationHints())

        #expect(simple.item.cardTitle == "Generic 1")
        #expect(list.item.cardTitle == "Generic 1")
        #expect(masonry.item.cardTitle == "Generic 1")
        expectHostable(simple, "SimpleCard GenericDataItem")
        expectHostable(list, "ListCard GenericDataItem")
        expectHostable(masonry, "MasonryCard GenericDataItem")
    }

    @Test @MainActor func testCardComponentsWorkWithGenericVehicleShapedItem() {
        initializeTestConfig()
        let layoutDecision = createLayoutDecision()
        let item = GenericDataItem(title: "Car 1", subtitle: "A nice car")
        let simple = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        let list = ListCardComponent(item: item, hints: PresentationHints())
        let masonry = MasonryCardComponent(item: item, hints: PresentationHints())

        #expect(simple.item.cardTitle == "Car 1")
        #expect(list.item.cardSubtitle == "A nice car")
        #expect(masonry.item.cardTitle == "Car 1")
        expectHostable(simple, "SimpleCard vehicle-shaped")
        expectHostable(list, "ListCard vehicle-shaped")
        expectHostable(masonry, "MasonryCard vehicle-shaped")
    }

    // MARK: - Edge cases

    @Test @MainActor func testCardComponentsWithEmptyStrings() {
        initializeTestConfig()
        let emptyItem = TestItem(title: "", subtitle: "", description: "", icon: "", color: nil)
        let simple = SimpleCardComponent(
            item: emptyItem,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        let list = ListCardComponent(item: emptyItem, hints: PresentationHints())
        let masonry = MasonryCardComponent(item: emptyItem, hints: PresentationHints())

        #expect(simple.item.cardTitle.isEmpty)
        #expect(list.item.cardSubtitle == "")
        #expect(masonry.item.cardIcon == "")
        expectHostable(simple, "SimpleCard empty strings")
        expectHostable(list, "ListCard empty strings")
        expectHostable(masonry, "MasonryCard empty strings")
    }

    @Test @MainActor func testCardComponentsWithVeryLongText() {
        initializeTestConfig()
        let longText = String(repeating: "Very long text that should be truncated properly. ", count: 10)
        let longItem = TestItem(
            title: longText,
            subtitle: longText,
            description: longText,
            icon: "star.fill",
            color: Color.blue
        )
        let simple = SimpleCardComponent(
            item: longItem,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        let list = ListCardComponent(item: longItem, hints: PresentationHints())
        let masonry = MasonryCardComponent(item: longItem, hints: PresentationHints())

        #expect(simple.item.cardTitle.count > 100)
        #expect(list.item.cardTitle == longText)
        #expect(masonry.item.cardIcon == "star.fill")
        expectHostable(simple, "SimpleCard long text")
        expectHostable(list, "ListCard long text")
        expectHostable(masonry, "MasonryCard long text")
    }

    @Test @MainActor func testCardComponentsHaveProperAccessibilityWiring() {
        initializeTestConfig()
        // Tree labels/hints need VI (#403); unit observes item wiring + hostability.
        let item = createCardTestItems()[0]
        let simple = SimpleCardComponent(
            item: item,
            layoutDecision: createLayoutDecision(),
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        let list = ListCardComponent(item: item, hints: PresentationHints())
        let masonry = MasonryCardComponent(item: item, hints: PresentationHints())

        #expect(simple.item.cardTitle == "Test Item 1")
        #expect(list.item.cardTitle == "Test Item 1")
        #expect(masonry.item.cardTitle == "Test Item 1")
        expectHostable(simple, "SimpleCard a11y")
        expectHostable(list, "ListCard a11y")
        expectHostable(masonry, "MasonryCard a11y")
    }
}
