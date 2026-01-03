//
//  PlatformTestUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Platform-specific test utilities for getting platform configurations and capabilities
//

import Foundation
@testable import SixLayerFramework

/// Platform test utilities
public enum PlatformTestUtilities {
    
    /// Platform configuration snapshot
    public struct PlatformConfig {
        public let supportsHapticFeedback: Bool
        public let supportsHover: Bool
        public let supportsTouch: Bool
        public let supportsVoiceOver: Bool
        public let supportsSwitchControl: Bool
        public let supportsAssistiveTouch: Bool
        public let minTouchTarget: CGFloat
        public let hoverDelay: TimeInterval
    }
    
    /// Get platform configuration for a specific platform using runtime detection with overrides
    public static func getPlatformConfig(for platform: SixLayerPlatform) -> PlatformConfig {
        // Set platform-specific overrides for testing
        switch platform {
        case .iOS:
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(false)
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        case .macOS:
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(true)
            RuntimeCapabilityDetection.setTestTouchSupport(false) // Default, but can be overridden for touchscreen Macs
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        case .watchOS:
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(false)
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        case .tvOS:
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(false)
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        case .visionOS:
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(true)
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        }

        // VoiceOver and SwitchControl are always available on Apple platforms
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)

        // Return runtime-detected values (which now use the overrides above)
        return PlatformConfig(
            supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
            supportsHover: RuntimeCapabilityDetection.supportsHover,
            supportsTouch: RuntimeCapabilityDetection.supportsTouch,
            supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
            supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
            supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
            minTouchTarget: RuntimeCapabilityDetection.minTouchTarget,
            hoverDelay: RuntimeCapabilityDetection.hoverDelay
        )
    }
    
    /// Get OCR availability for a platform
    public static func getOCRAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS:
            return true
        case .watchOS, .tvOS, .visionOS:
            return false
        }
    }
    
    /// Get Vision availability for a platform
    public static func getVisionAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS:
            return true
        case .watchOS, .tvOS, .visionOS:
            return false
        }
    }
}
