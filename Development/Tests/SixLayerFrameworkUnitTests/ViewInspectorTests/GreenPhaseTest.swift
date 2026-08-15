import Testing
import SwiftUI
@testable import SixLayerFramework

/// Basic collection L1 + data-structure smokes (#382; formerly Bool(true) theater).
@Suite("Basic Collection And Data Smokes", HostedViewTestIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class GreenPhaseTest: BaseTestClass {

    @Test @MainActor func testBasicViewCreation() {
        initializeTestConfig()
        let testItems = [
            TestPatterns.TestItem(id: "1", title: "Test Item 1"),
            TestPatterns.TestItem(id: "2", title: "Test Item 2")
        ]

        let view = platformPresentItemCollection_L1(
            items: testItems,
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .modal,
                customPreferences: [:]
            )
        )

        #expect(
            PlatformContainerStructureAssertions.isHostable(view),
            "platformPresentItemCollection_L1 view should be hostable (#382)"
        )
    }

    @Test func testBasicDataStructures() {
        let item = TestPatterns.TestItem(id: "test", title: "Test")
        let id = item.id
        let title = item.title

        #expect(String(describing: id) == "test" || (id as? String) == "test", "ID should be accessible")
        #expect(title == "Test", "Title should be accessible")
    }
}
