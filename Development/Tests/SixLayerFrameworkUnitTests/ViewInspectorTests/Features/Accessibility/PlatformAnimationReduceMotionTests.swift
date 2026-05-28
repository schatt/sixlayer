import SwiftUI
import Testing
@testable import SixLayerFramework

/// Hosting coverage for reduce-motion animation APIs after subtree-gating fix (#298).
@Suite(.serialized)
open class PlatformAnimationReduceMotionTests: BaseTestClass {

    @MainActor
    private func verifyViewIsHostable<V: View>(_ view: V, description: String) {
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "\(description) should be hostable")
    }

    @Test @MainActor func testPlatformAnimationHostsWithReduceMotionOverride() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformReduceMotionPreference.withTestOverride(true) {
                verifyViewIsHostable(
                    Text("Animated").platformAnimation(.easeInOut),
                    description: "platformAnimation with reduce motion override"
                )
            }
        }
    }

    @Test @MainActor func testAutomaticComplianceHostsWithReduceMotionOverride() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformReduceMotionPreference.withTestOverride(true) {
                verifyViewIsHostable(
                    Text("Compliance").automaticCompliance(),
                    description: "automaticCompliance with reduce motion override"
                )
            }
        }
    }
}
