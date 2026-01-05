import SwiftUI

// MARK: - Layer 5: Platform Optimization for Intelligent Card Expansion

/// Platform-specific optimization configuration
public struct CardExpansionPlatformConfig: Sendable {
    public let supportsHapticFeedback: Bool
    public let supportsHover: Bool
    public let supportsTouch: Bool
    public let supportsVoiceOver: Bool
    public let supportsSwitchControl: Bool
    public let supportsAssistiveTouch: Bool
    public let minTouchTarget: CGFloat
    public let hoverDelay: TimeInterval
    public let animationEasing: Animation
    
    public init(
        supportsHapticFeedback: Bool = false,
        supportsHover: Bool = false,
        supportsTouch: Bool = true,
        supportsVoiceOver: Bool = true,
        supportsSwitchControl: Bool = true,
        supportsAssistiveTouch: Bool = true,
        minTouchTarget: CGFloat = 44,
        hoverDelay: TimeInterval = 0.1,
        animationEasing: Animation = .easeInOut(duration: 0.3)
    ) {
        self.supportsHapticFeedback = supportsHapticFeedback
        self.supportsHover = supportsHover
        self.supportsTouch = supportsTouch
        self.supportsVoiceOver = supportsVoiceOver
        self.supportsSwitchControl = supportsSwitchControl
        self.supportsAssistiveTouch = supportsAssistiveTouch
        self.minTouchTarget = minTouchTarget
        self.hoverDelay = hoverDelay
        self.animationEasing = animationEasing
    }
}

/// Get platform-specific configuration for card expansion
@MainActor
public func getCardExpansionPlatformConfig() -> CardExpansionPlatformConfig {
    // Use RuntimeCapabilityDetection.currentPlatform to respect test platform settings
    let platform = RuntimeCapabilityDetection.currentPlatform
    let deviceType = SixLayerPlatform.deviceType
    
    switch platform {
    case .iOS:
        return iOSCardExpansionConfig(deviceType: deviceType)
    case .macOS:
        return macOSCardExpansionConfig()
    case .visionOS:
        return visionOSCardExpansionConfig()
    case .watchOS:
        return watchOSCardExpansionConfig()
    case .tvOS:
        return tvOSCardExpansionConfig()
    }
}

/// iOS-specific configuration using runtime capability detection
@MainActor
private func iOSCardExpansionConfig(deviceType: DeviceType) -> CardExpansionPlatformConfig {
    switch deviceType {
    case .phone:
        return CardExpansionPlatformConfig(
            supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
            supportsHover: RuntimeCapabilityDetection.supportsHover,
            supportsTouch: RuntimeCapabilityDetection.supportsTouch,
            supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
            supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
            supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
            minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
            hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
            animationEasing: .easeInOut(duration: 0.25)
        )
    case .pad:
        return CardExpansionPlatformConfig(
            supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
            supportsHover: RuntimeCapabilityDetection.supportsHover,
            supportsTouch: RuntimeCapabilityDetection.supportsTouch,
            supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
            supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
            supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
            minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
            hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
            animationEasing: .easeInOut(duration: 0.3)
        )
    default:
        return CardExpansionPlatformConfig()
    }
}

/// macOS-specific configuration using runtime capability detection
@MainActor
private func macOSCardExpansionConfig() -> CardExpansionPlatformConfig {
    return CardExpansionPlatformConfig(
        supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
        supportsHover: RuntimeCapabilityDetection.supportsHover,
        supportsTouch: RuntimeCapabilityDetection.supportsTouch,
        supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
        supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
        supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
        minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
        hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
        animationEasing: .easeInOut(duration: 0.3)
    )
}

/// visionOS-specific configuration using runtime capability detection
@MainActor
private func visionOSCardExpansionConfig() -> CardExpansionPlatformConfig {
    return CardExpansionPlatformConfig(
        supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
        supportsHover: RuntimeCapabilityDetection.supportsHover,
        supportsTouch: RuntimeCapabilityDetection.supportsTouch,
        supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
        supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
        supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
        minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
        hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
        animationEasing: .easeInOut(duration: 0.4) // Slower for spatial interface
    )
}

/// watchOS-specific configuration using runtime capability detection
@MainActor
private func watchOSCardExpansionConfig() -> CardExpansionPlatformConfig {
    return CardExpansionPlatformConfig(
        supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
        supportsHover: RuntimeCapabilityDetection.supportsHover,
        supportsTouch: RuntimeCapabilityDetection.supportsTouch,
        supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
        supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
        supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
        minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
        hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
        animationEasing: .easeInOut(duration: 0.15) // Very fast for watch
    )
}

/// tvOS-specific configuration using runtime capability detection
@MainActor
private func tvOSCardExpansionConfig() -> CardExpansionPlatformConfig {
    return CardExpansionPlatformConfig(
        supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
        supportsHover: RuntimeCapabilityDetection.supportsHover,
        supportsTouch: RuntimeCapabilityDetection.supportsTouch,
        supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
        supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
        supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
        minTouchTarget: RuntimeCapabilityDetection.minTouchTarget, // Platform-native touch target size
        hoverDelay: RuntimeCapabilityDetection.hoverDelay, // Platform-native hover delay
        animationEasing: .easeInOut(duration: 0.4) // Slower for TV viewing
    )
}

// MARK: - Performance Optimization

/// Performance configuration for card expansion
public struct CardExpansionPerformanceConfig {
    public let targetFrameRate: Int
    public let maxAnimationDuration: TimeInterval
    public let supportsSmoothAnimations: Bool
    public let memoryOptimization: Bool
    public let lazyLoading: Bool
    
