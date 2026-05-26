import SwiftUI
import Testing
@testable import SixLayerFramework

/// Verifies framework-owned reduce-motion policy for animation APIs (GitHub #298).
@Suite("Platform Reduce Motion Preference")
open class PlatformReduceMotionPreferenceTests: BaseTestClass {

    @Test @MainActor func testSystemReduceMotionMatchesTaskLocalOverrideWhenEnabled() {
        initializeTestConfig()
        PlatformReduceMotionPreference.withTestOverride(true) {
            #expect(PlatformReduceMotionPreference.isReduceMotionEnabled)
            let manager = AccessibilityManager()
            #expect(manager.isReduceMotionEnabled())
            let state = AccessibilitySystemState()
            #expect(state.isReducedMotionEnabled)
        }
    }

    @Test @MainActor func testSystemReduceMotionMatchesTaskLocalOverrideWhenDisabled() {
        initializeTestConfig()
        PlatformReduceMotionPreference.withTestOverride(false) {
            #expect(!PlatformReduceMotionPreference.isReduceMotionEnabled)
            let manager = AccessibilityManager()
            #expect(!manager.isReduceMotionEnabled())
            let state = AccessibilitySystemState()
            #expect(!state.isReducedMotionEnabled)
        }
    }

    @Test @MainActor func testRequestedAnimationSuppressedWhenReduceMotionEnabled() {
        initializeTestConfig()
        let spring = PlatformAnimation.spring.swiftUIAnimation
        let resolved = PlatformReduceMotionPreference.resolvedAnimation(
            spring,
            reduceMotionEnabled: true
        )
        #expect(resolved == nil, "Decorative animation should be suppressed when reduce motion is on")
    }

    @Test @MainActor func testRequestedAnimationPreservedWhenReduceMotionDisabled() {
        initializeTestConfig()
        let spring = PlatformAnimation.spring.swiftUIAnimation
        let resolved = PlatformReduceMotionPreference.resolvedAnimation(
            spring,
            reduceMotionEnabled: false
        )
        #expect(resolved != nil, "Decorative animation should remain when reduce motion is off")
    }

    @Test @MainActor func testWithPlatformAnimationSkipsWithAnimationWhenReduceMotionOn() async {
        initializeTestConfig()
        PlatformReduceMotionPreference.withTestOverride(true) {
            var changeCount = 0
            withPlatformAnimation(.spring) {
                changeCount += 1
            }
            #expect(changeCount == 1)
        }
    }

    @Test @MainActor func testAccessibilitySystemStateCopyPreservesSnapshot() {
        initializeTestConfig()
        PlatformReduceMotionPreference.withTestOverride(true) {
            let systemState = AccessibilitySystemState()
            let state = AccessibilitySystemState(from: systemState)
            #expect(state.isReducedMotionEnabled == systemState.isReducedMotionEnabled)
            #expect(state.isVoiceOverRunning == systemState.isVoiceOverRunning)
        }
    }
}
