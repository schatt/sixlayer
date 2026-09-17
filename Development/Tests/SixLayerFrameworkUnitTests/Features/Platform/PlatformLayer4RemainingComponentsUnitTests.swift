import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane smoke for remaining Layer4 component zeros (#467):
 * Buttons, ResponsiveCards, Lists, Styling, ModalSheet chrome, RowActions,
 * Popover/Sheet, Modals alias. Behavioral E2E stays XCUI/VI where needed.
 */

@Suite("Platform Layer4 Remaining Components Unit", HostedViewTestIsolationTrait())
struct PlatformLayer4RemainingComponentsUnitTests {

    // MARK: - Buttons

    @Test @MainActor
    func buttonStylesUseNamedCompliance() {
        #if os(watchOS)
        return
        #else
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let view = Button("Go") {}
            .platformPrimaryButtonStyle()
        let hosted = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
        }
        #expect(hosted != nil)
        #expect(
            isolated.getDebugLog().contains("platformPrimaryButtonStyle"),
            "primary button style must use named compliance"
        )
        #endif
    }

    @Test @MainActor
    func iconButtonHostsWithAccessibilityLabel() {
        #if os(watchOS)
        return
        #else
        let view = EmptyView().platformIconButton(
            systemImage: "trash",
            accessibilityLabel: "Delete item",
            accessibilityHint: "Removes the item",
            action: {}
        )
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Responsive cards

    @Test @MainActor
    func cardGridAndPaddingHost() {
        #if os(watchOS)
        return
        #else
        let grid = EmptyView()
            .platformCardGrid(columns: 2, spacing: 8) { Text("A"); Text("B") }
            .platformCardPadding()
        #expect(TestSetupUtilities.hostRootPlatformView(grid, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Lists

    @Test @MainActor
    func listEmptyStateAndRowHost() {
        #if os(watchOS)
        return
        #else
        let empty = EmptyView().platformListEmptyState(
            systemImage: "tray",
            title: "None",
            message: "No items"
        )
        let row = EmptyView().platformListRow(title: "Item") { Text(">") }
        #expect(TestSetupUtilities.hostRootPlatformView(empty, forceLayout: true) != nil)
        #expect(TestSetupUtilities.hostRootPlatformView(row, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Styling

    @Test @MainActor
    func platformAnimationModifierHosts() {
        #if os(watchOS)
        return
        #else
        let view = Text("Anim")
            .platformAnimation()
            .platformCornerRadius()
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Modal sheet navigation chrome

    @Test @MainActor
    func modalSheetNavigationChromeHosts() {
        #if os(watchOS)
        return
        #else
        let view = Text("Body")
            .platformModalSheetNavigationChrome_L4(
                title: "Sheet",
                onConfirmation: {}
            ) {
                Text("Content")
            }
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Row actions

    @Test @MainActor
    func rowActionButtonsConstruct() {
        #if os(watchOS)
        return
        #else
        var tapped = false
        let button = PlatformRowActionButton(title: "Edit") { tapped = true }
        let destructive = PlatformDestructiveRowActionButton(title: "Delete") {}
        _ = button
        _ = destructive
        #expect(!tapped)
        #endif
    }

    @Test @MainActor
    func rowActionsModifierHosts() {
        #if os(watchOS)
        return
        #else
        let view = Text("Row")
            .platformRowActions_L4 {
                Button("Edit") {}
            }
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Popover / sheet

    @Test @MainActor
    func popoverAndSheetModifiersHost() {
        #if os(watchOS)
        return
        #else
        let popover = Text("Anchor")
            .platformPopover_L4(isPresented: .constant(false)) { Text("Pop") }
        let sheet = Text("Root")
            .platformSheet_L4(isPresented: .constant(false)) { Text("Sheet") }
        #expect(TestSetupUtilities.hostRootPlatformView(popover, forceLayout: true) != nil)
        #expect(TestSetupUtilities.hostRootPlatformView(sheet, forceLayout: true) != nil)
        #endif
    }

    // MARK: - Modals alias

    @Test @MainActor
    func platformSheetAliasHosts() {
        #if os(watchOS)
        return
        #else
        let view = Text("Root")
            .platformSheet(isPresented: .constant(false)) { Text("Legacy sheet") }
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        #endif
    }
}
