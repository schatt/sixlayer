import Foundation
import SwiftUI

// MARK: - HIG Visual Design System

/// Visual design system providing HIG-compliant visual design categories
public struct HIGVisualDesignSystem {
    public let platform: SixLayerPlatform
    public let animationSystem: HIGAnimationSystem
    public let shadowSystem: HIGShadowSystem
    public let cornerRadiusSystem: HIGCornerRadiusSystem
    public let borderWidthSystem: HIGBorderWidthSystem
    public let opacitySystem: HIGOpacitySystem
    public let blurSystem: HIGBlurSystem
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        self.animationSystem = HIGAnimationSystem(for: platform)
        self.shadowSystem = HIGShadowSystem(for: platform)
        self.cornerRadiusSystem = HIGCornerRadiusSystem(for: platform)
        self.borderWidthSystem = HIGBorderWidthSystem(for: platform)
        self.opacitySystem = HIGOpacitySystem(for: platform)
        self.blurSystem = HIGBlurSystem(for: platform)
    }
}

// MARK: - Animation System

/// Animation category system providing HIG-compliant animation options
public struct HIGAnimationSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get animation for a specific category
    public func animation(for category: HIGAnimationCategory) -> Animation {
        switch category {
        case .easeInOut:
            return .easeInOut(duration: defaultDuration)
        case .spring:
            return .spring(response: defaultSpringResponse, dampingFraction: defaultDampingFraction)
        case .custom(let timingFunction):
            return .timingCurve(
                timingFunction.controlPoint1.x,
                timingFunction.controlPoint1.y,
                timingFunction.controlPoint2.x,
                timingFunction.controlPoint2.y,
                duration: defaultDuration
            )
        }
    }
    
    /// Get default animation for platform
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    public var defaultAnimation: Animation {
        switch platform {
        case .iOS:
            // iOS prefers spring animations
            return .spring(response: platform.defaultSpringResponse, dampingFraction: platform.defaultDampingFraction)
        case .macOS:
            // macOS prefers easeInOut
            return .easeInOut(duration: platform.defaultAnimationDuration)
        case .watchOS, .tvOS, .visionOS:
            // Other platforms use easeInOut
            return .easeInOut(duration: platform.defaultAnimationDuration)
        }
    }
    
    private var defaultDuration: Double {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        return platform.defaultAnimationDuration
    }
    
    private var defaultSpringResponse: Double {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        return platform.defaultSpringResponse
    }
    
    private var defaultDampingFraction: Double {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        return platform.defaultDampingFraction
    }
}

/// Animation category enum
public enum HIGAnimationCategory: Equatable {
    case easeInOut
    case spring
    case custom(TimingFunction)
    
    /// Default animation category for platform
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    public static func `default`(for platform: SixLayerPlatform) -> HIGAnimationCategory {
        return platform.defaultAnimationCategory
    }
}

/// Timing function for custom animations
public struct TimingFunction: Sendable, Equatable {
    public let controlPoint1: CGPoint
    public let controlPoint2: CGPoint
    
    public init(controlPoint1: CGPoint, controlPoint2: CGPoint) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
    }
    
    public static let easeIn = TimingFunction(
        controlPoint1: CGPoint(x: 0.42, y: 0.0),
        controlPoint2: CGPoint(x: 1.0, y: 1.0)
    )
    
    public static let easeOut = TimingFunction(
        controlPoint1: CGPoint(x: 0.0, y: 0.0),
        controlPoint2: CGPoint(x: 0.58, y: 1.0)
    )
    
    public static let easeInOut = TimingFunction(
        controlPoint1: CGPoint(x: 0.42, y: 0.0),
        controlPoint2: CGPoint(x: 0.58, y: 1.0)
    )
}

// MARK: - Shadow System

/// Shadow category system providing HIG-compliant shadow styles
public struct HIGShadowSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get shadow for a specific category
    public func shadow(for category: HIGShadowCategory) -> HIGShadow {
        switch category {
        case .elevated:
            return elevatedShadow
        case .floating:
            return floatingShadow
        case .custom(let radius, let offset, let color):
            return HIGShadow(
                color: color,
                radius: radius,
                offset: offset
            )
        }
    }
    
    private var elevatedShadow: HIGShadow {
        switch platform {
        case .iOS:
            return HIGShadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                offset: CGSize(width: 0, height: 2)
            )
        case .macOS:
            return HIGShadow(
                color: Color.black.opacity(0.08),
                radius: 2,
                offset: CGSize(width: 0, height: 1)
            )
        default:
            return HIGShadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                offset: CGSize(width: 0, height: 2)
            )
        }
    }
    
    private var floatingShadow: HIGShadow {
        switch platform {
        case .iOS:
            return HIGShadow(
                color: Color.black.opacity(0.15),
                radius: 8,
                offset: CGSize(width: 0, height: 4)
            )
        case .macOS:
            return HIGShadow(
                color: Color.black.opacity(0.12),
                radius: 6,
                offset: CGSize(width: 0, height: 3)
            )
        default:
            return HIGShadow(
                color: Color.black.opacity(0.15),
                radius: 8,
                offset: CGSize(width: 0, height: 4)
            )
        }
    }
}

