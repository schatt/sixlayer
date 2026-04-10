import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// Issue #221: optional `accessibilityIdentifier` on platform form/detail toolbars.
/// Asserts via ViewInspector `.toolbar()` extraction (platform hosted-tree traversal does not reliably
/// surface SwiftUI toolbar control identifiers in unit-test hosting).
@Suite("Platform form and detail toolbar accessibility identifiers")
struct PlatformFormToolbarAccessibilityTests {

    private let saveID = "SixLayer.tests.platformFormToolbar.save.221"
    private let cancelID = "SixLayer.tests.platformFormToolbar.cancel.221"
    private let selectID = "SixLayer.tests.platformFormToolbar.select.221"
    private let detailSaveID = "SixLayer.tests.platformDetailToolbar.save.221"
    private let detailCancelID = "SixLayer.tests.platformDetailToolbar.cancel.221"

    @Test @MainActor
    func platformFormToolbar_appliesOptionalAccessibilityIdentifiers() throws {
        #if canImport(ViewInspector)
        let view = Text("ToolbarHost")
            .platformFormToolbar(
                onCancel: {},
                onSave: {},
                saveButtonTitle: "Save",
                cancelButtonTitle: "Cancel",
                saveButtonAccessibilityIdentifier: saveID,
                cancelButtonAccessibilityIdentifier: cancelID,
                selectButtonAccessibilityIdentifier: selectID
            )

        let toolbar = try AnyView(view).inspect().toolbar()

        let cancelAID = try toolbar.item(0).button().accessibilityIdentifier()
        #expect(cancelAID == cancelID)

        #if os(iOS)
        let saveAID = try toolbar.item(1).button().accessibilityIdentifier()
        #expect(saveAID == saveID)
        #elseif os(macOS)
        let buttons = try toolbar.item(1).findAll(ViewType.Button.self)
        #expect(buttons.count == 2)
        let selectAID = try buttons[0].accessibilityIdentifier()
        let saveAID = try buttons[1].accessibilityIdentifier()
        #expect(selectAID == selectID)
        #expect(saveAID == saveID)
        #else
        Issue.record("Toolbar accessibility tests require iOS or macOS + ViewInspector")
        #endif
        #else
        Issue.record("ViewInspector required for Issue #221 toolbar identifier tests")
        #endif
    }

    @Test @MainActor
    func platformFormToolbar_nilIdentifiers_doNotRequireProvidedStrings() throws {
        #if canImport(ViewInspector)
        let view = Text("ToolbarHostNil")
            .platformFormToolbar(
                onCancel: {},
                onSave: {},
                saveButtonAccessibilityIdentifier: nil,
                cancelButtonAccessibilityIdentifier: nil,
                selectButtonAccessibilityIdentifier: nil
            )

        let toolbar = try AnyView(view).inspect().toolbar()
        let cancelAID = try toolbar.item(0).button().accessibilityIdentifier()
        #expect(cancelAID.isEmpty)

        #if os(iOS)
        let saveAID = try toolbar.item(1).button().accessibilityIdentifier()
        #expect(saveAID.isEmpty)
        #elseif os(macOS)
        let buttons = try toolbar.item(1).findAll(ViewType.Button.self)
        #expect(buttons.count == 2)
        let selectAID = try buttons[0].accessibilityIdentifier()
        let saveAID = try buttons[1].accessibilityIdentifier()
        #expect(selectAID.isEmpty)
        #expect(saveAID.isEmpty)
        #endif
        #else
        Issue.record("ViewInspector required for Issue #221 toolbar identifier tests")
        #endif
    }

    @Test @MainActor
    func platformDetailToolbar_appliesOptionalAccessibilityIdentifiers() throws {
        #if canImport(ViewInspector)
        let view = Text("DetailToolbarHost")
            .platformDetailToolbar(
                onCancel: {},
                onSave: {},
                saveButtonTitle: "Done",
                saveButtonAccessibilityIdentifier: detailSaveID,
                cancelButtonAccessibilityIdentifier: detailCancelID
            )

        let toolbar = try AnyView(view).inspect().toolbar()
        let cancelAID = try toolbar.item(0).button().accessibilityIdentifier()
        let saveAID = try toolbar.item(1).button().accessibilityIdentifier()
        #expect(cancelAID == detailCancelID)
        #expect(saveAID == detailSaveID)
        #else
        Issue.record("ViewInspector required for Issue #221 toolbar identifier tests")
        #endif
    }
}
