//
//  PlatformStrategy.swift
//  SixLayerFramework
//
//  Centralized platform-specific strategy values and computed properties
//  Consolidates platform switch statements to reduce code duplication (DRY)
//
//  Created as part of Issue #140: Consolidate Platform Switch Statements
//

import Foundation
import SwiftUI

// MARK: - Platform Strategy Extension

/// Platform-specific strategy values and computed properties
/// Consolidates common platform switch statements to reduce duplication
public extension SixLayerPlatform {
    
    // MARK: - Touch & Interaction Properties
    
    /// Minimum touch target size for accessibility compliance (points)
    /// Per Apple HIG: 44x44 points on touch-first platforms
    /// 
    /// - iOS/watchOS: Always 44.0 (touch-first platforms)
    /// - macOS/tvOS/visionOS: 44.0 if touch is detected, 0.0 otherwise
    var minTouchTarget: CGFloat {
        switch self {
        case .iOS, .watchOS:
            return 44.0  // Touch-first platforms always need touch-sized targets
        case .macOS, .tvOS, .visionOS:
            // Non-touch-first platforms: check runtime touch capability for accessibility
            // Note: This requires RuntimeCapabilityDetection, so we'll use a computed property
            // that checks at runtime. For compile-time only, return 0.0
            return RuntimeCapabilityDetection.supportsTouch ? 44.0 : 0.0
        }
    }
    
    /// Whether this platform natively supports touch as primary interaction
    /// This is a platform characteristic, not runtime capability detection
    var isTouchFirstPlatform: Bool {
        switch self {
        case .iOS, .watchOS:
            return true
        case .macOS, .tvOS, .visionOS:
            return false
        }
    }
    
    /// Whether this platform natively supports hover as primary interaction
    var isHoverFirstPlatform: Bool {
        switch self {
        case .macOS, .visionOS:
            return true
        case .iOS, .watchOS, .tvOS:
            return false
        }
    }
    
    // MARK: - Hover Properties
    
    /// Platform-appropriate hover delay (seconds)
    /// Returns the delay value only if hover is actually supported at runtime.
    /// Returns 0.0 if hover is not supported.
    /// 
    /// This checks runtime hover support because there's no practical use case
    /// for getting a hover delay value when hover isn't available.
    /// 
    /// - macOS: 0.5s (if hover supported via mouse/trackpad)
    /// - visionOS: 0.5s (if hover supported via hand tracking)
    /// - iOS: 0.5s (if hover supported on iPad with Apple Pencil), 0.0 for iPhone
    /// - watchOS: 0.0s (no hover support)
    /// - tvOS: 0.0s (no hover support)
    var hoverDelay: TimeInterval {
        // Check runtime support first - no point returning a delay if hover isn't available
        guard RuntimeCapabilityDetection.supportsHover else {
            return 0.0
        }
        
        // Return platform-appropriate delay for platforms that support hover
        switch self {
        case .macOS, .visionOS:
            return 0.5
        case .iOS:
            // iPad with Apple Pencil hover - runtime check already verified support
            return 0.5
        case .watchOS, .tvOS:
            return 0.0  // These platforms don't support hover
        }
    }
    
    // MARK: - Presentation Strategy Properties
    
    /// Default presentation preference for generic/collection content
    /// Considers platform capabilities and screen size
    /// Returns a PresentationPreference that can be used with Layer 1 functions
    func defaultPresentationPreference(deviceType: DeviceType) -> PresentationPreference {
        switch self {
        case .macOS, .visionOS:
            return .grid
        case .iOS:
            return deviceType == .pad ? .grid : .list
        case .watchOS, .tvOS:
            return .list
        }
    }
    
    /// Default presentation preference for media content
    func defaultMediaPresentationPreference(deviceType: DeviceType) -> PresentationPreference {
        switch self {
        case .visionOS:
            return .coverFlow  // Spatial interface prefers coverflow
        case .macOS:
            return .cards  // Desktop prefers hover-expandable cards
        case .iOS:
            return deviceType == .pad ? .cards : .automatic
        case .watchOS, .tvOS:
            return .list  // Constrained interfaces prefer lists
        }
    }
    
    /// Default presentation preference for navigation content
    func defaultNavigationPresentationPreference() -> PresentationPreference {
        switch self {
        case .visionOS:
            return .coverFlow
        case .macOS, .iOS:
            return .masonry
        case .watchOS, .tvOS:
            return .grid
        }
    }
    
    // MARK: - Count Threshold Properties
    
