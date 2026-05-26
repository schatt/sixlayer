import SwiftUI
import Testing
@testable import SixLayerFramework

/// View hosting for reduce-motion animation APIs (GitHub #298).
@Suite("Platform Animation Reduce Motion")
open class PlatformAnimationReduceMotionTests: BaseTestClass {

    @Test @MainActor func testPlatformAnimationHostsWithReduceMotionEnvironment() async {
        initializeTestConfig()
        let view = Text("Animated")
            .platformAnimation(.easeInOut)
            .environment(\.accessibilityReduceMotion, true)
        verifyViewIsHostable(view, description: "platformAnimation with reduce motion environment")
    }

    @Test @MainActor func testPlatformAnimationHostsWithoutReduceMotionEnvironment() async {
        initializeTestConfig()
        let view = Text("Animated")
            .platformAnimation(.easeInOut)
            .environment(\.accessibilityReduceMotion, false)
        verifyViewIsHostable(view, description: "platformAnimation without reduce motion")
    }

    @Test @MainActor func testHigAnimationCategoryHostsWithReduceMotionEnvironment() async {
        initializeTestConfig()
        let view = Text("Category")
            .higAnimationCategory(.easeInOut)
            .environment(\.accessibilityReduceMotion, true)
        verifyViewIsHostable(view, description: "higAnimationCategory with reduce motion environment")
    }
}
