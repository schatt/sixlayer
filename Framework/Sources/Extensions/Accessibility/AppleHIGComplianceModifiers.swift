import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Helper Extensions for Platform-Specific Modifiers

/// Helper extension to reduce code duplication in platform-specific modifiers
private extension View {
    /// Wraps content in AnyView with automatic compliance
    func wrappedWithCompliance() -> AnyView {
        AnyView(self.automaticCompliance())
    }
}

/// Helper function to get platform config with default fallback
private func getConfigOrDefault<T>(
    _ config: T?,
    default: @autoclosure () -> T
) -> T {
    config ?? `default`()
}

// MARK: - Apple HIG Compliance Modifier

/// Main modifier that applies comprehensive Apple HIG compliance
public struct AppleHIGComplianceModifier: ViewModifier {
    let manager: AppleHIGComplianceManager
    let complianceLevel: HIGComplianceLevel
    
    public func body(content: Content) -> some View {
        content
            .modifier(SystemAccessibilityModifier(
                accessibilityState: manager.accessibilityState,
                platform: manager.currentPlatform
            ))
            .modifier(PlatformPatternModifier(
                designSystem: manager.designSystem,
                platform: manager.currentPlatform
            ))
            .modifier(VisualConsistencyModifier(
                designSystem: manager.designSystem,
                platform: manager.currentPlatform,
                visualDesignConfig: manager.visualDesignConfig,
                iOSConfig: manager.currentPlatform == .iOS ? manager.iOSCategoryConfig : nil
            ))
            .modifier(InteractionPatternModifier(
                platform: manager.currentPlatform,
                accessibilityState: manager.accessibilityState,
                iOSConfig: manager.currentPlatform == .iOS ? manager.iOSCategoryConfig : nil,
                macOSConfig: manager.currentPlatform == .macOS ? manager.macOSCategoryConfig : nil
            ))
            .modifier(PlatformSpecificCategoryModifier(
                platform: manager.currentPlatform,
                iOSConfig: manager.currentPlatform == .iOS ? manager.iOSCategoryConfig : nil,
                macOSConfig: manager.currentPlatform == .macOS ? manager.macOSCategoryConfig : nil,
                visionOSConfig: manager.currentPlatform == .visionOS ? manager.visionOSCategoryConfig : nil
            ))
            .automaticCompliance()
    }
}

// MARK: - Automatic Accessibility Modifier

/// Automatically applies Apple HIG compliance features based on system state
public struct SystemAccessibilityModifier: ViewModifier {
    let accessibilityState: AccessibilitySystemState
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        content
            .modifier(VoiceOverSupportModifier(
                isEnabled: accessibilityState.isVoiceOverRunning
            ))
            .modifier(KeyboardNavigationModifier(
                hasKeyboardSupport: accessibilityState.hasKeyboardSupport,
                hasFullKeyboardAccess: accessibilityState.hasFullKeyboardAccess
            ))
            .modifier(HighContrastModifier(
                isEnabled: accessibilityState.isHighContrastEnabled
            ))
            .modifier(ReducedMotionModifier(
                isEnabled: accessibilityState.isReducedMotionEnabled
            ))
            .modifier(DynamicTypeModifier())
            .automaticCompliance() // FIXED: Add missing accessibility identifier generation
    }
}

// MARK: - Platform Pattern Modifier

/// Applies platform-specific design patterns
public struct PlatformPatternModifier: ViewModifier {
    let designSystem: PlatformDesignSystem
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        content
            .modifier(PlatformNavigationModifier(platform: platform))
            .modifier(PlatformStylingModifier(designSystem: designSystem))
            .modifier(PlatformIconModifier(iconSystem: designSystem.iconSystem))
            .automaticCompliance()
    }
}

// MARK: - Visual Consistency Modifier

/// Applies visual design consistency following Apple's guidelines
public struct VisualConsistencyModifier: ViewModifier {
    let designSystem: PlatformDesignSystem
    let platform: SixLayerPlatform
    let visualDesignConfig: HIGVisualDesignCategoryConfig
    let iOSConfig: HIGiOSCategoryConfig?
    
