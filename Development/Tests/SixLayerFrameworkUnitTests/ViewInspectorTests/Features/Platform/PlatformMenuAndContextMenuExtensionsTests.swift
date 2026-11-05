import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// `platformMenu` / `platformContextMenu` extensions (Issue #170). Grouped; keep <=10 tests.
@Suite("Platform Menu and Context Menu Extensions", HostedViewTestIsolationTrait())
open class PlatformMenuAndContextMenuExtensionsTests: BaseTestClass {

    @MainActor
    private func assertLayoutChromeDualPath<V: View>(
        anchorName: String,
        context: String,
        @ViewBuilder root: () -> V
    ) {
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let anonymous = root()
            _ = TestSetupUtilities.hostObservingPlatformRoot(
                accessibilityIdentifierConfig: isolated
            ) { anonymous }

            let named = root().named(anchorName)
            let namedHost = TestSetupUtilities.hostObservingPlatformRoot(
                accessibilityIdentifierConfig: isolated
            ) { named }

            #if os(watchOS) || os(visionOS)
            _ = (namedHost, context)
            #else
            let expectedNamedId = NamedModifier.testingGeneratedIdentifier(name: anchorName, config: isolated)
            let platformIds = findAllAccessibilityIdentifiersFromPlatformView(namedHost)
            let platformHit = platformIds.contains { $0 == expectedNamedId || $0.contains(anchorName) }
            #if canImport(ViewInspector)
            let viIds = AccessibilityTestUtilities.allAccessibilityIdentifiersFromViewInspector(named)
            let viHit = viIds.contains { $0 == expectedNamedId || $0.contains(anchorName) }
            #else
            let viHit = false
            #endif
            let debugLog = isolated.getDebugLog()
            let logHit = debugLog.contains(expectedNamedId)
            #expect(
                platformHit || viHit || logHit,
                "\(context): expected named id '\(expectedNamedId)' via platform, ViewInspector, or config debug log."
            )
            #endif
        }
    }

    @Test @MainActor func testPlatformContextMenuBasicNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContextMenuBasic", context: "platformContextMenu") {
            Text("Context host")
                .platformContextMenu {
                    Button("Alpha", action: {})
                    Button("Beta", action: {})
                }
        }
    }

    @Test @MainActor func testPlatformContextMenuWithPreviewNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContextMenuPreview", context: "platformContextMenu+preview") {
            Text("Preview host")
                .platformContextMenu(
                    menuItems: {
                        Button("Peek action", action: {})
                    },
                    preview: {
                        Text("Peek preview")
                    }
                )
        }
    }

    @Test @MainActor func testPlatformMenuTrailingContentOverloadNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformMenuTrailing", context: "platformMenu { }") {
            Text("Menu host")
                .platformMenu {
                    Button("One", action: {})
                    Button("Two", action: {})
                }
        }
    }

    @Test @MainActor func testPlatformMenuTitleOverloadNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformMenuTitle", context: "platformMenu(title:)") {
            Text("Trailing label ignored when title overload supplies menu label")
                .platformMenu(title: "Actions") {
                    Button("Do thing", action: {})
                }
        }
    }

    @Test @MainActor func testPlatformMenuLabelOverloadNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformMenuCustomLabel", context: "platformMenu(label:)") {
            Label("Row", systemImage: "line.3.horizontal")
                .platformMenu(label: Text("Overflow")) {
                    Button("A", action: {})
                    Button("B", action: {})
                }
        }
    }

    @Test @MainActor func testPlatformMenuContextMenuAuditHostRenders() async {
        TestSetupUtilities.hostExpectingPlatformRoot {
            PlatformMenuContextMenuExtensionsAuditHost(onBackToMain: nil)
        }
    }

    /// Issue #321: `platformMenu` must wrap SwiftUI `Menu` on iOS and macOS (not iOS no-op passthrough).
    @Test @MainActor func testPlatformMenuAllOverloadsExposeMenuItems() async throws {
        #if canImport(ViewInspector)
        try assertPlatformMenuExposesItems(
            context: "platformMenu { }",
            view: Text("Menu host")
                .platformMenu {
                    Button("One", action: {})
                    Button("Two", action: {})
                },
            expectedButtons: ["One", "Two"]
        )
        try assertPlatformMenuExposesItems(
            context: "platformMenu(title:)",
            view: Text("Trailing label ignored when title overload supplies menu label")
                .platformMenu(title: "Actions") {
                    Button("Do thing", action: {})
                },
            expectedButtons: ["Do thing"]
        )
        try assertPlatformMenuExposesItems(
            context: "platformMenu(label:)",
            view: Label("Row", systemImage: "line.3.horizontal")
                .platformMenu(label: Text("Overflow")) {
                    Button("A", action: {})
                    Button("B", action: {})
                },
            expectedButtons: ["A", "B"]
        )
        #endif
    }

    #if canImport(ViewInspector)
    @MainActor
    private func assertPlatformMenuExposesItems<V: View>(
        context: String,
        view: V,
        expectedButtons: [String]
    ) throws {
        let inspected = try AnyView(view).inspect()
        let menu = try inspected.find(ViewType.Menu.self)
        for title in expectedButtons {
            do {
                _ = try menu.find(button: title)
            } catch {
                Issue.record("\(context): expected tappable menu button '\(title)'")
            }
        }
    }
    #endif
}
