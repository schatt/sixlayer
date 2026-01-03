import Testing


import SwiftUI
@testable import SixLayerFramework

/// Platform Logic Tests
/// Tests the platform detection and configuration logic without relying on runtime platform detection
/// These tests focus on the logic that determines platform-specific behavior
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Logic")
open class PlatformLogicTests: BaseTestClass {
    
    // Local, general-purpose capability snapshot for tests (do not use card-specific config)
    public struct PlatformCapabilities: Sendable {
        let supportsHapticFeedback: Bool
        let supportsHover: Bool
        let supportsTouch: Bool
        let supportsVoiceOver: Bool
        let supportsSwitchControl: Bool
        let supportsAssistiveTouch: Bool
        let minTouchTarget: Int
        let hoverDelay: Double
    }

    // Local performance config for animation-related tests (avoid card-specific config)
    public struct PerformanceConfig {
        let targetFrameRate: Int
        let maxAnimationDuration: Double
    }
    
    // MARK: - Platform Detection Logic Tests
    
    @Test @MainActor func testPlatformDetectionLogic() {
        // GIVEN: Current platform configuration
        let currentPlatform = SixLayerPlatform.current

        // WHEN: Testing platform detection logic using runtime capability detection
        // Note: Using RuntimeCapabilityDetection properties directly since we're testing platform capabilities, not card-specific configs

        // THEN: Should be able to determine platform characteristics for current platform
        // Test that platform-specific capabilities are correctly determined
        switch currentPlatform {
            case .iOS:
                #expect(RuntimeCapabilityDetection.supportsTouch, "iOS should support touch")
                #expect(RuntimeCapabilityDetection.supportsHapticFeedback, "iOS should support haptic feedback")
                #expect(RuntimeCapabilityDetection.supportsAssistiveTouch, "iOS should support AssistiveTouch")
                #expect(RuntimeCapabilityDetection.supportsVoiceOver, "iOS should support VoiceOver")
                #expect(RuntimeCapabilityDetection.supportsSwitchControl, "iOS should support SwitchControl")

            case .macOS:
                #expect(!RuntimeCapabilityDetection.supportsTouch, "macOS should not support touch")
                #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "macOS should not support haptic feedback")
                #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch, "macOS should not support AssistiveTouch")
                #expect(RuntimeCapabilityDetection.supportsHover, "macOS should support hover")
                #expect(RuntimeCapabilityDetection.supportsVoiceOver, "macOS should support VoiceOver")
                #expect(RuntimeCapabilityDetection.supportsSwitchControl, "macOS should support SwitchControl")

            case .watchOS:
                #expect(RuntimeCapabilityDetection.supportsTouch, "watchOS should support touch")
                #expect(RuntimeCapabilityDetection.supportsHapticFeedback, "watchOS should support haptic feedback")
                #expect(RuntimeCapabilityDetection.supportsAssistiveTouch, "watchOS should support AssistiveTouch")
                #expect(!RuntimeCapabilityDetection.supportsHover, "watchOS should not support hover")
                #expect(RuntimeCapabilityDetection.supportsVoiceOver, "watchOS should support VoiceOver")
                #expect(RuntimeCapabilityDetection.supportsSwitchControl, "watchOS should support SwitchControl")

            case .tvOS:
                #expect(!RuntimeCapabilityDetection.supportsTouch, "tvOS should not support touch")
                #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "tvOS should not support haptic feedback")
                #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch, "tvOS should not support AssistiveTouch")
                #expect(!RuntimeCapabilityDetection.supportsHover, "tvOS should not support hover")
                #expect(RuntimeCapabilityDetection.supportsVoiceOver, "tvOS should support VoiceOver")
                #expect(RuntimeCapabilityDetection.supportsSwitchControl, "tvOS should support SwitchControl")

            case .visionOS:
                #expect(!RuntimeCapabilityDetection.supportsTouch, "visionOS should not support touch")
                #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "visionOS should not support haptic feedback")
                #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch, "visionOS should not support AssistiveTouch")
                #expect(RuntimeCapabilityDetection.supportsHover, "visionOS should support hover")
                #expect(RuntimeCapabilityDetection.supportsVoiceOver, "visionOS should support VoiceOver")
                #expect(RuntimeCapabilityDetection.supportsSwitchControl, "visionOS should support SwitchControl")
        }
    }
    
