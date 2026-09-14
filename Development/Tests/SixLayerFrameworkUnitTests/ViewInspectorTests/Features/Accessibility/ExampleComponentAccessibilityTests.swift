import Testing
import SwiftUI
@testable import SixLayerFramework

/// Accessibility identifier compliance for example components (unit lane; no ViewInspector required — #395).
@Suite("Example Component Accessibility", HostedViewTestIsolationTrait())
open class ExampleComponentAccessibilityTests: BaseTestClass {

    @Test @MainActor func testExampleHelpersGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let testView = platformVStackContainer {
                Text("Example Helpers")
            }
            .automaticCompliance(named: "ExampleHelpers")

            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: "SixLayer.main.ui.*ExampleHelpers*",
                platform: SixLayerPlatform.current,
                componentName: "ExampleHelpers"
            )
            #expect(hasAccessibilityID, "ExampleHelpers should generate accessibility identifiers")
        }
    }
}