    /// Count threshold for switching between small and large collection presentation
    /// Used in count-aware automatic presentation behavior
    func countThreshold(dataType: DataTypeHint, deviceType: DeviceType) -> Int {
        // Base threshold by content type
        let baseThreshold: Int
        switch dataType {
        case .media:
            baseThreshold = 15  // Media handled separately
        case .navigation:
            baseThreshold = 6  // Navigation handled separately
        case .generic, .collection:
            baseThreshold = 8
        default:
            baseThreshold = 8
        }
        
        // Adjust by platform/device
        switch (self, deviceType) {
        case (.macOS, _), (.iOS, .pad):
            return baseThreshold + 4  // More screen space
        case (.iOS, .phone):
            return baseThreshold
        case (.watchOS, _), (.tvOS, _):
            return 3  // Always prefer list
        default:
            return baseThreshold
        }
    }
    
    // MARK: - Navigation Properties
    
    /// Default navigation style for this platform
    var defaultNavigationStyle: NavigationStyle {
        switch self {
        case .macOS, .visionOS:
            return .splitView
        case .iOS:
            return .stack
        case .watchOS, .tvOS:
            return .stack
        }
    }
    
    // MARK: - HIG Compliance Properties
    
    /// Whether this platform supports AssistiveTouch
    /// AssistiveTouch is only available on touch-first platforms
    var supportsAssistiveTouch: Bool {
        switch self {
        case .iOS, .watchOS:
            return true
        case .macOS, .tvOS, .visionOS:
            return false
        }
    }
    
    /// Default safe area insets for this platform (points)
    var defaultSafeAreaInsets: EdgeInsets {
        switch self {
        case .iOS:
            return EdgeInsets(top: 44, leading: 0, bottom: 34, trailing: 0)  // Status bar + home indicator
        case .macOS:
            return EdgeInsets(top: 22, leading: 0, bottom: 0, trailing: 0)  // Menu bar
        case .watchOS:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)  // Full screen
        case .tvOS:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)  // Full screen
        case .visionOS:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)  // Spatial interface
        }
    }
    
    // MARK: - Animation Properties
    
    /// Default animation duration for this platform (seconds)
    var defaultAnimationDuration: TimeInterval {
        switch self {
        case .iOS:
            return 0.3
        case .macOS:
            return 0.25
        case .watchOS:
            return 0.15  // Very fast for watch
        case .tvOS:
            return 0.4  // Slower for TV viewing
        case .visionOS:
            return 0.4  // Slower for spatial interface
        }
    }
    
    /// Default animation easing for this platform
    var defaultAnimationEasing: Animation {
        switch self {
        case .iOS:
            return .easeInOut(duration: defaultAnimationDuration)
        case .macOS:
            return .easeInOut(duration: defaultAnimationDuration)
        case .watchOS:
            return .easeInOut(duration: defaultAnimationDuration)
        case .tvOS:
            return .easeInOut(duration: defaultAnimationDuration)
        case .visionOS:
            return .easeInOut(duration: defaultAnimationDuration)
        }
    }
    
    // MARK: - OCR Properties
    
    /// Supported OCR languages for this platform
    var supportedOCRLanguages: [OCRLanguage] {
        switch self {
        case .iOS, .macOS, .visionOS:
            return [.english, .spanish, .french, .german, .italian, .portuguese, .chinese, .japanese, .korean, .arabic, .russian]
        case .watchOS, .tvOS:
            return [.english, .spanish, .french, .german]  // Limited processing power
        }
    }
    
    /// Default OCR processing mode for this platform
    func defaultOCRProcessingMode(requiresNeuralEngine: Bool) -> OCRProcessingMode {
        switch self {
        case .iOS:
            return requiresNeuralEngine ? .neural : .standard
        case .macOS:
            return requiresNeuralEngine ? .accurate : .standard  // macOS doesn't have neural engine
        case .watchOS:
            return .fast  // Limited processing power
        case .tvOS:
            return .standard
        case .visionOS:
            return .neural  // visionOS can handle neural processing for spatial UI
        }
    }
}

// MARK: - Platform Strategy Helper Functions

/// Get platform-specific value using strategy pattern
/// Reduces need for switch statements throughout codebase
public struct PlatformStrategy {
    
    /// Get minimum touch target for platform
    public static func minTouchTarget(for platform: SixLayerPlatform) -> CGFloat {
        return platform.minTouchTarget
    }
    
    /// Get hover delay for platform
    public static func hoverDelay(for platform: SixLayerPlatform) -> TimeInterval {
        return platform.hoverDelay
    }
    
    /// Get default presentation preference for platform and device type
    public static func defaultPresentationPreference(
        for platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> PresentationPreference {
        return platform.defaultPresentationPreference(deviceType: deviceType)
    }
    
    /// Get default navigation style for platform
    public static func defaultNavigationStyle(for platform: SixLayerPlatform) -> NavigationStyle {
        return platform.defaultNavigationStyle
    }
    
    /// Check if platform supports AssistiveTouch
    public static func supportsAssistiveTouch(for platform: SixLayerPlatform) -> Bool {
        return platform.supportsAssistiveTouch
    }
}

