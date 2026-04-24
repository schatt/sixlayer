import Testing
import SwiftUI
@testable import SixLayerFramework

/// Focused coverage for core container/navigation helpers (Issue #170).
/// Keep this file intentionally small and grouped (<=10 tests).
@Suite("Platform Basic Containers Extensions")
open class PlatformBasicContainersExtensionsTests: BaseTestClass {

    @MainActor
    private func expectCompliance<V: View>(_ view: V, componentName: String) {
        initializeTestConfig()
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: .iOS,
            componentName: componentName
        )
        #expect(hasAccessibilityID, "\(componentName) should generate accessibility identifiers on iOS")
    }

    @Test @MainActor func testPlatformHStackGeneratesAccessibilityIdentifiers() async {
        let view = platformHStack {
            Text("One")
            Text("Two")
        }
        expectCompliance(view, componentName: "platformHStack")
    }

    @Test @MainActor func testPlatformZStackGeneratesAccessibilityIdentifiers() async {
        let view = platformZStack {
            Color.clear
            Text("Overlay")
        }
        expectCompliance(view, componentName: "platformZStack")
    }

    @Test @MainActor func testPlatformLazyVStackContainerGeneratesAccessibilityIdentifiers() async {
        let view = EmptyView().platformLazyVStackContainer {
            ForEach(0..<3, id: \.self) { idx in
                Text("Row \(idx)")
            }
        }
        expectCompliance(view, componentName: "platformLazyVStackContainer")
    }

    @Test @MainActor func testPlatformLazyHStackContainerGeneratesAccessibilityIdentifiers() async {
        let view = EmptyView().platformLazyHStackContainer {
            ForEach(0..<3, id: \.self) { idx in
                Text("Chip \(idx)")
            }
        }
        expectCompliance(view, componentName: "platformLazyHStackContainer")
    }

    @Test @MainActor func testPlatformScrollViewContainerGeneratesAccessibilityIdentifiers() async {
        let view = EmptyView().platformScrollViewContainer {
            Text("Scrollable content")
        }
        expectCompliance(view, componentName: "platformScrollViewContainer")
    }

    @Test @MainActor func testPlatformListContainerGeneratesAccessibilityIdentifiers() async {
        let view = EmptyView().platformListContainer {
            Text("List row")
        }
        expectCompliance(view, componentName: "platformListContainer")
    }

    @Test @MainActor func testPlatformFormGeneratesAccessibilityIdentifiers() async {
        let view = platformForm {
            Text("Field label")
        }
        expectCompliance(view, componentName: "platformForm")
    }

    @Test @MainActor func testPlatformSidebarPullIndicatorGeneratesAccessibilityIdentifiers() async {
        let view = platformSidebarPullIndicator(isVisible: true)
        expectCompliance(view, componentName: "platformSidebarPullIndicator")
    }
}
