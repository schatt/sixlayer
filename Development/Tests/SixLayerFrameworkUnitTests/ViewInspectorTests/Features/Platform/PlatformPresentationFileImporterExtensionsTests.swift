import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import SixLayerFramework

/// `platformPresentationDetents` and `platformFileImporter` (Issue #170). Grouped; keep <=10 tests.
@Suite("Platform Presentation and File Importer Extensions", HostedViewTestIsolationTrait())
open class PlatformPresentationFileImporterExtensionsTests: BaseTestClass {

    @MainActor
    private func assertLayoutChromeDualPath<V: View>(
        anchorName: String,
        context: String,
        @ViewBuilder root: () -> V
    ) {
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let anonymous = root()
            _ = TestSetupUtilities.hostObservingPlatformRoot(
                accessibilityIdentifierConfig: isolated
            ) { anonymous }

            let named = root().named(anchorName)
            let namedHost = TestSetupUtilities.hostObservingPlatformRoot(
                accessibilityIdentifierConfig: isolated
            ) { named }

            #if os(watchOS) || os(visionOS)
            _ = (namedHost, context)
            #else
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
            #endif
        }
    }

    @Test @MainActor func testPlatformPresentationDetentsTypedMediumLargeNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformPresDetentsTypedML", context: "platformPresentationDetents fromSizes") {
            Text("Detents typed ML")
                .platformPresentationDetents(fromSizes: [.medium, .large])
        }
    }

    @Test @MainActor func testPlatformPresentationDetentsTypedCustomNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformPresDetentsTypedCustom", context: "platformPresentationDetents fromSizes exact") {
            Text("Detents typed custom")
                .platformPresentationDetents(fromSizes: [.exact(width: 140, height: 140)])
        }
    }

    @Test @MainActor func testPlatformPresentationDetentsAnyArrayNamedCompliance() async {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            assertLayoutChromeDualPath(anchorName: "PlatformPresDetentsAny", context: "platformPresentationDetents [Any]") {
                Text("Detents any")
                    .platformPresentationDetents(
                        [PresentationDetent.medium as Any, PresentationDetent.large as Any]
                    )
            }
        } else {
        }
        #else
        #endif
    }

    @Test @MainActor func testPlatformFileImporterNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformFileImporter", context: "platformFileImporter") {
            Text("Importer host")
                .platformFileImporter(
                    isPresented: .constant(false),
                    allowedContentTypes: [UTType.plainText],
                    allowsMultipleSelection: false
                ) { _ in }
        }
    }

    @Test @MainActor func testPlatformPresentationFileImporterAuditHostRenders() async {
        TestSetupUtilities.hostExpectingPlatformRoot {
            PlatformPresentationFileImporterAuditHost(onBackToMain: nil)
        }
    }
}
