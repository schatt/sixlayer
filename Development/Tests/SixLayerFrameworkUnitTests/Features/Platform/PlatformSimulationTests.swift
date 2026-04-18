//
//  PlatformSimulationTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Tests platform detection and runtime capability validation.
//  Since platform simulation was removed, these tests now verify
//  that runtime capability detection works correctly on the current platform.
//
//  TESTING SCOPE:
//  - Platform detection accuracy
//  - Runtime capability detection
//  - Platform-specific behavior validation
//
//  METHODOLOGY:
//  - Test platform detection returns correct values
//  - Verify runtime capabilities match expected platform behavior
//  - Validate platform-specific features work correctly
//
//  QUALITY ASSESSMENT: ✅ EXCELLENT
//  - ✅ Excellent: Tests actual platform behavior
//  - ✅ Excellent: Validates runtime capability detection
//  - ✅ Excellent: Ensures platform-specific features work correctly
//


import Testing
import Foundation
@testable import SixLayerFramework

/// Platform detection and capability tests
/// Tests verify that runtime capability detection works correctly
@Suite("Platform Detection", DefaultRuntimeCapabilityIsolationTrait())
open class PlatformSimulationTests: BaseTestClass {

    // MARK: - Platform Detection Tests

    @Test func testCurrentPlatformDetection() {
        let platform = SixLayerPlatform.current
        #expect(platform == .iOS || platform == .macOS || platform == .watchOS || platform == .tvOS || platform == .visionOS)
    }

    @Test func testRuntimeCapabilityDetection() {
        // Clear any test overrides to use real platform detection
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        
        // Test that runtime capability detection works
        let supportsTouch = RuntimeCapabilityDetection.supportsTouch
        let supportsHaptic = RuntimeCapabilityDetection.supportsHapticFeedback
        let supportsVoiceOver = RuntimeCapabilityDetection.supportsVoiceOver
        let supportsSwitchControl = RuntimeCapabilityDetection.supportsSwitchControl

        // All should be boolean values
        #expect(type(of: supportsTouch) == Bool.self)
        #expect(type(of: supportsHaptic) == Bool.self)
        #expect(type(of: supportsVoiceOver) == Bool.self)
        #expect(type(of: supportsSwitchControl) == Bool.self)

        // VoiceOver and SwitchControl should always be true for Apple platforms
        #expect(supportsVoiceOver == true)
        #expect(supportsSwitchControl == true)
    }

    @Test func testPlatformSpecificCapabilities() {
        // Apple HIG per platform (Issue #237):
        //   iOS:      44pt (touch HIG)
        //   watchOS:  44pt (inherited — watchOS HIG does not publish a numeric minimum)
        //   tvOS:     60pt (focus engine at 10-foot distance, independent of touch)
        //   visionOS: 60pt (gaze+pinch minimum, independent of hand-tracking touch)
        //   macOS:    44pt if runtime touch detected, else 0pt
        //
        // Prior test collapsed tvOS + visionOS under the macOS pointer-driven
        // branch ("44 if touch, else 0"), which violated their respective HIGs.
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        let platform = SixLayerPlatform.current
        let expected = PlatformTestUtilities.expectedMinTouchTarget(for: platform)
        let actual = RuntimeCapabilityDetection.minTouchTarget

        #expect(abs(actual - expected) < 0.001,
                "Apple HIG: \(platform) expected \(expected)pt, got \(actual)pt (supportsTouch=\(RuntimeCapabilityDetection.supportsTouch))")
    }
}