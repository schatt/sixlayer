import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformSecurityL1 (#466).
 * Observes L1 entry points (not only SecurityService).
 */

@Suite("Platform Security L1 Unit", HostedViewTestIsolationTrait())
struct PlatformSecurityL1UnitTests {

    @Test @MainActor
    func biometricAuthL1FailsWhenUnavailableInTestEnvironment() async {
        do {
            let authenticated = try await platformRequestBiometricAuth_L1(
                reason: "Unit test biometric probe"
            )
            #expect(!authenticated, "test env without biometrics must not report success")
        } catch let error as SecurityServiceError {
            #expect(error == .biometricNotAvailable)
        } catch {
            Issue.record("expected SecurityServiceError.biometricNotAvailable, got \(error)")
        }
    }

    @Test @MainActor
    func secureContentL1HostsProbeText() {
        TestSetupUtilities.hostExpectingPlatformRoot(exposeContentAccessibility: true) {
            platformPresentSecureContent_L1(
                content: Text("SecureProbe"),
                hints: SecurityHints(enablePrivacyIndicators: false)
            )
        }
    }

    @Test @MainActor
    func secureTextFieldL1UsesIdentifierNamePath() {
        var text = ""
        TestSetupUtilities.hostExpectingNamedCompliance(
            "platformPresentSecureTextField_L1",
            exposeContentAccessibility: true
        ) {
            platformPresentSecureTextField_L1(
                title: "Password",
                text: Binding(get: { text }, set: { text = $0 }),
                hints: SecurityHints(enableSecureTextEntry: true)
            )
        }
    }

    @Test @MainActor
    func privacyIndicatorL1ReturnsEmptyViewShell() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformShowPrivacyIndicator_L1(
                type: .camera,
                isActive: true,
                hints: SecurityHints(enablePrivacyIndicators: true)
            )
        }
    }
}
