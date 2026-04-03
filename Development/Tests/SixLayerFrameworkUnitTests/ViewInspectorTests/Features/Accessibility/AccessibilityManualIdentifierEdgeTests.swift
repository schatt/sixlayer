import Testing
import SwiftUI
@testable import SixLayerFramework

/// Manual `.accessibilityIdentifier` on `PlatformInteractionButton` (edge-case doc lives next to
/// `AccessibilityIdentifierEdgeCaseTests`). Uses `BaseTestClass` + `runWithTaskLocalConfig` like
/// `AccessibilityIdentifierDisabledTests`; a bare `struct` + `withValue` did not reproduce the same
/// ViewInspector outcome in this target.
@Suite("Accessibility Manual Identifier Edge")
final class AccessibilityManualIdentifierEdgeTests: BaseTestClass {
    @Test @MainActor func testManualIDOverride() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false

            // Byte-for-byte parity with AccessibilityIdentifierDisabledTests.testManualIDsStillWorkWhenAutomaticDisabled
            // (including identifier string); used to validate inspect in this suite/file.
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
            .accessibilityIdentifier("manual-test-button")

            #if canImport(ViewInspector)
            if let buttonID = AccessibilityTestUtilities.inspectButtonAccessibilityIdentifier(
                view,
                issuePrefix: "Failed to inspect view for manual accessibility identifier"
            ) {
                #expect(buttonID == "manual-test-button", "Manual accessibility identifier should work when automatic is disabled")
            }
            #endif
        }
    }
}
