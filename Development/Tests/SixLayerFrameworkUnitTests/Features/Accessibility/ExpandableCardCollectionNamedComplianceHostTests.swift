import Testing
import SwiftUI
@testable import SixLayerFramework

/// Release gate regression (#406): hosting ExpandableCardCollectionView under the HIG +
/// `automaticCompliance(named:)` stack must not trap with
/// `Fatal error: Can't unsafeBitCast between types of different sizes`.
@Suite("ExpandableCardCollection Named Compliance Host", HostedViewTestIsolationTrait())
open class ExpandableCardCollectionNamedComplianceHostTests: BaseTestClass {

    private struct Item: Identifiable {
        let id: String
        let title: String
    }

    @Test @MainActor func expandableCardCollectionView_namedComplianceUnderHIG_hostsWithoutTrap() async {
        initializeTestConfig()
        guard let config = testConfig else {
            Issue.record("testConfig missing after initializeTestConfig()")
            return
        }

        let previousDebug = config.enableDebugLogging
        config.enableDebugLogging = true
        config.clearDebugLog()
        defer { config.enableDebugLogging = previousDebug }

        let items = [
            Item(id: "1", title: "One"),
            Item(id: "2", title: "Two")
        ]
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )

        // Same production path as the release crash: L1 → ExpandableCardCollectionView + .appleHIGCompliant().
        let view = platformPresentItemCollection_L1(items: items, hints: hints)

        let hostedRoot = hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true,
            accessibilityIdentifierConfig: config
        )
        #expect(hostedRoot != nil, "Hosting ExpandableCardCollectionView under HIG must not trap (#406)")

        let debugLog = config.getDebugLog().joined(separator: "\n")
        #expect(
            debugLog.contains("ExpandableCardCollectionView"),
            "Named compliance for ExpandableCardCollectionView should run during host (#406); log=\(debugLog.prefix(500))"
        )
    }
}