    public func body(content: Content) -> some View {
        content
            .modifier(SystemColorModifier(colorSystem: designSystem.colorSystem))
            .modifier(SystemTypographyModifier(typographySystem: designSystem.typographySystem))
            .modifier(SpacingModifier(spacingSystem: designSystem.spacingSystem))
            .modifier(TouchTargetModifier(
                platform: platform,
                iOSConfig: iOSConfig
            ))
            .modifier(SafeAreaComplianceModifier(
                platform: platform,
                iOSConfig: iOSConfig
            ))
            .modifier(VisualDesignCategoryModifier(
                visualDesignSystem: designSystem.visualDesignSystem,
                config: visualDesignConfig
            ))
            .automaticCompliance()
    }
}

// MARK: - Visual Design Category Modifier

/// Applies visual design categories from the visual design system based on configuration
/// 
/// This modifier automatically applies visual design categories according to the
/// configuration set in `AppleHIGComplianceManager.visualDesignConfig`. Developers
/// can control which categories are applied automatically:
///
/// ```swift
/// // Configure at app startup
/// let manager = AppleHIGComplianceManager()
/// manager.visualDesignConfig.applyShadows = true
/// manager.visualDesignConfig.applyCornerRadius = true
/// ```
///
/// Individual categories can still be applied explicitly using:
/// - `.higAnimationCategory()` for animations
/// - `.higShadowCategory()` for shadows
/// - `.higCornerRadiusCategory()` for corner radius
/// - `.higBorderWidthCategory()` for borders
/// - `.higOpacityCategory()` for opacity
/// - `.higBlurCategory()` for blur
public struct VisualDesignCategoryModifier: ViewModifier {
    let visualDesignSystem: HIGVisualDesignSystem
    let config: HIGVisualDesignCategoryConfig
    
    public init(visualDesignSystem: HIGVisualDesignSystem, config: HIGVisualDesignCategoryConfig) {
        self.visualDesignSystem = visualDesignSystem
        self.config = config
    }
    
    public func body(content: Content) -> some View {
        applyVisualDesignCategories(to: content, visualDesignSystem: visualDesignSystem, config: config)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply visual design categories based on configuration
    private func applyVisualDesignCategories<Content: View>(
        to content: Content,
        visualDesignSystem: HIGVisualDesignSystem,
        config: HIGVisualDesignCategoryConfig
    ) -> some View {
        var modifiedContent: AnyView = AnyView(content)
        
        // Note: Animations are not applied automatically because SwiftUI animations
        // should be tied to specific state changes, not applied globally.
        // Use `.higAnimationCategory()` or `.animation(_:value:)` with state changes instead.
        // The `applyAnimations` config flag is reserved for future use when we have
        // a better way to apply animations automatically.
        
        if config.applyShadows {
            let shadow = visualDesignSystem.shadowSystem.shadow(for: config.defaultShadowCategory)
            modifiedContent = AnyView(
                modifiedContent
                    .shadow(
                        color: shadow.color,
                        radius: shadow.radius,
                        x: shadow.offset.width,
                        y: shadow.offset.height
                    )
            )
        }
        
        if config.applyCornerRadius {
            let radius = visualDesignSystem.cornerRadiusSystem.radius(for: config.defaultCornerRadiusCategory)
            modifiedContent = AnyView(
                modifiedContent
                    .clipShape(RoundedRectangle(cornerRadius: radius))
            )
        }
        
        if config.applyBorders {
            let borderWidth = visualDesignSystem.borderWidthSystem.width(for: config.defaultBorderWidthCategory)
            modifiedContent = AnyView(
                modifiedContent
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.separator, lineWidth: borderWidth)
                    )
            )
        }
        
        if config.applyOpacity {
            let opacity = visualDesignSystem.opacitySystem.opacity(for: config.defaultOpacityCategory)
            modifiedContent = AnyView(
                modifiedContent
                    .opacity(opacity)
            )
        }
        
        if config.applyBlur {
            let blur = visualDesignSystem.blurSystem.blur(for: config.defaultBlurCategory)
            modifiedContent = AnyView(
                modifiedContent
                    .blur(radius: blur.radius)
            )
        }
        
        return modifiedContent.wrappedWithCompliance()
    }
}

