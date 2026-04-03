import Testing
import SwiftUI
@testable import SixLayerFramework

/// Manual `.accessibilityIdentifier` on `PlatformInteractionButton` when automatic IDs are off.
/// `AccessibilityIdentifierDisabledTests` only asserts inside `if let` (nil inspect passes vacuously);
/// this test requires evidence from the hosted UIKit tree and falls back to ViewInspector.
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

            let manualID = "manual-test-button"
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
            .accessibilityIdentifier(manualID)

            let root = Self.hostRootPlatformView(
                view,
                forceLayout: true,
                exposeContentAccessibility: true,
                accessibilityIdentifierConfig: config
            )
            let platformIDs = findAllAccessibilityIdentifiersFromPlatformView(root)
            if platformIDs.contains(manualID) {
                #expect(platformIDs.contains(manualID))
                return
            }

            #if canImport(ViewInspector)
            if let buttonID = AccessibilityTestUtilities.inspectButtonAccessibilityIdentifier(
                view,
                issuePrefix: "Failed to inspect view for manual accessibility identifier"
            ) {
                #expect(buttonID == manualID)
                return
            }
            #endif

            Issue.record(
                "Could not verify manual id '\(manualID)'; platform collected \(platformIDs.count) ids: \(platformIDs)"
            )
        }
    }
}
