import Testing
import SwiftUI
@testable import SixLayerFramework

/// Focused coverage for core container/navigation helpers (Issue #170).
/// Keep this file intentionally small and grouped (<=10 tests).
@Suite("Platform Basic Containers Extensions")
open class PlatformBasicContainersExtensionsTests: BaseTestClass {

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

    @Test @MainActor func testPlatformHStackGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersHStack", context: "platformHStack") {
            platformHStack {
                Text("One")
                Text("Two")
            }
        }
    }

    @Test @MainActor func testPlatformZStackGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersZStack", context: "platformZStack") {
            platformZStack {
                Color.clear
                Text("Overlay")
            }
        }
    }

    @Test @MainActor func testPlatformLazyVStackContainerGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersLazyVStack", context: "platformLazyVStackContainer") {
            EmptyView().platformLazyVStackContainer {
                ForEach(0..<3, id: \.self) { idx in
                    Text("Row \(idx)")
                }
            }
        }
    }

    @Test @MainActor func testPlatformLazyHStackContainerGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersLazyHStack", context: "platformLazyHStackContainer") {
            EmptyView().platformLazyHStackContainer {
                ForEach(0..<3, id: \.self) { idx in
                    Text("Chip \(idx)")
                }
            }
        }
    }

    @Test @MainActor func testPlatformScrollViewContainerGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersScrollView", context: "platformScrollViewContainer") {
            EmptyView().platformScrollViewContainer {
                Text("Scrollable content")
            }
        }
    }

    @Test @MainActor func testPlatformListContainerGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersList", context: "platformListContainer") {
            EmptyView().platformListContainer {
                Text("List row")
            }
        }
    }

    @Test @MainActor func testPlatformFormGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersForm", context: "platformForm") {
            platformForm {
                Text("Field label")
            }
        }
    }

    @Test @MainActor func testPlatformSidebarPullIndicatorGeneratesAccessibilityIdentifiers() async {
        assertLayoutChromeDualPath(anchorName: "PlatformBasicContainersSidebarPullIndicator", context: "platformSidebarPullIndicator") {
            platformSidebarPullIndicator(isVisible: true)
        }
    }
}
