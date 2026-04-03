import Testing
import SwiftUI
@testable import SixLayerFramework

/// Manual accessibility identifier checks isolated from `AccessibilityIdentifierEdgeCaseTests`.
/// `inspectButtonAccessibilityIdentifier` returns nil for the same view when the `@Test` is declared
/// on that open class (Swift Testing / ViewInspector interaction); a struct `Suite` avoids the failure.
@Suite("Accessibility Manual Identifier Edge")
struct AccessibilityManualIdentifierEdgeTests {
    @Test @MainActor func testManualIDOverride() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        config.enableAutoIDs = false

        let manualID = "edge-manual-identifier"
        // Build the view inside `withValue` so modifier bodies see the same @TaskLocal config as
        // `runWithTaskLocalConfig` in AccessibilityIdentifierDisabledTests (not `.shared` alone).
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
            .accessibilityIdentifier(manualID)

            #if canImport(ViewInspector)
            if let id = AccessibilityTestUtilities.inspectButtonAccessibilityIdentifier(
                view,
                issuePrefix: "Failed to inspect manual accessibility identifier"
            ) {
                #expect(id == manualID)
            } else {
                Issue.record("Inspection unavailable: expected manual id on hosted button")
            }
            #else
            Issue.record("ViewInspector required for manual accessibilityIdentifier test")
            #endif
        }
    }
}
