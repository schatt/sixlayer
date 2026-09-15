import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformSecurityL1 (#466).
 * Observes L1 entry points (not only SecurityService).
 */

@Suite("Platform Security L1 Unit")
struct PlatformSecurityL1UnitTests {

    @Test @MainActor
    func biometricAuthL1FailsWhenUnavailableInTestEnvironment() async throws {
        // Deliberate red (#466): expect success. Test env has no biometrics → throw/false.
        let authenticated = try await platformRequestBiometricAuth_L1(
            reason: "Unit test biometric probe"
        )
        #expect(authenticated, "deliberate red: expect biometrics available in CI")
    }

    @Test @MainActor
    func secureContentL1HostsProbeText() {
        #if os(watchOS)
        return
        #else
        let view = platformPresentSecureContent_L1(
            content: Text("SecureProbe"),
            hints: SecurityHints(enablePrivacyIndicators: false)
        )
        let hosted = TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true
        )
        #expect(hosted != nil, "secure content L1 must host on UIKit/AppKit")
        #endif
    }

    @Test @MainActor
    func secureTextFieldL1EmitsNamedIdentifier() {
        #if os(watchOS)
        return
        #else
        var text = ""
        let view = platformPresentSecureTextField_L1(
            title: "Password",
            text: Binding(get: { text }, set: { text = $0 }),
            hints: SecurityHints(enableSecureTextEntry: true)
        )
        let hosted = TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true
        )
        let ids = findAllAccessibilityIdentifiersFromPlatformView(hosted)
        #expect(
            ids.contains(where: { $0.contains("platformPresentSecureTextField_L1") }),
            "secure text field L1 must emit its named compliance id. ids=\(ids)"
        )
        #endif
    }

    @Test @MainActor
    func privacyIndicatorL1ReturnsEmptyViewShell() {
        let view = platformShowPrivacyIndicator_L1(
            type: .camera,
            isActive: true,
            hints: SecurityHints(enablePrivacyIndicators: true)
        )
        // EmptyView shell — observe by hosting without crash.
        #if os(watchOS)
        _ = view
        #else
        let hosted = TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true
        )
        #expect(hosted != nil)
        #endif
    }
}
