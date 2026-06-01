import Testing
import SwiftUI
@testable import SixLayerFramework

/// Harness-level tests for synthetic ID recovery when anonymous `.automaticCompliance()` suppresses wrapper IDs (#222).
@Suite("AccessibilityTestUtilities synthetic anonymous compliance")
struct AccessibilityTestUtilitiesSyntheticComplianceTests {

    @Test @MainActor
    func syntheticIdentifierMatchesSixLayerUiGlobForAnonymousButtonCompliance() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let view = Button("Test Button") { }
            .automaticCompliance()

        let ids = AccessibilityTestUtilities.testingSyntheticAutomaticComplianceIdentifiers(
            view: view,
            config: config
        )

        #expect(
            ids.contains(where: {
                AccessibilityTestUtilities.identifierMatchesExpectedPattern($0, expectedPattern: "SixLayer.*ui")
            }),
            "Expected synthetic ID for anonymous Button automaticCompliance; got: \(ids)"
        )
    }
}
