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

        let toolbar = try view.inspect().toolbar()

        // `.accessibilityIdentifier` is applied outside `Button`; read from toolbar item root, not `.button()`.
        let cancelAID = try toolbar.item(0).accessibilityIdentifier()
        #expect(cancelAID == cancelID)

        #if os(iOS)
        let saveAID = try toolbar.item(1).accessibilityIdentifier()
        #expect(saveAID == saveID)
        #elseif os(macOS)
        let idsInPrimary = try toolbar.item(1).findAll(ViewType.ClassifiedView.self, where: { _ in true }).compactMap { node -> String? in
            guard let id = try? node.accessibilityIdentifier(), !id.isEmpty else { return nil }
            return id
        }
        #expect(idsInPrimary.contains(selectID))
        #expect(idsInPrimary.contains(saveID))
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

        let toolbar = try view.inspect().toolbar()
        let cancelAID = try toolbar.item(0).accessibilityIdentifier()
        #expect(cancelAID.isEmpty)

        #if os(iOS)
        let saveAID = try toolbar.item(1).accessibilityIdentifier()
        #expect(saveAID.isEmpty)
        #elseif os(macOS)
        let idsInPrimary = try toolbar.item(1).findAll(ViewType.ClassifiedView.self, where: { _ in true }).compactMap { node -> String? in
            guard let id = try? node.accessibilityIdentifier(), !id.isEmpty else { return nil }
            return id
        }
        #expect(idsInPrimary.isEmpty)
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

        let toolbar = try view.inspect().toolbar()
        let cancelAID = try toolbar.item(0).accessibilityIdentifier()
        let saveAID = try toolbar.item(1).accessibilityIdentifier()
        #expect(cancelAID == detailCancelID)
        #expect(saveAID == detailSaveID)
        #else
        Issue.record("ViewInspector required for Issue #221 toolbar identifier tests")
        #endif
    }
}
