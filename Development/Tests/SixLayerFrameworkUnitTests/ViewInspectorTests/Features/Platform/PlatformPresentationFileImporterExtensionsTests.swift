import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import SixLayerFramework

/// `platformPresentationDetents` and `platformFileImporter` (Issue #170). Grouped; keep <=10 tests.
@Suite("Platform Presentation and File Importer Extensions")
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
            let anonymousHost = hostRootPlatformView(anonymous, accessibilityIdentifierConfig: isolated)
            #expect(anonymousHost != nil, "\(context): anonymous path should render")

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

    @Test @MainActor func testPlatformPresentationDetentsTypedMediumLargeNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformPresDetentsTypedML", context: "platformPresentationDetents typed") {
            Text("Detents typed ML")
                .platformPresentationDetents([.medium, .large])
        }
    }

    @Test @MainActor func testPlatformPresentationDetentsTypedCustomNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformPresDetentsTypedCustom", context: "platformPresentationDetents typed custom") {
            Text("Detents typed custom")
                .platformPresentationDetents([.custom(140)])
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
            #expect(Bool(true), "iOS 16+ required for PresentationDetent Any overload probe")
        }
        #else
        #expect(Bool(true), "PresentationDetent Any overload probe is iOS-only in this suite")
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
        let hosted = Self.hostRootPlatformView(PlatformPresentationFileImporterAuditHost(onBackToMain: nil))
        #expect(hosted != nil)
    }
}
