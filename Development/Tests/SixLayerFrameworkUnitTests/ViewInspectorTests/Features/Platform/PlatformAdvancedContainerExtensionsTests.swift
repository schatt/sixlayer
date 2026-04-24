import Testing
import SwiftUI
@testable import SixLayerFramework

/// `PlatformAdvancedContainerExtensions` styling modifiers (Issue #170). Grouped; keep <=10 tests.
@Suite("Platform Advanced Container Extensions")
open class PlatformAdvancedContainerExtensionsTests: BaseTestClass {

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

    @Test @MainActor func testPlatformLazyVGridContainerNamedCompliance() async {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        assertLayoutChromeDualPath(anchorName: "PlatformAdvancedLazyVGrid", context: "platformLazyVGridContainer") {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<2, id: \.self) { idx in
                    Text("Cell \(idx)")
                }
            }
            .platformLazyVGridContainer()
        }
    }

    @Test @MainActor func testPlatformScrollContainerNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformAdvancedScrollContainer", context: "platformScrollContainer") {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Line 1")
                    Text("Line 2")
                }
            }
            .frame(minHeight: 40, maxHeight: 56)
            .platformScrollContainer(showsIndicators: false)
        }
    }

    @Test @MainActor func testPlatformAdvancedListContainerModifierNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformAdvancedListContainer", context: "List.platformListContainer") {
            List {
                Text("Row A")
                Text("Row B")
            }
            .frame(minHeight: 56, maxHeight: 72)
            .platformListContainer()
        }
    }

    @Test @MainActor func testPlatformFormContainerModifierNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformAdvancedFormContainer", context: "Form.platformFormContainer") {
            Form {
                Section("S") {
                    Text("Value")
                }
            }
            .frame(minHeight: 64, maxHeight: 88)
            .platformFormContainer()
        }
    }

    @Test @MainActor func testPlatformTabContainerNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformAdvancedTabContainer", context: "TabView.platformTabContainer") {
            TabView {
                Text("T1")
                    .tabItem { Text("One") }
                Text("T2")
                    .tabItem { Text("Two") }
            }
            .frame(height: 96)
            .platformTabContainer()
        }
    }
}
