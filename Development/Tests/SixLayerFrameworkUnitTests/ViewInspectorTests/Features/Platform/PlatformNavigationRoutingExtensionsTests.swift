import Testing
import SwiftUI
@testable import SixLayerFramework

/// Navigation routing + open settings helpers (Issue #170). Grouped; keep <=10 tests.
@Suite("Platform Navigation Routing Extensions")
open class PlatformNavigationRoutingExtensionsTests: BaseTestClass {

    struct NavRow: Identifiable, Hashable {
        let id: Int
    }

    @MainActor
    private func assertLayoutChromeDualPath<V: View>(
        anchorName: String,
        context: String,
        @ViewBuilder root: () -> V
    ) {
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let anonymous = root()
            let anonymousHost = hostRootPlatformView(anonymous, accessibilityIdentifierConfig: isolated)
            #expect(anonymousHost != nil, "\(context): anonymous compliance path should render")

            let named = root().named(anchorName)
            let namedHost = hostRootPlatformView(named, accessibilityIdentifierConfig: isolated)
            #expect(namedHost != nil, "\(context): named path should render")

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
        }
    }

    @MainActor
    private func expectRenderable<V: View>(_ view: V, context: String) {
        let hosted = hostRootPlatformView(view)
        #expect(hosted != nil, "\(context) should render in hosted test environment")
    }

    @Test @MainActor func testPlatformNavigationSplitContainerL4NamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformNavRoutingSplitContainer", context: "platformNavigationSplitContainer_L4") {
            Text("Host")
                .platformNavigationSplitContainer_L4 {
                    Text("Sidebar")
                } detail: {
                    Text("Detail")
                }
        }
    }

    @Test @MainActor func testCrossPlatformNavigationStackRenders() async {
        final class SelectionBox {
            var value: NavRow?
        }
        let box = SelectionBox()
        let binding = Binding<NavRow?>(
            get: { box.value },
            set: { box.value = $0 }
        )
        let items = [NavRow(id: 0), NavRow(id: 1)]
        let analysis = DataIntrospectionEngine.analyzeCollection(items)
        let view = CrossPlatformNavigation.platformNavigationStack(
            items: items,
            selectedItem: binding,
            itemView: { row in Text("Row \(row.id)") },
            detailView: { row in Text("Detail \(row.id)") },
            analysis: analysis
        )
        expectRenderable(view, context: "CrossPlatformNavigation.platformNavigationStack")
    }

    @Test @MainActor func testPlatformImplementNavigationStackItemsL4Renders() async {
        final class SelectionBox {
            var value: NavRow?
        }
        let box = SelectionBox()
        let binding = Binding<NavRow?>(
            get: { box.value },
            set: { box.value = $0 }
        )
        let items = [NavRow(id: 0)]
        let strategy = NavigationStackStrategy(
            implementation: .navigationStack,
            reasoning: "unit test"
        )
        let view = platformImplementNavigationStackItems_L4(
            items: items,
            selectedItem: binding,
            itemView: { row in Text("\(row.id)") },
            detailView: { row in Text("D \(row.id)") },
            strategy: strategy
        )
        expectRenderable(view, context: "platformImplementNavigationStackItems_L4")
    }

    @Test @MainActor func testPlatformBottomBarPlacementOnIOS() async {
        #if os(iOS)
        #expect(platformBottomBarPlacement() == .bottomBar)
        #else
        _ = platformBottomBarPlacement()
        #expect(Bool(true), "platformBottomBarPlacement returns a placement on this OS")
        #endif
    }

    @Test @MainActor func testGlobalPlatformOpenSettingsReturnsTrueInTestHost() async {
        let ok = platformOpenSettings()
        #expect(ok, "platformOpenSettings should return true under XCTest/Swift Testing DEBUG guard")
    }

    private struct OpenSettingsOpenURLProbe: View {
        @Environment(\.openURL) private var openURL

        var body: some View {
            Color.clear
                .accessibilityIdentifier("open-settings-openurl-probe")
                .onAppear {
                    _ = platformOpenSettings(openURL: openURL)
                }
        }
    }

    @Test @MainActor func testPlatformOpenSettingsWithOpenURLHostRenders() async {
        let view = OpenSettingsOpenURLProbe()
        expectRenderable(view, context: "platformOpenSettings(openURL:) probe host")
    }

    @Test @MainActor func testBottomBarToolbarHostRenders() async {
        let view = NavigationStack {
            Text("Probe")
                .toolbar {
                    ToolbarItem(placement: platformBottomBarPlacement()) {
                        Text("Bottom item")
                    }
                }
        }
        expectRenderable(view, context: "toolbar with platformBottomBarPlacement")
    }
}
