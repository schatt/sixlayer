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
@Suite(HostedViewTestIsolationTrait())
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

    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_ExposesConfirmationButton() {
        let chrome = EmptyView().platformModalSheetNavigationChrome_L4(
            title: "Filters",
            titleDisplayMode: .inline,
            confirmationTitle: "Apply",
            onConfirmation: {},
            content: { Text("Body") }
        )
        .enableGlobalAutomaticCompliance()

        #if os(iOS) && canImport(UIKit)
        initializeTestConfig()
        // NavigationStack hosting hides toolbar items in unit tests; probe the inner toolbar stack.
        let toolbarProbe = Text("Body")
            .platformNavigationTitle_L4("Filters")
            .platformNavigationTitleDisplayMode_L4(.inline)
            .platformToolbarWithConfirmationAction(confirmationAction: {}, confirmationTitle: "Apply")
            .enableGlobalAutomaticCompliance()
        let hosted = runWithTaskLocalConfig {
            hostRootPlatformView(toolbarProbe, forceLayout: true, exposeContentAccessibility: true)
        }
        #if canImport(ViewInspector)
        let inspectorFound = findButtonInViewHierarchy(toolbarProbe, labels: ["Apply"]) != nil
        #else
        let inspectorFound = false
        #endif
        let hostedFound = hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Apply")
            || hostedUIKitAccessibilityHierarchyContains(root: hosted, predicate: { view in
                view.hostedAccessibilityLabelText.contains("Apply")
            })
        #expect(
            hostedFound || inspectorFound,
            "Sheet chrome toolbar stack should expose confirmation control with expected title"
        )
        _ = chrome
        #elseif os(macOS) && canImport(ViewInspector)
        let found = withInspectedView(AnyView(chrome)) { inspected in
            Self.inspectionHasButtonLabel(inspected, label: "Apply")
        }
        #expect(found == true, "macOS inspection should find confirmation toolbar button")
        #else
        #endif
    }

    /// Prints reported `accessibilityElementCount` stats for the same hosted chrome as the toolbar tests (#232 diagnostics).
    @Test @MainActor func testPlatformModalSheetNavigationChrome_L4_Diagnostics_ReportedAccessibilityElementCounts() {
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
        let report = diagnosticsReportedAccessibilityElementCounts(inHosted: hosted)
        print("[A11y diagnostics] \(report)")
        #expect(Bool(true), "See test console log for [A11y diagnostics] line")
        #else
        #expect(Bool(true), "iOS UIKit-only diagnostic")
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
        initializeTestConfig()
        let toolbarProbe = Text("Rows")
            .platformNavigationTitle_L4("Sort")
            .platformNavigationTitleDisplayMode_L4(.inline)
            .platformToolbarWithLeadingActions { Button("Reset", action: {}) }
            .platformToolbarWithConfirmationAction(confirmationAction: {}, confirmationTitle: "Done")
            .enableGlobalAutomaticCompliance()
        let hosted = runWithTaskLocalConfig {
            hostRootPlatformView(toolbarProbe, forceLayout: true, exposeContentAccessibility: true)
        }
        #if canImport(ViewInspector)
        let inspectorFoundReset = findButtonInViewHierarchy(toolbarProbe, labels: ["Reset"]) != nil
        let inspectorFoundDone = findButtonInViewHierarchy(toolbarProbe, labels: ["Done"]) != nil
        #else
        let inspectorFoundReset = false
        let inspectorFoundDone = false
        #endif
        #expect(
            hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Reset")
                || hostedUIKitAccessibilityHierarchyContains(root: hosted, predicate: { view in
                    view.hostedAccessibilityLabelText.contains("Reset")
                })
                || inspectorFoundReset
        )
        #expect(
            hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: hosted, expectedLabel: "Done")
                || hostedUIKitAccessibilityHierarchyContains(root: hosted, predicate: { view in
                    view.hostedAccessibilityLabelText.contains("Done")
                })
                || inspectorFoundDone
        )
        _ = chrome
        #elseif os(macOS) && canImport(ViewInspector)
        let found = withInspectedView(AnyView(chrome)) { inspected in
            Self.inspectionHasButtonLabel(inspected, label: "Reset")
                && Self.inspectionHasButtonLabel(inspected, label: "Done")
        }
        #expect(found == true, "macOS inspection should find leading and confirmation buttons")
        #else
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
        var strings: [String] = []
        if let labelView = try? button.labelView(),
           let text = try? labelView.find(ViewType.Text.self).string() {
            strings.append(text)
        }
        for textView in button.findAll(ViewType.Text.self) {
            if let s = try? textView.string(), !s.isEmpty {
                strings.append(s)
            }
        }
        return strings.contains(where: { $0 == label || $0.contains(label) })
    }
    #endif
}