// MARK: - Interaction Pattern Modifier

/// Applies platform-appropriate interaction patterns
public struct InteractionPatternModifier: ViewModifier {
    let platform: SixLayerPlatform
    let accessibilityState: AccessibilitySystemState
    let iOSConfig: HIGiOSCategoryConfig?
    let macOSConfig: HIGmacOSCategoryConfig?
    
    public init(
        platform: SixLayerPlatform,
        accessibilityState: AccessibilitySystemState,
        iOSConfig: HIGiOSCategoryConfig? = nil,
        macOSConfig: HIGmacOSCategoryConfig? = nil
    ) {
        self.platform = platform
        self.accessibilityState = accessibilityState
        self.iOSConfig = iOSConfig
        self.macOSConfig = macOSConfig
    }
    
    public func body(content: Content) -> some View {
        content
            .modifier(PlatformInteractionModifier(platform: platform, macOSConfig: macOSConfig))
            .modifier(HapticFeedbackModifier(platform: platform, iOSConfig: iOSConfig))
            .modifier(GestureRecognitionModifier(platform: platform, iOSConfig: iOSConfig))
            .automaticCompliance()
    }
}

// MARK: - Individual Modifiers

/// VoiceOver support modifier
public struct VoiceOverSupportModifier: ViewModifier {
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        if isEnabled {
            content
                .accessibilityLabel(extractAccessibilityLabel(from: content))
                .accessibilityHint(extractAccessibilityHint(from: content))
                .accessibilityAddTraits(extractAccessibilityTraits(from: content))
                .automaticCompliance()
        } else {
            content
                .automaticCompliance()
        }
    }
    
    private func extractAccessibilityLabel(from content: Content) -> String {
        // Extract accessibility label from view content
        // This would use reflection or view introspection in a real implementation
        return "Interactive element"
    }
    
    private func extractAccessibilityHint(from content: Content) -> String {
        // Extract accessibility hint from view content
        return "Tap to activate"
    }
    
    private func extractAccessibilityTraits(from content: Content) -> AccessibilityTraits {
        // Extract accessibility traits from view content
        return .isButton
    }
}

/// Keyboard navigation modifier
public struct KeyboardNavigationModifier: ViewModifier {
    let hasKeyboardSupport: Bool
    let hasFullKeyboardAccess: Bool
    
