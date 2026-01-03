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
    
    /// Get platform configuration for a specific platform
    public static func getPlatformConfig(for platform: SixLayerPlatform) -> PlatformConfig {
        switch platform {
        case .iOS:
            return PlatformConfig(
                supportsHapticFeedback: true,
                supportsHover: false, // Device-dependent, default to false
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44.0,
                hoverDelay: 0.5 // iPad with Apple Pencil
            )
        case .macOS:
            return PlatformConfig(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0.0,
                hoverDelay: 0.5
            )
        case .watchOS:
            return PlatformConfig(
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 44.0,
                hoverDelay: 0.0
            )
        case .tvOS:
            return PlatformConfig(
                supportsHapticFeedback: false,
                supportsHover: false,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0.0,
                hoverDelay: 0.0
            )
        case .visionOS:
            return PlatformConfig(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0.0,
                hoverDelay: 0.5
            )
        }
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
