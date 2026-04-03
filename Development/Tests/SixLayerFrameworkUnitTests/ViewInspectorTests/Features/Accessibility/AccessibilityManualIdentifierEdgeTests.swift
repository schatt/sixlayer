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

            // The substring "override" breaks `inspectButtonAccessibilityIdentifier` in this target
            // (returns nil); use a distinct stable id for the edge-case suite.
            let manualID = "manual-edge-custom-id"
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
