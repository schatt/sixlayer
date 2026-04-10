import SwiftUI
import Testing
@testable import SixLayerFramework

/// Issue #221: optional `accessibilityIdentifier` on platform form/detail toolbars (hosted tree; avoids NavigationStack inspect hangs).
@Suite("Platform form and detail toolbar accessibility identifiers")
struct PlatformFormToolbarAccessibilityTests {

    private let saveID = "SixLayer.tests.platformFormToolbar.save.221"
    private let cancelID = "SixLayer.tests.platformFormToolbar.cancel.221"
    private let selectID = "SixLayer.tests.platformFormToolbar.select.221"
    private let detailSaveID = "SixLayer.tests.platformDetailToolbar.save.221"
    private let detailCancelID = "SixLayer.tests.platformDetailToolbar.cancel.221"

    @MainActor
    private func hostedToolbarIdentifiers<V: View>(for view: V) -> [String] {
        guard let root = TestSetupUtilities.hostRootPlatformView(view) else { return [] }
        return findAllAccessibilityIdentifiersFromPlatformView(root)
    }

    @Test @MainActor
    func platformFormToolbar_appliesOptionalAccessibilityIdentifiers() {
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

        let ids = Set(hostedToolbarIdentifiers(for: view))

        #expect(ids.contains(saveID), "Save button should expose the provided accessibility identifier")
        #expect(ids.contains(cancelID), "Cancel button should expose the provided accessibility identifier")

        #if os(macOS)
        #expect(ids.contains(selectID), "macOS Select control should expose selectButtonAccessibilityIdentifier when provided")
        #else
        #expect(!ids.contains(selectID), "selectButtonAccessibilityIdentifier must not create an extra id on platforms without Select")
        #endif
    }

    @Test @MainActor
    func platformFormToolbar_nilIdentifiers_doNotRequireProvidedStrings() {
        let sentinel = "SixLayer.tests.platformFormToolbar.shouldNotAppear"
        let view = Text("ToolbarHostNil")
            .platformFormToolbar(
                onCancel: {},
                onSave: {},
                saveButtonAccessibilityIdentifier: nil,
                cancelButtonAccessibilityIdentifier: nil,
                selectButtonAccessibilityIdentifier: nil
            )

        let ids = hostedToolbarIdentifiers(for: view)
        #expect(!ids.contains(sentinel))
        #expect(!ids.contains(saveID))
    }

    @Test @MainActor
    func platformDetailToolbar_appliesOptionalAccessibilityIdentifiers() {
        let view = Text("DetailToolbarHost")
            .platformDetailToolbar(
                onCancel: {},
                onSave: {},
                saveButtonTitle: "Done",
                saveButtonAccessibilityIdentifier: detailSaveID,
                cancelButtonAccessibilityIdentifier: detailCancelID
            )

        let ids = Set(hostedToolbarIdentifiers(for: view))
        #expect(ids.contains(detailSaveID))
        #expect(ids.contains(detailCancelID))
    }
}
