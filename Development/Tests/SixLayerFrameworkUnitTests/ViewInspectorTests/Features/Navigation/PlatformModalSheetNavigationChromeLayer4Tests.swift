import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Behavioral tests for ``platformModalSheetNavigationChrome_L4`` (issue #223).
@Suite(.serialized)
open class PlatformModalSheetNavigationChromeLayer4Tests: BaseTestClass {

    // MARK: - API surface

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_APISignature() {
        let _ = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "Filters",
            titleDisplayMode: .large,
            confirmationTitle: "Apply",
            onConfirmation: {},
            content: { Text("Body") }
        )
        #expect(Bool(true), "Simple overload should compile and build")
    }

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_WithLeading_APISignature() {
        let _ = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "Sort",
            titleDisplayMode: .automatic,
            confirmationTitle: "Done",
            onConfirmation: {},
            leadingToolbar: { Button("Reset", action: {}) },
            content: { Text("List") }
        )
        #expect(Bool(true), "Leading-toolbar overload should compile and build")
    }

    // MARK: - Toolbar presence (stub must fail; full implementation must pass)

    @Test func testPlatformModalSheetNavigationChrome_L4_ExposesConfirmationButton() {
        let chrome = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "Filters",
            titleDisplayMode: .inline,
            confirmationTitle: "Apply",
            onConfirmation: {},
            content: { Text("Body") }
        )
        .enableGlobalAutomaticCompliance()

        #if os(iOS) && canImport(UIKit)
        let hosted = hostRootPlatformView(chrome)
        #expect(
            hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Apply"),
            "Hosted sheet chrome should expose confirmation control with expected title"
        )
        #elseif os(macOS) && canImport(ViewInspector)
        let found = withInspectedView(AnyView(chrome)) { inspected in
            Self.inspectionHasButtonLabel(inspected, label: "Apply")
        }
        #expect(found == true, "macOS inspection should find confirmation toolbar button")
        #else
        #expect(Bool(true), "Platform-specific toolbar check skipped on this target")
        #endif
    }

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_WithLeading_ExposesBothToolbarButtons() {
        let chrome = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "Sort",
            titleDisplayMode: .inline,
            confirmationTitle: "Done",
            onConfirmation: {},
            leadingToolbar: { Button("Reset", action: {}) },
            content: { Text("Rows") }
        )
        .enableGlobalAutomaticCompliance()

        #if os(iOS) && canImport(UIKit)
        let hosted = hostRootPlatformView(chrome)
        #expect(hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Reset"))
        #expect(hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Done"))
        #elseif os(macOS) && canImport(ViewInspector)
        let found = withInspectedView(AnyView(chrome)) { inspected in
            Self.inspectionHasButtonLabel(inspected, label: "Reset")
                && Self.inspectionHasButtonLabel(inspected, label: "Done")
        }
        #expect(found == true, "macOS inspection should find leading and confirmation buttons")
        #else
        #expect(Bool(true), "Platform-specific toolbar check skipped on this target")
        #endif
    }

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_OutermostComplianceHook() {
        let chrome = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "T",
            confirmationTitle: "Go",
            onConfirmation: {},
            content: { Text("C") }
        )
        .enableGlobalAutomaticCompliance()

        var diagnostic: String? = nil
        let ok = testComponentComplianceSinglePlatform(
            chrome,
            expectedPattern: "*platformModalSheetNavigationChrome_L4*",
            platform: SixLayerPlatform.current,
            componentName: "platformModalSheetNavigationChrome_L4",
            diagnostic: &diagnostic
        )
        #expect(ok, "Chrome should register outer compliance hook: \(diagnostic ?? "")")
    }

    // MARK: - Callback

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_ConfirmationCallbackInvoked() throws {
        // NavigationStack roots hang or resist full inspection on iOS in this suite; macOS uses a plain stack.
        #if os(macOS) && canImport(ViewInspector)
        var invoked = false
        let chrome = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "T",
            confirmationTitle: "Save",
            onConfirmation: { invoked = true },
            content: { Text("C") }
        )
        try withInspectedViewThrowing(AnyView(chrome)) { inspected in
            let buttons = inspected.findAll(ViewType.Button.self)
            for button in buttons {
                if Self.buttonMatchesLabel(button, label: "Save") {
                    try button.tap()
                    #expect(invoked, "Confirmation tap should invoke onConfirmation")
                    return
                }
            }
            Issue.record("Could not find Save button in chrome hierarchy")
        }
        #else
        #expect(Bool(true), "Confirmation tap inspection runs on macOS ViewInspector only")
        #endif
    }

    // MARK: - Helpers

    #if canImport(ViewInspector)
    @MainActor
    private static func inspectionHasButtonLabel(
        _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>,
        label: String
    ) -> Bool {
        for button in inspected.findAll(ViewType.Button.self) where buttonMatchesLabel(button, label: label) {
            return true
        }
        return false
    }

    @MainActor
    private static func buttonMatchesLabel(
        _ button: ViewInspector.InspectableView<ViewInspector.ViewType.Button>,
        label: String
    ) -> Bool {
        guard let labelView = try? button.labelView(),
              let text = try? labelView.find(ViewType.Text.self).string()
        else { return false }
        return text == label
    }
    #endif
}
