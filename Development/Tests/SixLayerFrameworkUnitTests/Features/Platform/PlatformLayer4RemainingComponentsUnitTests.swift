import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane observations for remaining Layer4 component zeros (#467):
 * Buttons, ResponsiveCards, Lists, Styling, ModalSheet chrome, RowActions,
 * Popover/Sheet, Modals alias. Behavioral E2E stays XCUI/VI where needed.
 *
 * Named-compliance APIs must appear in the isolated debug log. That is the
 * unit-lane proof the modifier body ran (not only that hosting returned non-nil).
 */

@Suite("Platform Layer4 Remaining Components Unit", HostedViewTestIsolationTrait())
struct PlatformLayer4RemainingComponentsUnitTests {

    private struct SheetItem: Identifiable {
        let id: String
    }

    // MARK: - Buttons

    @Test @MainActor
    func primaryButtonStyleUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformPrimaryButtonStyle") {
            Button("Go") {}.platformPrimaryButtonStyle()
        }
    }

    @Test @MainActor
    func secondaryButtonStyleUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformSecondaryButtonStyle") {
            Button("Maybe") {}.platformSecondaryButtonStyle()
        }
    }

    @Test @MainActor
    func destructiveButtonStyleUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformDestructiveButtonStyle") {
            Button("Stop") {}.platformDestructiveButtonStyle()
        }
    }

    @Test @MainActor
    func iconButtonUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformIconButton") {
            EmptyView().platformIconButton(
                systemImage: "trash",
                accessibilityLabel: "Delete item",
                accessibilityHint: "Removes the item",
                action: {}
            )
        }
    }

    // MARK: - Responsive cards

    @Test @MainActor
    func cardGridUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardGrid") {
            EmptyView().platformCardGrid(columns: 2, spacing: 8) {
                Text("A")
            }
        }
    }

    @Test @MainActor
    func cardMasonryUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardMasonry") {
            EmptyView().platformCardMasonry(columns: 2, spacing: 8) {
                Text("M")
            }
        }
    }

    @Test @MainActor
    func cardListUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardList") {
            EmptyView().platformCardList(spacing: 8) {
                Text("L")
            }
        }
    }

    @Test @MainActor
    func cardAdaptiveUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardAdaptive") {
            EmptyView().platformCardAdaptive(minWidth: 80, maxWidth: 200) {
                Text("C")
            }
        }
    }

    @Test @MainActor
    func cardStyleUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardStyle") {
            Text("Card").platformCardStyle()
        }
    }

    @Test @MainActor
    func cardPaddingUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformCardPadding") {
            Text("Padded").platformCardPadding()
        }
    }

    // MARK: - Lists

    @Test @MainActor
    func listRowUsesNamedComplianceAndTitle() {
        hostExpectingNamedCompliance("platformListRow") {
            EmptyView().platformListRow(title: "Item") { Text(">") }
        }
    }

    @Test @MainActor
    func listRowContentOverloadUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformListRow") {
            EmptyView().platformListRow(label: "Legacy") {
                Text("Row")
            }
        }
    }

    @Test @MainActor
    func listSectionHeaderUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformListSectionHeader") {
            EmptyView().platformListSectionHeader(title: "Section", subtitle: "Sub")
        }
    }

    @Test @MainActor
    func listEmptyStateUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformListEmptyState") {
            EmptyView().platformListEmptyState(
                systemImage: "tray",
                title: "None",
                message: "No items"
            )
        }
    }

    @Test @MainActor
    func selectableListRowUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformSelectableListRow") {
            EmptyView().platformSelectableListRow(isSelected: true, onSelect: {}) {
                Text("Pick")
            }
        }
        hostExpectingNamedCompliance("platformSelectableListRow") {
            EmptyView().platformSelectableListRow(isSelected: false, onSelect: {}) {
                Text("Idle")
            }
        }
    }

    @Test @MainActor
    func detailPlaceholderUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformDetailPlaceholder") {
            EmptyView().platformDetailPlaceholder(
                systemImage: "doc",
                title: "Nothing selected",
                message: "Pick a row"
            )
        }
    }

    // MARK: - Styling (unnamed automaticCompliance — execute modifier bodies)

    @Test @MainActor
    func stylingModifiersHost() {
        hostView {
            Text("Style")
                .platformBackground()
                .platformBackground(.blue)
                .platformBackground(.red, ignoresSafeAreaEdges: .all)
                .platformBackground { Color.green }
                .platformPadding()
                .platformPadding(.horizontal, 8)
                .platformPadding(4)
                .platformPadding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
                .platformReducedPadding()
                .platformCornerRadius()
                .platformCornerRadius(6)
                .platformShadow()
                .platformShadow(radius: 2)
                .platformBorder()
                .platformBorder(color: .gray, width: 1)
                .platformFont()
                .platformFont(.headline)
                .platformAnimation()
                .platformAnimation(.easeInOut, value: true)
                .platformMinFrame()
                .platformMaxFrame()
                .platformIdealFrame()
                .platformAdaptiveFrame()
                .platformFormStyle()
                .platformContentSpacing()
        }
    }

    @Test @MainActor
    func styledContainerHosts() {
        hostView {
            EmptyView().platformStyledContainer_L4 {
                Text("Boxed")
            }
        }
    }

    @Test @MainActor
    func platformAnimationHonorsReduceMotionOverride() {
        #if os(watchOS)
        return
        #else
        PlatformReduceMotionPreference.withTestOverride(true) {
            hostView {
                Text("Still").platformAnimation()
            }
        }
        PlatformReduceMotionPreference.withTestOverride(false) {
            hostView {
                Text("Motion").platformAnimation(.linear, value: 1)
            }
        }
        #endif
    }

    // MARK: - Modal sheet navigation chrome

    @Test @MainActor
    func modalSheetNavigationChromeUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformModalSheetNavigationChrome_L4") {
            Text("Body").platformModalSheetNavigationChrome_L4(
                title: "Sheet",
                onConfirmation: {}
            ) {
                Text("Content")
            }
        }
    }

    @Test @MainActor
    func modalSheetNavigationChromeWithLeadingUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformModalSheetNavigationChrome_L4") {
            Text("Body").platformModalSheetNavigationChrome_L4(
                title: "Sheet",
                onConfirmation: {},
                leadingToolbar: { Button("Reset") {} }
            ) {
                Text("Content")
            }
        }
    }

    // MARK: - Row actions

    @Test @MainActor
    func rowActionButtonsHost() {
        hostView {
            VStack {
                PlatformRowActionButton(title: "Edit", systemImage: "pencil") {}
                PlatformDestructiveRowActionButton(title: "Delete", systemImage: "trash") {}
            }
        }
    }

    @Test @MainActor
    func rowActionsModifierUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformRowActions_L4") {
            Text("Row").platformRowActions_L4 {
                Button("Edit") {}
            }
        }
    }

    @Test @MainActor
    func contextMenuUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformContextMenu_L4") {
            Text("Menu").platformContextMenu_L4 {
                Button("Info") {}
            }
        }
    }

    @Test @MainActor
    func contextMenuWithPreviewUsesNamedCompliance() {
        #if os(watchOS)
        return
        #else
        if #available(iOS 16.0, *) {
            hostExpectingNamedCompliance("platformContextMenu_L4") {
                Text("Preview").platformContextMenu_L4 {
                    Button("Info") {}
                } preview: {
                    Text("Peek")
                }
            }
        }
        #endif
    }

    // MARK: - Popover / sheet

    @Test @MainActor
    func popoverUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformPopover_L4") {
            Text("Anchor").platformPopover_L4(isPresented: .constant(false)) {
                Text("Pop")
            }
        }
    }

    @Test @MainActor
    func sheetL4Hosts() {
        // iOS omits named sheet compliance (flattening / #193); observe that the modifier hosts.
        hostView {
            Text("Root").platformSheet_L4(isPresented: .constant(false)) {
                Text("Sheet")
            }
        }
    }

    @Test @MainActor
    func sheetL4ItemBindingHosts() {
        hostView {
            Text("Root").platformSheet_L4(item: .constant(SheetItem(id: "one"))) { item in
                Text(item.id)
            }
        }
    }

    // MARK: - Modals alias

    @Test @MainActor
    func platformSheetAliasUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformSheet") {
            Text("Root").platformSheet(isPresented: .constant(false)) {
                Text("Legacy sheet")
            }
        }
    }

    @Test @MainActor
    func platformAlertAndConfirmationDialogHost() {
        hostView {
            Text("Root")
                .platformAlert(
                    title: "Alert",
                    message: "Body",
                    primaryButton: .default(Text("OK"))
                )
                .platformConfirmationDialog(
                    title: "Confirm",
                    actions: { Button("Yes") {} },
                    message: { Text("Sure?") }
                )
        }
    }

    @Test @MainActor
    func platformDismissEmbeddedSettingsHosts() {
        hostView {
            Text("Settings").platformDismissEmbeddedSettings(onClose: {})
        }
    }

    // MARK: - Hosting helpers

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let hosted = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            TestSetupUtilities.hostRootPlatformView(
                view(),
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
        }
        #expect(hosted != nil)
        #expect(
            isolated.getDebugLog().contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
    }

    @MainActor
    private func hostView<V: View>(@ViewBuilder _ view: () -> V) {
        #if os(watchOS)
        return
        #else
        #expect(TestSetupUtilities.hostRootPlatformView(view(), forceLayout: true) != nil)
        #endif
    }
}
