import Testing
import SwiftUI
@testable import SixLayerFramework

/// `platformFrame`, `platformContentSpacing`, `platformHelp`, and `platformHoverEffect` utilities (Issue #170).
/// Grouped; keep <=10 tests.
@Suite("Platform Frame Spacing Utility Extensions")
open class PlatformFrameSpacingUtilityExtensionsTests: BaseTestClass {

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

    @Test @MainActor func testPlatformFrameDefaultNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformFrameDefault", context: "platformFrame()") {
            Text("Default frame")
                .platformFrame()
        }
    }

    @Test @MainActor func testPlatformFrameFixedNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformFrameFixed", context: "platformFrame(width:height:)") {
            Text("Fixed frame")
                .platformFrame(width: 120, height: 44, alignment: .leading)
        }
    }

    @Test @MainActor func testPlatformFrameConstraintsNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformFrameConstraints", context: "platformFrame(min/ideal/max)") {
            Text("Flexible frame")
                .platformFrame(minWidth: 80, idealWidth: 120, maxWidth: 180, minHeight: 32, maxHeight: 52)
        }
    }

    @Test @MainActor func testPlatformContentSpacingTopPaddingNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContentSpacingTop", context: "platformContentSpacing(topPadding:)") {
            Text("Top spacing")
                .platformContentSpacing(topPadding: 8)
        }
    }

    @Test @MainActor func testPlatformContentSpacingDirectionalNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContentSpacingDirectional", context: "platformContentSpacing(top:bottom:leading:trailing:)") {
            Text("Directional spacing")
                .platformContentSpacing(top: 4, bottom: 6, leading: 8, trailing: 10)
        }
    }

    @Test @MainActor func testPlatformContentSpacingAxisNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContentSpacingAxis", context: "platformContentSpacing(horizontal:vertical:)") {
            Text("Axis spacing")
                .platformContentSpacing(horizontal: 10, vertical: 6)
        }
    }

    @Test @MainActor func testPlatformContentSpacingUniformNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformContentSpacingUniform", context: "platformContentSpacing(all:)") {
            Text("Uniform spacing")
                .platformContentSpacing(all: 8)
        }
    }

    @Test @MainActor func testPlatformHelpNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformHelp", context: "platformHelp") {
            Text("Help target")
                .platformHelp("Help text")
        }
    }

    @Test @MainActor func testPlatformHoverEffectNamedCompliance() async {
        assertLayoutChromeDualPath(anchorName: "PlatformHoverEffect", context: "platformHoverEffect") {
            Text("Hover target")
                .platformHoverEffect { _ in }
        }
    }

    @Test @MainActor func testPlatformFrameSpacingAuditHostRenders() async {
        let hosted = Self.hostRootPlatformView(PlatformFrameSpacingUtilitiesAuditHost(onBackToMain: nil))
        #expect(hosted != nil)
    }
}
