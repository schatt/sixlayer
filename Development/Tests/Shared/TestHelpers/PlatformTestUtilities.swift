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