/// Shadow category enum
/// Note: Color does not conform to Equatable, so custom cases cannot be compared
public enum HIGShadowCategory {
    case elevated
    case floating
    case custom(radius: CGFloat, offset: CGSize, color: Color)
}

/// Shadow structure
public struct HIGShadow {
    public let color: Color
    public let radius: CGFloat
    public let offset: CGSize
    
    public init(color: Color, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.offset = offset
    }
}

// MARK: - Corner Radius System

/// Corner radius category system providing HIG-compliant radius values
public struct HIGCornerRadiusSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get corner radius for a specific category
    public func radius(for category: HIGCornerRadiusCategory) -> CGFloat {
        switch category {
        case .small:
            return platformValue(iOS: 8, macOS: 4, default: 8)
        case .medium:
            return platformValue(iOS: 12, macOS: 8, default: 12)
        case .large:
            return platformValue(iOS: 16, macOS: 12, default: 16)
        case .custom(let value):
            return value
        }
    }
    
    /// Helper to get platform-specific CGFloat values
    private func platformValue(iOS: CGFloat, macOS: CGFloat, default defaultValue: CGFloat) -> CGFloat {
        switch platform {
        case .iOS:
            return iOS
        case .macOS:
            return macOS
        default:
            return defaultValue
        }
    }
}

/// Corner radius category enum
public enum HIGCornerRadiusCategory: Equatable {
    case small
    case medium
    case large
    case custom(CGFloat)
}

// MARK: - Border Width System

/// Border width category system providing HIG-compliant border widths
public struct HIGBorderWidthSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get border width for a specific category
    public func width(for category: HIGBorderWidthCategory) -> CGFloat {
        switch category {
        case .thin:
            return 0.5 // Consistent across all platforms
        case .medium:
            return platformValue(iOS: 0.5, macOS: 1.0, default: 0.5)
        case .thick:
            return platformValue(iOS: 1.0, macOS: 2.0, default: 1.0)
        }
    }
    
    /// Helper to get platform-specific CGFloat values
    private func platformValue(iOS: CGFloat, macOS: CGFloat, default defaultValue: CGFloat) -> CGFloat {
        switch platform {
        case .iOS:
            return iOS
        case .macOS:
            return macOS
        default:
            return defaultValue
        }
    }
}

/// Border width category enum
public enum HIGBorderWidthCategory: CaseIterable, Equatable {
    case thin
    case medium
    case thick
}

// MARK: - Opacity System

/// Opacity category system providing HIG-compliant opacity levels
/// Note: Opacity values are consistent across platforms, so platform parameter is not used
public struct HIGOpacitySystem {
    public init(for platform: SixLayerPlatform) {
        // Opacity values are platform-independent, but we accept platform for consistency
        // with other design systems
    }
    
    /// Get opacity for a specific category
    public func opacity(for category: HIGOpacityCategory) -> Double {
        switch category {
        case .primary:
            return 1.0
        case .secondary:
            return 0.7
        case .tertiary:
            return 0.4
        case .custom(let value):
            return value
        }
    }
}

/// Opacity category enum
public enum HIGOpacityCategory: Equatable {
    case primary
    case secondary
    case tertiary
    case custom(Double)
}

// MARK: - Blur System

/// Blur category system providing HIG-compliant blur effects
public struct HIGBlurSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get blur for a specific category
    public func blur(for category: HIGBlurCategory) -> HIGBlur {
        switch category {
        case .light:
            return HIGBlur(radius: platformValue(iOS: 5, macOS: 4, default: 5))
        case .medium:
            return HIGBlur(radius: platformValue(iOS: 10, macOS: 8, default: 10))
        case .heavy:
            return HIGBlur(radius: platformValue(iOS: 20, macOS: 16, default: 20))
        case .custom(let radius):
            return HIGBlur(radius: radius)
        }
    }
    
    /// Helper to get platform-specific CGFloat values
    private func platformValue(iOS: CGFloat, macOS: CGFloat, default defaultValue: CGFloat) -> CGFloat {
        switch platform {
        case .iOS:
            return iOS
        case .macOS:
            return macOS
        default:
            return defaultValue
        }
    }
}

/// Blur category enum
public enum HIGBlurCategory: Equatable {
    case light
    case medium
    case heavy
    case custom(radius: CGFloat)
}

/// Blur structure
public struct HIGBlur {
    public let radius: CGFloat
    
    public init(radius: CGFloat) {
        self.radius = radius
    }
}

