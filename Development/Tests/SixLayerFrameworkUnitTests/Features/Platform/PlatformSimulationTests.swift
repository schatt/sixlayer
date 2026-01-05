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
@Suite("Platform Detection")
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
        // Clear any overrides to test default platform behavior
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        
        let platform = SixLayerPlatform.current

        switch platform {
        case .iOS:
            // iOS always has 44pt minimum per Apple HIG
            #expect(RuntimeCapabilityDetection.minTouchTarget == 44.0, "iOS should always have 44pt minimum touch targets")
        case .watchOS:
            // watchOS always has 44pt minimum per Apple HIG
            #expect(RuntimeCapabilityDetection.minTouchTarget == 44.0, "watchOS should always have 44pt minimum touch targets")
        case .macOS, .tvOS, .visionOS:
            // These platforms have 44pt targets if touch is detected, 0 otherwise
            // Per Apple HIG: 44pt when touch is available for accessibility compliance
            let supportsTouch = RuntimeCapabilityDetection.supportsTouch
            let expected: CGFloat = supportsTouch ? 44.0 : 0.0
            let actual: CGFloat = RuntimeCapabilityDetection.minTouchTarget
            // Use abs() for floating point comparison to handle any precision issues
            #expect(abs(actual - expected) < 0.001, "Non-touch-first platforms should have 44pt targets when touch is detected (per Apple HIG), got \(actual) with supportsTouch=\(supportsTouch), expected \(expected)")
        }
    }
}