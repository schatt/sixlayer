import Testing
import SwiftUI
@testable import SixLayerFramework

/// Focused list/navigation helper coverage for Issue #170.
/// Keep grouped and compact (<=10 tests per file).
@Suite("Platform List Navigation Extensions")
open class PlatformListNavigationExtensionsTests: BaseTestClass {
    struct TestRow: Identifiable, Hashable {
        let id: Int
        let title: String
    }

    @MainActor
    private func expectRenderable<V: View>(_ view: V, context: String) {
        let hosted = hostRootPlatformView(view)
        #expect(hosted != nil, "\(context) should render in hosted test environment")
    }

    @MainActor
    private func expectAccessibilityCompliance<V: View>(_ view: V, componentName: String) {
        initializeTestConfig()
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: .iOS,
            componentName: componentName
        )
        #expect(hasAccessibilityID, "\(componentName) should generate accessibility identifiers on iOS")
    }

    @Test @MainActor func testPlatformListToolbarRenders() async {
        let view = List(0..<2, id: \.self) { idx in
            Text("Row \(idx)")
        }
        .platformListToolbar(onAdd: {}, addButtonTitle: "Add", addButtonIcon: "plus")
        expectRenderable(view, context: "platformListToolbar")
    }

    @Test @MainActor func testPlatformListStyleRenders() async {
        let view = List(0..<2, id: \.self) { idx in
            Text("Styled \(idx)")
        }
        .platformListStyle()
        expectRenderable(view, context: "platformListStyle")
    }

    @Test @MainActor func testPlatformListWithSelectionSingleRenders() async {
        @State var selection: Int? = nil
        let view = EmptyView().platformListWithSelection(selection: $selection) {
            Text("Single A").tag(0)
            Text("Single B").tag(1)
        }
        expectRenderable(view, context: "platformListWithSelection single")
    }

    @Test @MainActor func testPlatformListWithSelectionMultiRenders() async {
        @State var selection: Set<Int> = []
        let view = EmptyView().platformListWithSelection(selection: $selection) {
            Text("Multi A").tag(0)
            Text("Multi B").tag(1)
        }
        expectRenderable(view, context: "platformListWithSelection multi")
    }

    @Test @MainActor func testPlatformBackupListContainerRenders() async {
        let view = EmptyView().platformBackupListContainer {
            Text("Backup content")
        }
        expectRenderable(view, context: "platformBackupListContainer")
    }

    @Test @MainActor func testPlatformListDetailContainerRenders() async {
        let view = EmptyView().platformListDetailContainer {
            Text("List pane")
        } detail: {
            Text("Detail pane")
        }
        expectRenderable(view, context: "platformListDetailContainer")
    }

    @Test @MainActor func testPlatformSelectableListRowRenders() async {
        let view = EmptyView().platformSelectableListRow(isSelected: false, onSelect: {}) {
            Text("Selectable row")
        }
        expectAccessibilityCompliance(view, componentName: "platformSelectableListRow")
    }

    @Test @MainActor func testPlatformListDetailNavigationRenders() async {
        @State var selected: TestRow? = nil
        let items = [TestRow(id: 1, title: "One"), TestRow(id: 2, title: "Two")]
        let view = Text("Host").platformListDetailNavigation(
            items: items,
            selectedItem: $selected,
            itemView: { row in Text(row.title) },
            detailView: { row in Text("Detail \(row.title)") }
        )
        expectRenderable(view, context: "platformListDetailNavigation")
    }

    @Test @MainActor func testPlatformNavigationSheetButtonRenders() async {
        let view = Text("Host").platformNavigationSheetButton(action: {})
        expectAccessibilityCompliance(view, componentName: "platformNavigationSheetButton")
    }

    @Test @MainActor func testPlatformNavigationSheetButtonPhoneOrDetailOnlyRendersOnMacHost() async {
        let view = Text("Host").platformNavigationSheetButton(
            action: {},
            visibility: .phoneOrDetailOnly,
            columnVisibility: .constant(.all),
            accessibilityIdentifier: "Test.ShowNavigationMenuButton"
        )
        expectAccessibilityCompliance(view, componentName: "platformNavigationSheetButton")
    }

    @Test @MainActor func testPlatformAppNavigationSheetToolbarLeadingRenders() async {
        @State var showingSheet = false
        let view = Text("Host")
            .platformAppNavigationSheetToolbarLeading(
                showingNavigationSheet: $showingSheet,
                columnVisibility: .constant(.detailOnly),
                accessibilityIdentifier: "Test.ShowNavigationMenuButton"
            )
        expectRenderable(view, context: "platformAppNavigationSheetToolbarLeading")
    }
}