    @Test @MainActor func testDeviceTypeDetectionLogic() {
        // GIVEN: Current device type
        let currentDeviceType = DeviceType.current

        // WHEN: Testing device type detection logic
        // THEN: Should be able to determine current device characteristics
        switch currentDeviceType {
        case .phone:
            #expect(RuntimeCapabilityDetection.supportsTouch, "Phone should support touch")
        case .car:
            #expect(RuntimeCapabilityDetection.supportsTouch, "Car should support touch")
            #expect(RuntimeCapabilityDetection.supportsHapticFeedback, "Car should support haptic feedback")
            #expect(!RuntimeCapabilityDetection.supportsHover, "Car should not support hover")

        case .pad:
            #expect(RuntimeCapabilityDetection.supportsTouch, "Pad should support touch")
            #expect(RuntimeCapabilityDetection.supportsHapticFeedback, "Pad should support haptic feedback")
            #expect(RuntimeCapabilityDetection.supportsHover, "Pad should support hover")

        case .mac:
            #expect(!RuntimeCapabilityDetection.supportsTouch, "Mac should not support touch")
            #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "Mac should not support haptic feedback")
            #expect(RuntimeCapabilityDetection.supportsHover, "Mac should support hover")

        case .watch:
            #expect(RuntimeCapabilityDetection.supportsTouch, "Watch should support touch")
            #expect(RuntimeCapabilityDetection.supportsHapticFeedback, "Watch should support haptic feedback")
            #expect(!RuntimeCapabilityDetection.supportsHover, "Watch should not support hover")

        case .tv:
            #expect(!RuntimeCapabilityDetection.supportsTouch, "TV should not support touch")
            #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "TV should not support haptic feedback")
            #expect(!RuntimeCapabilityDetection.supportsHover, "TV should not support hover")

        case .vision:
            #expect(!RuntimeCapabilityDetection.supportsTouch, "Vision should not support touch")
            #expect(!RuntimeCapabilityDetection.supportsHapticFeedback, "Vision should not support haptic feedback")
            #expect(RuntimeCapabilityDetection.supportsHover, "Vision should support hover")
        }
    }
    
    // MARK: - Capability Matrix Tests
    

    @Test func testAccessibilityRequirements() {
        // GIVEN: Current platform
        let currentPlatform = SixLayerPlatform.current

        // WHEN: Testing accessibility support requirements
        // THEN: All Apple platforms should support essential accessibility features
        #expect(RuntimeCapabilityDetection.supportsVoiceOver, "\(currentPlatform) should support VoiceOver")
        #expect(RuntimeCapabilityDetection.supportsSwitchControl, "\(currentPlatform) should support SwitchControl")
    }
    
    
    // MARK: - Vision Framework Availability Tests
    
    @Test @MainActor func testVisionFrameworkAvailabilityLogic() {
        // GIVEN: Current platform
        let currentPlatform = SixLayerPlatform.current

        // WHEN: Testing Vision framework availability on current platform
        let hasVision = isVisionFrameworkAvailable()

        // THEN: Vision availability should be correct for current platform
        switch currentPlatform {
        case .iOS, .macOS, .visionOS:
            #expect(hasVision, "\(currentPlatform) should have Vision framework")

        case .watchOS, .tvOS:
            #expect(!hasVision, "\(currentPlatform) should not have Vision framework")
        }
    }
    
    @Test @MainActor func testOCRAvailabilityLogic() {
        // GIVEN: Current platform
        let currentPlatform = SixLayerPlatform.current

        // WHEN: Testing OCR availability on current platform
        let hasOCR = isVisionOCRAvailable()

        // THEN: OCR availability should be correct for current platform
        switch currentPlatform {
        case .iOS, .macOS, .visionOS:
            #expect(hasOCR, "\(currentPlatform) should have OCR")

        case .watchOS, .tvOS:
            #expect(!hasOCR, "\(currentPlatform) should not have OCR")
        }
    }
    
}
