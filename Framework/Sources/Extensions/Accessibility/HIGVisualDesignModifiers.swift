import Foundation
import SwiftUI

// MARK: - Animation Category Modifier

/// Modifier that applies HIG-compliant animation category
public struct HIGAnimationCategoryModifier: ViewModifier {
    let category: HIGAnimationCategory
    let animationSystem: HIGAnimationSystem
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    public func body(content: Content) -> some View {
        let reduceMotion = accessibilityReduceMotion
            || PlatformReduceMotionPreference.isReduceMotionEnabled
        return content
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                } else {
                    transaction.animation = animationSystem.animation(for: category)
                }
            }
            .automaticCompliance()
    }
}

// MARK: - Shadow Category Modifier

/// Modifier that applies HIG-compliant shadow category
public struct HIGShadowCategoryModifier: ViewModifier {
    let category: HIGShadowCategory
    let shadowSystem: HIGShadowSystem
    
    public func body(content: Content) -> some View {
        let shadow = shadowSystem.shadow(for: category)
        return content
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.offset.width,
                y: shadow.offset.height
            )
            .automaticCompliance()
    }
}

// MARK: - Corner Radius Category Modifier

/// Modifier that applies HIG-compliant corner radius category
public struct HIGCornerRadiusCategoryModifier: ViewModifier {
    let category: HIGCornerRadiusCategory
    let cornerRadiusSystem: HIGCornerRadiusSystem
    
    public func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadiusSystem.radius(for: category)))
            .automaticCompliance()
    }
}

// MARK: - Border Width Category Modifier

/// Modifier that applies HIG-compliant border width category
public struct HIGBorderWidthCategoryModifier: ViewModifier {
    let category: HIGBorderWidthCategory
    let borderWidthSystem: HIGBorderWidthSystem
    let color: Color
    
    public init(category: HIGBorderWidthCategory, borderWidthSystem: HIGBorderWidthSystem, color: Color = .separator) {
        self.category = category
        self.borderWidthSystem = borderWidthSystem
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: borderWidthSystem.width(for: category))
            )
            .automaticCompliance()
    }
}

// MARK: - Opacity Category Modifier

/// Modifier that applies HIG-compliant opacity category
public struct HIGOpacityCategoryModifier: ViewModifier {
    let category: HIGOpacityCategory
    let opacitySystem: HIGOpacitySystem
    
    public func body(content: Content) -> some View {
        content
            .opacity(opacitySystem.opacity(for: category))
            .automaticCompliance()
    }
}

// MARK: - Blur Category Modifier

/// Modifier that applies HIG-compliant blur category
public struct HIGBlurCategoryModifier: ViewModifier {
    let category: HIGBlurCategory
    let blurSystem: HIGBlurSystem
    
    public func body(content: Content) -> some View {
        let blur = blurSystem.blur(for: category)
        return content
            .blur(radius: blur.radius)
            .automaticCompliance()
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply HIG-compliant animation category
    func higAnimationCategory(_ category: HIGAnimationCategory, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGAnimationCategoryModifier(
            category: category,
            animationSystem: HIGAnimationSystem(for: targetPlatform)
        ))
    }
    
    /// Apply HIG-compliant shadow category
    func higShadowCategory(_ category: HIGShadowCategory, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGShadowCategoryModifier(
            category: category,
            shadowSystem: HIGShadowSystem(for: targetPlatform)
        ))
    }
    
    /// Apply HIG-compliant corner radius category
    func higCornerRadiusCategory(_ category: HIGCornerRadiusCategory, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGCornerRadiusCategoryModifier(
            category: category,
            cornerRadiusSystem: HIGCornerRadiusSystem(for: targetPlatform)
        ))
    }
    
    /// Apply HIG-compliant border width category
    func higBorderWidthCategory(_ category: HIGBorderWidthCategory, color: Color = .separator, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGBorderWidthCategoryModifier(
            category: category,
            borderWidthSystem: HIGBorderWidthSystem(for: targetPlatform),
            color: color
        ))
    }
    
    /// Apply HIG-compliant opacity category
    func higOpacityCategory(_ category: HIGOpacityCategory, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGOpacityCategoryModifier(
            category: category,
            opacitySystem: HIGOpacitySystem(for: targetPlatform)
        ))
    }
    
    /// Apply HIG-compliant blur category
    func higBlurCategory(_ category: HIGBlurCategory, for platform: SixLayerPlatform? = nil) -> some View {
        let targetPlatform = platform ?? SixLayerPlatform.current
        return self.modifier(HIGBlurCategoryModifier(
            category: category,
            blurSystem: HIGBlurSystem(for: targetPlatform)
        ))
    }
}

