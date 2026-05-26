import SwiftUI
import Testing
@testable import SixLayerFramework

/// View hosting for reduce-motion animation APIs (GitHub #298).
@Suite(.serialized, "Platform Animation Reduce Motion")
open class PlatformAnimationReduceMotionTests: BaseTestClass {

    @MainActor
    private func verifyViewIsHostable<V: View>(_ view: V, description: String) {
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "\(description) should be hostable")
    }

    @Test @MainActor func testPlatformAnimationHostsWithReduceMotionOverride() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformReduceMotionPreference.withTestOverride(true) {
                let view = Text("Animated").platformAnimation(.easeInOut)
                verifyViewIsHostable(view, description: "platformAnimation with reduce motion override")
            }
        }
    }

    @Test @MainActor func testPlatformAnimationHostsWithoutReduceMotionOverride() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformReduceMotionPreference.withTestOverride(false) {
                let view = Text("Animated").platformAnimation(.easeInOut)
                verifyViewIsHostable(view, description: "platformAnimation without reduce motion override")
            }
        }
    }

    @Test @MainActor func testHigAnimationCategoryHostsWithReduceMotionOverride() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformReduceMotionPreference.withTestOverride(true) {
                let view = Text("Category").higAnimationCategory(.easeInOut)
                verifyViewIsHostable(view, description: "higAnimationCategory with reduce motion override")
            }
        }
    }
}
