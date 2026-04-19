import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("Platform Security and Notification L1")
open class PlatformSecurityNotificationL1Tests: BaseTestClass {

    private nonisolated static func issue245_namedAutomaticComplianceFingerprint(componentName: String) -> String {
        "NAMED MODIFIER DEBUG: body() called for '\(componentName)'"
    }

    @MainActor
    private static func issue245_shellsThatMustNotUseNamedAutomaticCompliance() -> [(name: String, view: AnyView)] {
        [
            ("platformPresentSecureContent_L1", AnyView(platformPresentSecureContent_L1(content: Text("secure")))),
            ("platformShowPrivacyIndicator_L1", AnyView(platformShowPrivacyIndicator_L1(type: .camera, isActive: true))),
            ("platformPresentAlert_L1", platformPresentAlert_L1(title: "Alert", message: "Body"))
        ]
    }

    @Test @MainActor
    func testIssue245_securityAndNotificationShellsDoNotUseNamedAutomaticComplianceModifier() async {
        for shell in Self.issue245_shellsThatMustNotUseNamedAutomaticCompliance() {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                let host = Self.hostRootPlatformView(
                    shell.view,
                    forceLayout: true,
                    accessibilityIdentifierConfig: isolated
                )
                #expect(host != nil, "\(shell.name) should host")
                let log = isolated.getDebugLog()
                let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(componentName: shell.name)
                #expect(
                    !log.contains(fingerprint),
                    "\(shell.name) must not use NamedAutomaticComplianceModifier (issue #245); log sample: \(String(log.suffix(400)))"
                )
            }
        }
    }

    @Test @MainActor
    func testIssue245_platformPresentSecureTextFieldUsesNamedAutomaticComplianceModifier() async {
        let view = platformPresentSecureTextField_L1(
            title: "Password",
            text: .constant("")
        )
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let host = Self.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
            #expect(host != nil, "platformPresentSecureTextField_L1 should host")
            let log = isolated.getDebugLog()
            let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(
                componentName: "platformPresentSecureTextField_L1"
            )
            #expect(
                log.contains(fingerprint),
                "platformPresentSecureTextField_L1 should still use NamedAutomaticComplianceModifier; log sample: \(String(log.suffix(400)))"
            )
        }
    }
}