    public init(
        targetFrameRate: Int = 60,
        maxAnimationDuration: TimeInterval = 0.3,
        supportsSmoothAnimations: Bool = true,
        memoryOptimization: Bool = true,
        lazyLoading: Bool = true
    ) {
        self.targetFrameRate = targetFrameRate
        self.maxAnimationDuration = maxAnimationDuration
        self.supportsSmoothAnimations = supportsSmoothAnimations
        self.memoryOptimization = memoryOptimization
        self.lazyLoading = lazyLoading
    }
}

/// Get performance configuration for current platform
@MainActor
public func getCardExpansionPerformanceConfig() -> CardExpansionPerformanceConfig {
    // Use RuntimeCapabilityDetection.currentPlatform to respect test platform settings
    let platform = RuntimeCapabilityDetection.currentPlatform
    let deviceType = SixLayerPlatform.deviceType
    
    switch platform {
    case .iOS:
        return iOSPerformanceConfig(deviceType: deviceType)
    case .macOS:
        return macOSPerformanceConfig()
    case .visionOS:
        return visionOSPerformanceConfig()
    case .watchOS:
        return watchOSPerformanceConfig()
    case .tvOS:
        return tvOSPerformanceConfig()
    }
}

/// iOS performance configuration
private func iOSPerformanceConfig(deviceType: DeviceType) -> CardExpansionPerformanceConfig {
    switch deviceType {
    case .phone:
        return CardExpansionPerformanceConfig(
            targetFrameRate: 60,
            maxAnimationDuration: 0.25,
            supportsSmoothAnimations: true,
            memoryOptimization: true,
            lazyLoading: true
        )
    case .pad:
        return CardExpansionPerformanceConfig(
            targetFrameRate: 60,
            maxAnimationDuration: 0.3,
            supportsSmoothAnimations: true,
            memoryOptimization: true,
            lazyLoading: true
        )
    default:
        return CardExpansionPerformanceConfig()
    }
}

/// macOS performance configuration
private func macOSPerformanceConfig() -> CardExpansionPerformanceConfig {
    return CardExpansionPerformanceConfig(
        targetFrameRate: 60,
        maxAnimationDuration: 0.3,
        supportsSmoothAnimations: true,
        memoryOptimization: true,
        lazyLoading: true
    )
}

/// visionOS performance configuration
private func visionOSPerformanceConfig() -> CardExpansionPerformanceConfig {
    return CardExpansionPerformanceConfig(
        targetFrameRate: 90, // Higher frame rate for spatial interface
        maxAnimationDuration: 0.4,
        supportsSmoothAnimations: true,
        memoryOptimization: true,
        lazyLoading: true
    )
}

/// watchOS performance configuration
private func watchOSPerformanceConfig() -> CardExpansionPerformanceConfig {
    return CardExpansionPerformanceConfig(
        targetFrameRate: 60,
        maxAnimationDuration: 0.15,
        supportsSmoothAnimations: true,
        memoryOptimization: true,
        lazyLoading: true
    )
}

/// tvOS performance configuration
private func tvOSPerformanceConfig() -> CardExpansionPerformanceConfig {
    return CardExpansionPerformanceConfig(
        targetFrameRate: 60,
        maxAnimationDuration: 0.4,
        supportsSmoothAnimations: true,
        memoryOptimization: true,
        lazyLoading: true
    )
}

// MARK: - Accessibility Optimization

/// Accessibility configuration for card expansion
public struct CardExpansionAccessibilityConfig {
    public let supportsVoiceOver: Bool
    public let supportsSwitchControl: Bool
    public let supportsAssistiveTouch: Bool
    public let supportsReduceMotion: Bool
    public let supportsHighContrast: Bool
    public let supportsDynamicType: Bool
    public let announcementDelay: TimeInterval
    public let focusManagement: Bool
    
    public init(
        supportsVoiceOver: Bool = true,
        supportsSwitchControl: Bool = true,
        supportsAssistiveTouch: Bool = true,
        supportsReduceMotion: Bool = true,
        supportsHighContrast: Bool = true,
        supportsDynamicType: Bool = true,
        announcementDelay: TimeInterval = 0.5,
        focusManagement: Bool = true
    ) {
        self.supportsVoiceOver = supportsVoiceOver
        self.supportsSwitchControl = supportsSwitchControl
        self.supportsAssistiveTouch = supportsAssistiveTouch
        self.supportsReduceMotion = supportsReduceMotion
        self.supportsHighContrast = supportsHighContrast
        self.supportsDynamicType = supportsDynamicType
        self.announcementDelay = announcementDelay
        self.focusManagement = focusManagement
    }
}

/// Get accessibility configuration for current platform
@MainActor
public func getCardExpansionAccessibilityConfig() -> CardExpansionAccessibilityConfig {
    // Use RuntimeCapabilityDetection to respect capability overrides and runtime detection
    let platform = RuntimeCapabilityDetection.currentPlatform
    
    // Use runtime detection for accessibility features (respects capability overrides)
    let supportsVoiceOver = RuntimeCapabilityDetection.supportsVoiceOver
    let supportsSwitchControl = RuntimeCapabilityDetection.supportsSwitchControl
    let supportsAssistiveTouch = RuntimeCapabilityDetection.supportsAssistiveTouch
    
    // Use PlatformStrategy for platform-specific announcement delays (Issue #140)
    let announcementDelay = platform.defaultAnnouncementDelay
    
    return CardExpansionAccessibilityConfig(
        supportsVoiceOver: supportsVoiceOver,
        supportsSwitchControl: supportsSwitchControl,
        supportsAssistiveTouch: supportsAssistiveTouch,
        supportsReduceMotion: true,
        supportsHighContrast: true,
        supportsDynamicType: true,
        announcementDelay: announcementDelay,
        focusManagement: true
    )
}
