import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector

/// Collects non-empty `accessibilityIdentifier` values under a toolbar item (modifier may sit above `Button` in the hierarchy).
@MainActor
private func accessibilityIdentifiersUnderToolbarItem(_ item: InspectableView<ViewType.Toolbar.Item>) -> [String] {
    item.findAll(ViewType.ClassifiedView.self, where: { _ in true }).compactMap { node in
        guard let id = try? node.accessibilityIdentifier(), !id.isEmpty else { return nil }
        return id
    }
}
#endif

/// Issue #221: optional `accessibilityIdentifier` on platform form/detail toolbars.
///
/// **Positive contract** (provided IDs appear in the runtime tree) is asserted in
/// `PlatformToolbarAccessibilityUITests` — ViewInspector toolbar extraction does not reliably surface
/// identifiers on macOS for these toolbars.
@Suite("Platform form and detail toolbar accessibility identifiers")
struct PlatformFormToolbarAccessibilityTests {

    private let saveID = "SixLayer.tests.platformFormToolbar.save.221"
    private let cancelID = "SixLayer.tests.platformFormToolbar.cancel.221"
    private let selectID = "SixLayer.tests.platformFormToolbar.select.221"

    @Test @MainActor
    func platformFormToolbar_nilIdentifiers_doNotRequireProvidedStrings() throws {
        // ViewInspector toolbar enumeration is unreliable on watchOS in this SDK matrix (#271).
        #if canImport(ViewInspector) && !os(watchOS)
        let view = Text("ToolbarHostNil")
            .platformFormToolbar(
                onCancel: {},
                onSave: {},
                saveButtonAccessibilityIdentifier: nil,
                cancelButtonAccessibilityIdentifier: nil,
                selectButtonAccessibilityIdentifier: nil
            )

        let toolbar = try view.inspect().toolbar()
        let cancelIds = accessibilityIdentifiersUnderToolbarItem(try toolbar.item(0))
        let primaryIds = accessibilityIdentifiersUnderToolbarItem(try toolbar.item(1))
        #expect(!cancelIds.contains(cancelID))
        #expect(!primaryIds.contains(saveID))
        #expect(!primaryIds.contains(selectID))
        #else
        // tvOS/visionOS: ViewInspector not linked; watchOS: toolbar item extraction unreliable (#271).
        // Positive contract: PlatformToolbarAccessibilityUITests on iOS/macOS.
        #expect(Bool(true), "Skipped: toolbar nil-ID check needs ViewInspector on iOS/macOS only (Issue #221 / #271)")
        #endif
    }
}