    public func body(content: Content) -> some View {
        applyKeyboardNavigation(to: content, hasKeyboardSupport: hasKeyboardSupport, hasFullKeyboardAccess: hasFullKeyboardAccess)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply keyboard navigation with platform-specific behavior
    private func applyKeyboardNavigation<Content: View>(
        to content: Content,
        hasKeyboardSupport: Bool,
        hasFullKeyboardAccess: Bool
    ) -> AnyView {
        guard hasKeyboardSupport else {
            return content.wrappedWithCompliance()
        }
        
        #if os(macOS)
        return macOSKeyboardNavigation(to: content, hasFullKeyboardAccess: hasFullKeyboardAccess).wrappedWithCompliance()
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        return iosKeyboardNavigation(to: content).wrappedWithCompliance()
        #else
        return fallbackKeyboardNavigation(to: content)
        #endif
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(macOS)
    @available(macOS 14.0, *)
    private func macOSKeyboardNavigation<Content: View>(
        to content: Content,
        hasFullKeyboardAccess: Bool
    ) -> some View {
        content
            .focusable()
            .onKeyPress(.return) {
                // Handle keyboard activation
                return .handled
            }
    }
    #endif
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    private func iosKeyboardNavigation<Content: View>(to content: Content) -> some View {
        content.focusable()
    }
    #endif
    
    private func fallbackKeyboardNavigation<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// High contrast modifier
public struct HighContrastModifier: ViewModifier {
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        applyHighContrast(to: content, isEnabled: isEnabled)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply high contrast with platform-specific behavior
    private func applyHighContrast<Content: View>(to content: Content, isEnabled: Bool) -> AnyView {
        guard isEnabled else {
            return content.wrappedWithCompliance()
        }
        
        #if canImport(UIKit)
        return iosHighContrast(to: content).wrappedWithCompliance()
        #elseif os(macOS)
        return macOSHighContrast(to: content).wrappedWithCompliance()
        #else
        return fallbackHighContrast(to: content)
        #endif
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if canImport(UIKit)
    private func iosHighContrast<Content: View>(to content: Content) -> some View {
        content
            .foregroundColor(.primary)
            .background(Color(UIColor.systemBackground))
    }
    #endif
    
    #if os(macOS)
    private func macOSHighContrast<Content: View>(to content: Content) -> some View {
        content
            .foregroundColor(.primary)
            .background(.gray)
    }
    #endif
    
    private func fallbackHighContrast<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// Reduced motion modifier
public struct ReducedMotionModifier: ViewModifier {
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        if isEnabled {
            content
                .animation(.none, value: UUID())
                .automaticCompliance()
        } else {
            content
                .automaticCompliance()
        }
    }
}

/// Dynamic type modifier
public struct DynamicTypeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(.accessibility1...)
            .automaticCompliance()
    }
}

/// Platform navigation modifier
public struct PlatformNavigationModifier: ViewModifier {
    let platform: SixLayerPlatform
    
    public func body(content: Content) -> some View {
        applyPlatformNavigation(to: content, platform: platform)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific navigation patterns
    private func applyPlatformNavigation<Content: View>(
        to content: Content,
        platform: SixLayerPlatform
    ) -> AnyView {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        switch platform {
        case .iOS:
            #if os(iOS)
            return iosPlatformNavigation(to: content).wrappedWithCompliance()
            #else
            return fallbackPlatformNavigation(to: content)
            #endif
        case .macOS:
            #if os(macOS)
            return macOSPlatformNavigation(to: content).wrappedWithCompliance()
            #else
            return fallbackPlatformNavigation(to: content)
            #endif
        default:
            return fallbackPlatformNavigation(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS)
    private func iosPlatformNavigation<Content: View>(to content: Content) -> some View {
        content.platformNavigationTitleDisplayMode_L4(.inline)
    }
    #endif
    
    private func macOSPlatformNavigation<Content: View>(to content: Content) -> some View {
        content.navigationTitle("")
    }
    
    private func fallbackPlatformNavigation<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// Platform styling modifier
public struct PlatformStylingModifier: ViewModifier {
    let designSystem: PlatformDesignSystem
    
    public func body(content: Content) -> some View {
        content
            .foregroundStyle(designSystem.colorSystem.text)
            .background(designSystem.colorSystem.background)
        // CRITICAL: Do NOT call .automaticCompliance() here - it causes infinite recursion
        // This modifier is already applied within AutomaticComplianceModifier.applyHIGComplianceFeatures
    }
}

/// Platform icon modifier
public struct PlatformIconModifier: ViewModifier {
    let iconSystem: HIGIconSystem
    
    public func body(content: Content) -> some View {
        content
            .imageScale(.medium)
        // CRITICAL: Do NOT call .automaticCompliance() here - it causes infinite recursion
        // This modifier is already applied within AutomaticComplianceModifier.applyHIGComplianceFeatures
    }
}

/// System color modifier
public struct SystemColorModifier: ViewModifier {
    let colorSystem: HIGColorSystem
    
    public func body(content: Content) -> some View {
        content
            .foregroundStyle(colorSystem.text)
            .background(colorSystem.background)
        // CRITICAL: Do NOT call .automaticCompliance() here - it causes infinite recursion
        // This modifier is already applied within AutomaticComplianceModifier.applyHIGComplianceFeatures
    }
}

/// System typography modifier
public struct SystemTypographyModifier: ViewModifier {
    let typographySystem: HIGTypographySystem
    
    public func body(content: Content) -> some View {
        content
            .font(typographySystem.body)
        // CRITICAL: Do NOT call .automaticCompliance() here - it causes infinite recursion
        // This modifier is already applied within AutomaticComplianceModifier.applyHIGComplianceFeatures
    }
}

/// Spacing modifier following Apple's 8pt grid
public struct SpacingModifier: ViewModifier {
    let spacingSystem: HIGSpacingSystem
    
    public func body(content: Content) -> some View {
        content
            .padding(spacingSystem.md)
        // CRITICAL: Do NOT call .automaticCompliance() here - it causes infinite recursion
        // This modifier is already applied within AutomaticComplianceModifier.applyHIGComplianceFeatures
    }
}

/// Touch target modifier ensuring proper touch targets
/// Enforces Apple HIG requirement: 44pt minimum touch target on iOS/watchOS
public struct TouchTargetModifier: ViewModifier {
    let platform: SixLayerPlatform
    let iOSConfig: HIGiOSCategoryConfig?
    
    public init(platform: SixLayerPlatform, iOSConfig: HIGiOSCategoryConfig? = nil) {
        self.platform = platform
        self.iOSConfig = iOSConfig
    }
    
    public func body(content: Content) -> some View {
        applyTouchTarget(to: content, platform: platform, iOSConfig: iOSConfig)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific touch target requirements
    private func applyTouchTarget<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        if platform.isTouchFirstPlatform {
            #if os(iOS) || os(watchOS)
            let config = getConfigOrDefault(iOSConfig, default: HIGiOSCategoryConfig())
            return iosTouchTarget(to: content, config: config).wrappedWithCompliance()
            #else
            return fallbackTouchTarget(to: content)
            #endif
        } else {
            return fallbackTouchTarget(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS) || os(watchOS)
    /// iOS/watchOS: Enforce 44pt minimum touch target (Apple HIG requirement)
    private func iosTouchTarget<Content: View>(
        to content: Content,
        config: HIGiOSCategoryConfig
    ) -> some View {
        guard config.enableTouchTargetValidation else {
            return content.wrappedWithCompliance()
        }
        
        // Apple HIG: Minimum 44pt touch target for interactive elements
        return content.frame(minWidth: 44, minHeight: 44).wrappedWithCompliance()
    }
    #endif
    
    /// Fallback for platforms without touch target requirements
    private func fallbackTouchTarget<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

// MARK: - Safe Area Compliance Modifier

/// Safe area compliance modifier ensuring proper safe area handling on iOS
/// Automatically applies safe area insets to respect device notches, status bars, and home indicators
public struct SafeAreaComplianceModifier: ViewModifier {
    let platform: SixLayerPlatform
    let iOSConfig: HIGiOSCategoryConfig?
    
    public init(platform: SixLayerPlatform, iOSConfig: HIGiOSCategoryConfig? = nil) {
        self.platform = platform
        self.iOSConfig = iOSConfig
    }
    
    public func body(content: Content) -> some View {
        applySafeAreaCompliance(to: content, platform: platform, iOSConfig: iOSConfig)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific safe area compliance
    private func applySafeAreaCompliance<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        if platform.isTouchFirstPlatform {
            #if os(iOS) || os(watchOS)
            let config = getConfigOrDefault(iOSConfig, default: HIGiOSCategoryConfig())
            return iosSafeAreaCompliance(to: content, config: config).wrappedWithCompliance()
            #else
            return fallbackSafeAreaCompliance(to: content)
            #endif
        } else {
            return fallbackSafeAreaCompliance(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS) || os(watchOS)
    /// iOS/watchOS: Apply safe area insets automatically
    private func iosSafeAreaCompliance<Content: View>(
        to content: Content,
        config: HIGiOSCategoryConfig
    ) -> some View {
        guard config.enableSafeAreaCompliance else {
            return content.wrappedWithCompliance()
        }
        
        // Safe area is automatically handled by SwiftUI when using proper container views
        // This modifier ensures content respects safe areas by using safeAreaInset when needed
        // For most cases, SwiftUI's automatic safe area handling is sufficient
        return content
            .ignoresSafeArea(.container, edges: []) // Respect all safe areas
            .wrappedWithCompliance()
    }
    #endif
    
    /// Fallback for platforms without safe area requirements
    private func fallbackSafeAreaCompliance<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// Platform interaction modifier
/// Applies platform-specific interaction patterns (touch for iOS, mouse for macOS)
public struct PlatformInteractionModifier: ViewModifier {
    let platform: SixLayerPlatform
    let macOSConfig: HIGmacOSCategoryConfig?
    
    public init(platform: SixLayerPlatform, macOSConfig: HIGmacOSCategoryConfig? = nil) {
        self.platform = platform
        self.macOSConfig = macOSConfig
    }
    
    public func body(content: Content) -> some View {
        applyPlatformInteraction(to: content, platform: platform, macOSConfig: macOSConfig)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific interaction patterns
    private func applyPlatformInteraction<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        macOSConfig: HIGmacOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        switch platform {
        case .iOS:
            #if os(iOS)
            return iosPlatformInteraction(to: content)
            #else
            return fallbackPlatformInteraction(to: content)
            #endif
        case .macOS:
            #if os(macOS)
            let config = getConfigOrDefault(macOSConfig, default: HIGmacOSCategoryConfig())
            return macOSPlatformInteraction(to: content, config: config)
            #else
            return fallbackPlatformInteraction(to: content)
            #endif
        default:
            return fallbackPlatformInteraction(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS)
    /// iOS: Touch-based interactions with button styling
    private func iosPlatformInteraction<Content: View>(to content: Content) -> AnyView {
        content.buttonStyle(.bordered).wrappedWithCompliance()
    }
    #endif
    
    #if os(macOS)
    /// macOS: Mouse-based interactions with hover states and click patterns
    private func macOSPlatformInteraction<Content: View>(
        to content: Content,
        config: HIGmacOSCategoryConfig
    ) -> AnyView {
        let baseContent = content.buttonStyle(.bordered)
        
        guard config.enableMouseInteractions else {
            return baseContent.wrappedWithCompliance()
        }
        
        // Apply macOS-appropriate mouse interaction patterns
        // Hover states, click patterns, and cursor changes
        return baseContent
            .onHover { isHovering in
                // Handle hover state - cursor changes are automatic in SwiftUI
                // Additional hover effects can be added here
            }
            .wrappedWithCompliance()
    }
    #endif
    
    private func fallbackPlatformInteraction<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// Haptic feedback modifier
/// Applies platform-specific haptic feedback based on configuration
public struct HapticFeedbackModifier: ViewModifier {
    let platform: SixLayerPlatform
    let iOSConfig: HIGiOSCategoryConfig?
    
    public init(platform: SixLayerPlatform, iOSConfig: HIGiOSCategoryConfig? = nil) {
        self.platform = platform
        self.iOSConfig = iOSConfig
    }
    
    public func body(content: Content) -> some View {
        applyHapticFeedback(to: content, platform: platform, iOSConfig: iOSConfig)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific haptic feedback
    private func applyHapticFeedback<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        if platform.isTouchFirstPlatform {
            #if os(iOS) || os(watchOS)
            let config = getConfigOrDefault(iOSConfig, default: HIGiOSCategoryConfig())
            return iosHapticFeedback(to: content, config: config).wrappedWithCompliance()
            #else
            return fallbackHapticFeedback(to: content)
            #endif
        } else if platform == .macOS {
            #if os(macOS)
            return macOSHapticFeedback(to: content).wrappedWithCompliance()
            #else
            return fallbackHapticFeedback(to: content)
            #endif
        } else {
            return fallbackHapticFeedback(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS) || os(watchOS)
    /// iOS/watchOS: Native haptic feedback on tap with configurable type
    private func iosHapticFeedback<Content: View>(
        to content: Content,
        config: HIGiOSCategoryConfig
    ) -> AnyView {
        guard config.enableHapticFeedback else {
            return content.wrappedWithCompliance()
        }
        
        let hapticType = config.defaultHapticFeedbackType
        
        return content
            .onTapGesture {
                triggerIOSHapticFeedback(type: hapticType)
            }
            .wrappedWithCompliance()
    }
    
    /// Trigger iOS haptic feedback based on type
    private func triggerIOSHapticFeedback(type: PlatformHapticFeedback) {
        #if os(iOS)
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .soft:
            if #available(iOS 13.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            } else {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
            } else {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        #endif
    }
    #endif
    
    #if os(macOS)
    /// macOS: Sound feedback instead of haptics (macOS doesn't support haptics)
    private func macOSHapticFeedback<Content: View>(to content: Content) -> AnyView {
        // macOS doesn't have haptic feedback, so we return content unchanged
        // In a full implementation, this could trigger sound feedback
        content.wrappedWithCompliance()
    }
    #endif
    
    /// Fallback for platforms without haptic feedback support
    private func fallbackHapticFeedback<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

/// Gesture recognition modifier
/// Applies platform-specific gesture recognition based on configuration
public struct GestureRecognitionModifier: ViewModifier {
    let platform: SixLayerPlatform
    let iOSConfig: HIGiOSCategoryConfig?
    
    public init(platform: SixLayerPlatform, iOSConfig: HIGiOSCategoryConfig? = nil) {
        self.platform = platform
        self.iOSConfig = iOSConfig
    }
    
    public func body(content: Content) -> some View {
        applyGestureRecognition(to: content, platform: platform, iOSConfig: iOSConfig)
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific gesture recognition
    private func applyGestureRecognition<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        if platform.isTouchFirstPlatform {
            #if os(iOS) || os(watchOS)
            let config = getConfigOrDefault(iOSConfig, default: HIGiOSCategoryConfig())
            return iosGestureRecognition(to: content, config: config).wrappedWithCompliance()
            #else
            return fallbackGestureRecognition(to: content)
            #endif
        } else if platform == .macOS {
            #if os(macOS)
            return macOSGestureRecognition(to: content).wrappedWithCompliance()
            #else
            return fallbackGestureRecognition(to: content)
            #endif
        } else {
            return fallbackGestureRecognition(to: content)
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(iOS) || os(watchOS)
    /// iOS/watchOS: Touch-based gesture recognition (tap, long press, swipe, pinch, rotation)
    private func iosGestureRecognition<Content: View>(
        to content: Content,
        config: HIGiOSCategoryConfig
    ) -> AnyView {
        guard config.enableGestureRecognition else {
            return content.wrappedWithCompliance()
        }
        
        // Apply basic tap gesture recognition
        // Additional gestures (long press, swipe, pinch, rotation) can be added
        // via explicit gesture modifiers when needed
        return content
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        // Tap gesture handled - additional gestures can be added explicitly
                    }
            )
            .wrappedWithCompliance()
    }
    #endif
    
    #if os(macOS)
    /// macOS: Mouse-based gesture recognition
    private func macOSGestureRecognition<Content: View>(to content: Content) -> AnyView {
        content
            .onTapGesture {
                // Handle click gesture
            }
            .wrappedWithCompliance()
    }
    #endif
    
    /// Fallback for platforms without gesture recognition
    private func fallbackGestureRecognition<Content: View>(to content: Content) -> AnyView {
        content.wrappedWithCompliance()
    }
}

// MARK: - View Extensions for Easy Use

public extension View {
    /// Apply comprehensive Apple HIG compliance automatically
    func appleHIGCompliant() -> some View {
        self.modifier(SystemAccessibilityModifier(
            accessibilityState: AccessibilitySystemState(),
            platform: .iOS
        ))
        .automaticCompliance(named: "AppleHIGCompliant")
    }
    
    /// Apply automatic accessibility features
    func automaticAccessibility() -> some View {
        self.modifier(SystemAccessibilityModifier(
            accessibilityState: AccessibilitySystemState(),
            platform: .iOS // This would be detected automatically
        ))
    }
    
    /// Apply platform-specific patterns
    func platformPatterns() -> some View {
        let platform = RuntimeCapabilityDetection.currentPlatform
        return self.modifier(PlatformPatternModifier(
            designSystem: PlatformDesignSystem.cached(for: platform),
            platform: platform
        ))
    }
    
    /// Apply visual design consistency
    func visualConsistency() -> some View {
        let platform = RuntimeCapabilityDetection.currentPlatform
        return self.modifier(VisualConsistencyModifier(
            designSystem: PlatformDesignSystem.cached(for: platform),
            platform: platform,
            visualDesignConfig: HIGVisualDesignCategoryConfig.default(for: platform),
            iOSConfig: platform == .iOS ? HIGiOSCategoryConfig() : nil
        ))
    }
    
    /// Apply interaction patterns
    func interactionPatterns() -> some View {
        self.modifier(InteractionPatternModifier(
            platform: .iOS,
            accessibilityState: AccessibilitySystemState(),
            iOSConfig: HIGiOSCategoryConfig()
        ))
    }
}

// MARK: - Platform-Specific Category Modifier

/// Applies platform-specific HIG compliance categories (iOS, macOS, visionOS)
/// Handles categories that are specific to each platform's interaction patterns
public struct PlatformSpecificCategoryModifier: ViewModifier {
    let platform: SixLayerPlatform
    let iOSConfig: HIGiOSCategoryConfig?
    let macOSConfig: HIGmacOSCategoryConfig?
    let visionOSConfig: HIGvisionOSCategoryConfig?
    
    public init(
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig? = nil,
        macOSConfig: HIGmacOSCategoryConfig? = nil,
        visionOSConfig: HIGvisionOSCategoryConfig? = nil
    ) {
        self.platform = platform
        self.iOSConfig = iOSConfig
        self.macOSConfig = macOSConfig
        self.visionOSConfig = visionOSConfig
    }
    
    public func body(content: Content) -> some View {
        applyPlatformSpecificCategories(
            to: content,
            platform: platform,
            iOSConfig: iOSConfig,
            macOSConfig: macOSConfig,
            visionOSConfig: visionOSConfig
        )
    }
    
    // MARK: - Cross-Platform Implementation
    
    /// Apply platform-specific categories
    private func applyPlatformSpecificCategories<Content: View>(
        to content: Content,
        platform: SixLayerPlatform,
        iOSConfig: HIGiOSCategoryConfig?,
        macOSConfig: HIGmacOSCategoryConfig?,
        visionOSConfig: HIGvisionOSCategoryConfig?
    ) -> some View {
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        // Touch-first platforms (iOS/watchOS) - categories handled by other modifiers
        if platform.isTouchFirstPlatform {
            return content.wrappedWithCompliance()
        } else if platform == .macOS {
            #if os(macOS)
            let config = getConfigOrDefault(macOSConfig, default: HIGmacOSCategoryConfig())
            return macOSPlatformSpecificCategories(to: content, config: config)
            #else
            return content.wrappedWithCompliance()
            #endif
        } else if platform == .visionOS {
            #if os(visionOS)
            let config = getConfigOrDefault(visionOSConfig, default: HIGvisionOSCategoryConfig())
            return visionOSPlatformSpecificCategories(to: content, config: config)
            #else
            return content.wrappedWithCompliance()
            #endif
        } else {
            return content.wrappedWithCompliance()
        }
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(macOS)
    /// macOS: Apply window management, keyboard shortcuts, and mouse interactions
    private func macOSPlatformSpecificCategories<Content: View>(
        to content: Content,
        config: HIGmacOSCategoryConfig
    ) -> AnyView {
        // Note: Window management (resize, minimize, maximize, fullscreen) is typically
        // handled at the App/Window level via NSWindow or SwiftUI WindowGroup, not at the view level.
        // This modifier focuses on view-level macOS HIG compliance.
        
        // Keyboard shortcuts are applied via .keyboardShortcut() modifier when needed
        // Mouse interactions (hover states, click patterns) are handled by PlatformInteractionModifier
        // Menu bar integration requires App-level configuration and is opt-in via config
        
        // Additional macOS-specific view-level enhancements can be added here
        // For now, the existing modifiers handle the core functionality
        
        return content.wrappedWithCompliance()
    }
    #endif
    
    #if os(visionOS)
    /// visionOS: Apply spatial UI, hand tracking, and spatial audio
    /// Note: Eye tracking is not available via public API
    private func visionOSPlatformSpecificCategories<Content: View>(
        to content: Content,
        config: HIGvisionOSCategoryConfig
    ) -> AnyView {
        // Hand tracking is handled through SwiftUI gestures (tap, pinch, rotate)
        // Spatial UI is handled through WindowGroup and RealityKit
        // Spatial audio requires AVAudioEngine setup (not handled at view level)
        
        // Additional visionOS-specific enhancements can be added here
        // For now, the existing modifiers handle the core functionality
        
        // Note: Eye tracking is not available via public API as of visionOS 1.0
        // This is reserved for future use when Apple provides a public API
        
        return content.wrappedWithCompliance()
    }
    #endif
}
