import Testing
import ViewInspector
import SwiftUI
@testable import SixLayerFramework

/// Layer 4 navigation link structure (ViewInspector).
///
/// Do **not** `hostRootPlatformView` / `inspect()` `NavigationStack` / `NavigationView` wrappers
/// in unit/VI — those hang. Behavior of stack/split/title contracts: XCUI `Layer4UITests` + TestApp.
/// Refs #369.
@Suite(HostedViewTestIsolationTrait())
open class NavigationLayer4Tests: BaseTestClass {

    /// `platformNavigationLink_L4(destination:)` — label + NavigationLink structure (not a stack host).
    @Test @MainActor func testPlatformNavigationLink_L4_BasicDestination() {
        let destination = Text("Destination View")
        let label = Text("Navigate")

        let link = label.platformNavigationLink_L4(destination: destination) {
            Text("Label")
        }

        self.verifyViewContainsText(link, expectedText: "Label", testName: "Navigation link label")

        #if os(iOS)
        do {
            let inspected = try AnyView(link).inspect()
            _ = try inspected.find(ViewType.NavigationLink.self)
        } catch {
            Issue.record("iOS navigation link should contain NavigationLink structure: \(error)")
        }
        #elseif os(macOS)
        do {
            _ = try AnyView(link).inspect()
        } catch {
            Issue.record("macOS navigation link should be inspectable: \(error)")
        }
        #endif
    }
}
