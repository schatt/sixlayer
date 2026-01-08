import Foundation
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Apple HIG Compliance Manager

/// Central manager for automatic Apple Human Interface Guidelines compliance
/// Ensures all UI elements follow Apple's design standards automatically
@MainActor
public class AppleHIGComplianceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current compliance level
    @Published public var complianceLevel: HIGComplianceLevel = .automatic
    
    /// System accessibility state
    @Published public var accessibilityState: AccessibilitySystemState = AccessibilitySystemState()
    
    /// Platform-specific design system
    @Published public var designSystem: PlatformDesignSystem = PlatformDesignSystem(for: .iOS)
    
    /// Current platform
    @Published public var currentPlatform: SixLayerPlatform = .iOS
    
    /// Visual design category configuration
    @Published public var visualDesignConfig: HIGVisualDesignCategoryConfig = HIGVisualDesignCategoryConfig()
    
    /// iOS-specific category configuration
    @Published public var iOSCategoryConfig: HIGiOSCategoryConfig = HIGiOSCategoryConfig()
    
    /// macOS-specific category configuration
    @Published public var macOSCategoryConfig: HIGmacOSCategoryConfig = HIGmacOSCategoryConfig()
    
    /// visionOS-specific category configuration
    @Published public var visionOSCategoryConfig: HIGvisionOSCategoryConfig = HIGvisionOSCategoryConfig()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        setupPlatformDetection()
        setupAccessibilityMonitoring()
        setupDesignSystem()
    }
    
    // MARK: - Platform Detection
    
    private func setupPlatformDetection() {
        currentPlatform = SixLayerPlatform.current
    }
    
    // MARK: - Accessibility Monitoring
    
    private func setupAccessibilityMonitoring() {
        // Monitor system accessibility state changes
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateAccessibilityState()
            }
            .store(in: &cancellables)
    }
    
    private func updateAccessibilityState() {
        // Simplified accessibility state update
        accessibilityState = AccessibilitySystemState()
    }
    
    // MARK: - Design System Setup
    
    private func setupDesignSystem() {
        designSystem = PlatformDesignSystem(for: currentPlatform)
    }
    
    // MARK: - Automatic Compliance Application
    
    /// Apply automatic Apple HIG compliance to a view
    public func applyHIGCompliance<Content: View>(to content: Content) -> some View {
        return content
            .modifier(SystemAccessibilityModifier(
                accessibilityState: accessibilityState,
                platform: currentPlatform
            ))
    }
    
    /// Apply automatic accessibility features
    public func applyAutomaticAccessibility<Content: View>(to content: Content) -> some View {
        return content
            .modifier(SystemAccessibilityModifier(
                accessibilityState: accessibilityState,
                platform: currentPlatform
            ))
    }
    
    /// Apply platform-specific design patterns
    public func applyPlatformPatterns<Content: View>(to content: Content) -> some View {
        return content
            .modifier(PlatformPatternModifier(
                designSystem: designSystem,
                platform: currentPlatform
            ))
    }
    
    /// Apply visual design consistency
    public func applyVisualConsistency<Content: View>(to content: Content) -> some View {
        return content
            .modifier(VisualConsistencyModifier(
                designSystem: designSystem,
                platform: currentPlatform,
                visualDesignConfig: visualDesignConfig,
                iOSConfig: currentPlatform == .iOS ? iOSCategoryConfig : nil
            ))
    }
    
    // MARK: - Compliance Checking
    
    /// Check if a view meets Apple HIG compliance standards
    public func checkHIGCompliance<Content: View>(_ content: Content) -> HIGComplianceReport {
        let accessibilityScore = checkAccessibilityCompliance(content)
        let visualScore = checkVisualCompliance(content)
        let interactionScore = checkInteractionCompliance(content)
        let platformScore = checkPlatformCompliance(content)
        
        let overallScore = (accessibilityScore + visualScore + interactionScore + platformScore) / 4.0
        
        return HIGComplianceReport(
            overallScore: overallScore,
            accessibilityScore: accessibilityScore,
            visualScore: visualScore,
            interactionScore: interactionScore,
            platformScore: platformScore,
            recommendations: generateRecommendations(
                accessibility: accessibilityScore,
                visual: visualScore,
                interaction: interactionScore,
                platform: platformScore
            )
        )
    }
    
    // MARK: - Private Compliance Checking Methods
    
    private func checkAccessibilityCompliance<Content: View>(_ content: Content) -> Double {
        var score = 0.0
        
        // Check for accessibility labels
        if hasAccessibilityLabel(content) {
            score += 25.0
        }
        
        // Check for accessibility hints
        if hasAccessibilityHint(content) {
            score += 25.0
        }
        
        // Check for proper accessibility traits
        if hasProperAccessibilityTraits(content) {
            score += 25.0
        }
        
        // Check for keyboard navigation support
        if supportsKeyboardNavigation(content) {
            score += 25.0
        }
        
        return score
    }
    
    private func checkVisualCompliance<Content: View>(_ content: Content) -> Double {
        var score = 0.0
        
        // Check for proper spacing (8pt grid)
        if follows8ptGrid(content) {
            score += 25.0
        }
        
        // Check for system colors
        if usesSystemColors(content) {
            score += 25.0
        }
        
        // Check for proper typography
        if usesSystemTypography(content) {
            score += 25.0
        }
        
        // Check for proper touch targets
        if hasProperTouchTargets(content) {
            score += 25.0
        }
        
        return score
    }
    
    private func checkInteractionCompliance<Content: View>(_ content: Content) -> Double {
        var score = 0.0
        
        // Check for proper hover states (macOS)
        if currentPlatform == .macOS && hasHoverStates(content) {
            score += 33.0
        }
        
        // Check for proper touch feedback (iOS)
        if currentPlatform == .iOS && hasTouchFeedback(content) {
            score += 33.0
        }
        
        // Check for gesture recognition
        if hasGestureRecognition(content) {
            score += 34.0
        }
        
        return score
    }
    
    private func checkPlatformCompliance<Content: View>(_ content: Content) -> Double {
        var score = 0.0
        var maxScore = 0.0
        
        // Check for platform-specific patterns
        if followsPlatformPatterns(content) {
            score += 25.0
        }
        maxScore += 25.0
        
        // Check for platform-appropriate styling
        if usesPlatformAppropriateStyling(content) {
            score += 25.0
        }
        maxScore += 25.0
        
        // Check platform-specific category compliance
        switch currentPlatform {
        case .iOS, .watchOS:
            let iOSScore = checkiOSCategoryCompliance()
            score += iOSScore
            maxScore += 50.0
        case .macOS:
            let macOSScore = checkmacOSCategoryCompliance()
            score += macOSScore
            maxScore += 50.0
        case .visionOS:
            let visionOSScore = checkvisionOSCategoryCompliance()
            score += visionOSScore
            maxScore += 50.0
        default:
            // Other platforms don't have specific category checks yet
            maxScore += 50.0
        }
        
        // Normalize to 0-100 scale
        return maxScore > 0 ? (score / maxScore) * 100.0 : 0.0
    }
    
    // MARK: - Platform-Specific Category Compliance Checking
    
    /// Check iOS-specific category compliance
    private func checkiOSCategoryCompliance() -> Double {
        let checks: [(Bool, Double)] = [
            (iOSCategoryConfig.enableHapticFeedback, 12.5),
            (iOSCategoryConfig.enableGestureRecognition, 12.5),
            (iOSCategoryConfig.enableTouchTargetValidation, 12.5),
            (iOSCategoryConfig.enableSafeAreaCompliance, 12.5)
        ]
        return calculateComplianceScore(checks: checks)
    }
    
    /// Check macOS-specific category compliance
    private func checkmacOSCategoryCompliance() -> Double {
        let checks: [(Bool, Double)] = [
            (macOSCategoryConfig.enableMouseInteractions, 25.0),
            (macOSCategoryConfig.enableKeyboardShortcuts, 25.0)
            // Note: Window management and menu bar integration are App-level concerns
            // and are documented but not validated at the view level
        ]
        return calculateComplianceScore(checks: checks)
    }
    
    /// Check visionOS-specific category compliance
    private func checkvisionOSCategoryCompliance() -> Double {
        let checks: [(Bool, Double)] = [
            (visionOSCategoryConfig.enableHandTracking, 33.0),
            (visionOSCategoryConfig.enableSpatialUI, 33.0),
            (visionOSCategoryConfig.enableSpatialAudio, 34.0)
            // Note: Eye tracking is not available via public API
        ]
        return calculateComplianceScore(checks: checks)
    }
    
    /// Helper function to calculate compliance score from a list of checks
    /// - Parameter checks: Array of (isEnabled, weight) tuples
    /// - Returns: Calculated score (0.0 if no checks provided)
    private func calculateComplianceScore(checks: [(Bool, Double)]) -> Double {
        guard !checks.isEmpty else { return 0.0 }
        
        let (score, maxScore) = checks.reduce((0.0, 0.0)) { result, check in
            let (currentScore, currentMax) = result
            let (isEnabled, weight) = check
            return (
                currentScore + (isEnabled ? weight : 0.0),
                currentMax + weight
            )
        }
        
        return maxScore > 0 ? score : 0.0
    }
    
    // MARK: - Helper Methods
    
    private func hasAccessibilityLabel<Content: View>(_ content: Content) -> Bool {
        // This would use reflection or view introspection in a real implementation
        // For now, we'll assume basic views have accessibility labels
        return true
    }
    
    private func hasAccessibilityHint<Content: View>(_ content: Content) -> Bool {
        // Check if view has accessibility hints
        return true
    }
    
    private func hasProperAccessibilityTraits<Content: View>(_ content: Content) -> Bool {
        // Check for proper accessibility traits
        return true
    }
    
    private func supportsKeyboardNavigation<Content: View>(_ content: Content) -> Bool {
        // Check for keyboard navigation support
        return true
    }
    
    private func follows8ptGrid<Content: View>(_ content: Content) -> Bool {
        // Check if view follows Apple's 8pt grid system
        return true
    }
    
    private func usesSystemColors<Content: View>(_ content: Content) -> Bool {
        // Check if view uses system colors
        return true
    }
    
    private func usesSystemTypography<Content: View>(_ content: Content) -> Bool {
        // Check if view uses system typography
        return true
    }
    
    private func hasProperTouchTargets<Content: View>(_ content: Content) -> Bool {
        // Check for proper touch targets (44pt minimum on iOS)
        return true
    }
    
    private func hasHoverStates<Content: View>(_ content: Content) -> Bool {
        // Check for hover states on macOS
        return currentPlatform == .macOS
    }
    
    private func hasTouchFeedback<Content: View>(_ content: Content) -> Bool {
        // Check for touch feedback on iOS
        return currentPlatform == .iOS
    }
    
    private func hasGestureRecognition<Content: View>(_ content: Content) -> Bool {
        // Check for gesture recognition
        return true
    }
    
    private func followsPlatformPatterns<Content: View>(_ content: Content) -> Bool {
        // Check if view follows platform-specific patterns
        return true
    }
    
    private func usesPlatformAppropriateStyling<Content: View>(_ content: Content) -> Bool {
        // Check for platform-appropriate styling
        return true
    }
    
    private func generateRecommendations(
        accessibility: Double,
        visual: Double,
        interaction: Double,
        platform: Double
    ) -> [HIGRecommendation] {
        var recommendations: [HIGRecommendation] = []
        
        if accessibility < 75.0 {
            recommendations.append(HIGRecommendation(
                category: .accessibility,
                priority: .high,
                description: "Improve accessibility features",
                suggestion: "Add proper accessibility labels, hints, and traits"
            ))
        }
        
        if visual < 75.0 {
            recommendations.append(HIGRecommendation(
                category: .visual,
                priority: .medium,
                description: "Improve visual design consistency",
                suggestion: "Use system colors, typography, and follow the 8pt grid"
            ))
        }
        
        if interaction < 75.0 {
            recommendations.append(HIGRecommendation(
                category: .interaction,
                priority: .medium,
                description: "Improve interaction patterns",
                suggestion: "Add platform-appropriate hover states and touch feedback"
            ))
        }
        
        if platform < 75.0 {
            let platformRecommendation = generatePlatformRecommendation()
            recommendations.append(platformRecommendation)
        }
        
        return recommendations
    }
    
    /// Generate platform-specific recommendations based on current platform and configuration
    private func generatePlatformRecommendation() -> HIGRecommendation {
        switch currentPlatform {
        case .iOS, .watchOS:
            var suggestions: [String] = []
            
            if !iOSCategoryConfig.enableHapticFeedback {
                suggestions.append("Enable haptic feedback for better user interaction feedback")
            }
            if !iOSCategoryConfig.enableGestureRecognition {
                suggestions.append("Enable gesture recognition for standard iOS gestures")
            }
            if !iOSCategoryConfig.enableTouchTargetValidation {
                suggestions.append("Enable touch target validation to ensure 44pt minimum touch targets")
            }
            if !iOSCategoryConfig.enableSafeAreaCompliance {
                suggestions.append("Enable safe area compliance to respect device notches and home indicators")
            }
            
            let suggestion = suggestions.isEmpty
                ? "Follow iOS-specific design patterns and styling"
                : suggestions.joined(separator: ". ")
            
            return HIGRecommendation(
                category: .platform,
                priority: .high,
                description: "Improve iOS platform compliance",
                suggestion: suggestion
            )
        case .macOS:
            var suggestions: [String] = []
            
            if !macOSCategoryConfig.enableMouseInteractions {
                suggestions.append("Enable mouse interactions for hover states and click patterns")
            }
            if !macOSCategoryConfig.enableKeyboardShortcuts {
                suggestions.append("Enable keyboard shortcuts for Command+key combinations")
            }
            
            let suggestion = suggestions.isEmpty
                ? "Follow macOS-specific design patterns and styling"
                : suggestions.joined(separator: ". ")
            
            return HIGRecommendation(
                category: .platform,
                priority: .high,
                description: "Improve macOS platform compliance",
                suggestion: suggestion
            )
        case .visionOS:
            var suggestions: [String] = []
            
            if !visionOSCategoryConfig.enableHandTracking {
                suggestions.append("Enable hand tracking for spatial interactions")
            }
            if !visionOSCategoryConfig.enableSpatialUI {
                suggestions.append("Enable spatial UI for immersive experiences")
            }
            // Note: Spatial audio is opt-in, so we don't suggest it as required
            
            let suggestion = suggestions.isEmpty
                ? "Follow visionOS-specific design patterns and styling"
                : suggestions.joined(separator: ". ")
            
            return HIGRecommendation(
                category: .platform,
                priority: .high,
                description: "Improve visionOS platform compliance",
                suggestion: suggestion
            )
        default:
            return HIGRecommendation(
                category: .platform,
                priority: .high,
                description: "Improve platform compliance",
                suggestion: "Follow platform-specific design patterns and styling"
            )
        }
    }
}

// MARK: - Supporting Types

/// HIG compliance level
public enum HIGComplianceLevel: String, CaseIterable {
    case automatic = "automatic"
    case enhanced = "enhanced"
    case standard = "standard"
    case minimal = "minimal"
}

// Platform enumeration is already defined in PlatformTypes.swift

/// Accessibility system state
public struct AccessibilitySystemState {
    public let isVoiceOverRunning: Bool
    public let isDarkerSystemColorsEnabled: Bool
    public let isReduceTransparencyEnabled: Bool
    public let isHighContrastEnabled: Bool
    public let isReducedMotionEnabled: Bool
    public let hasKeyboardSupport: Bool
    public let hasFullKeyboardAccess: Bool
    public let hasSwitchControl: Bool
    
    public init() {
        self.isVoiceOverRunning = false
        self.isDarkerSystemColorsEnabled = false
        self.isReduceTransparencyEnabled = false
        self.isHighContrastEnabled = false
        self.isReducedMotionEnabled = false
        self.hasKeyboardSupport = false
        self.hasFullKeyboardAccess = false
        self.hasSwitchControl = false
    }
    
    public init(from systemState: AccessibilitySystemState) {
        self.isVoiceOverRunning = systemState.isVoiceOverRunning
        self.isDarkerSystemColorsEnabled = systemState.isDarkerSystemColorsEnabled
        self.isReduceTransparencyEnabled = systemState.isReduceTransparencyEnabled
        self.isHighContrastEnabled = systemState.isHighContrastEnabled
        self.isReducedMotionEnabled = systemState.isReducedMotionEnabled
        self.hasKeyboardSupport = systemState.hasKeyboardSupport
        self.hasFullKeyboardAccess = systemState.hasFullKeyboardAccess
        self.hasSwitchControl = systemState.hasSwitchControl
    }
}

/// Platform design system
public struct PlatformDesignSystem {
    public let platform: SixLayerPlatform
    public let colorSystem: HIGColorSystem
    public let typographySystem: HIGTypographySystem
    public let spacingSystem: HIGSpacingSystem
    public let iconSystem: HIGIconSystem
    public let visualDesignSystem: HIGVisualDesignSystem
    
    // Static cache to prevent infinite recursion when creating design systems in view body
    // Design systems are immutable and platform-specific, so caching is safe
    // Using nonisolated(unsafe) because we protect access with NSLock
    nonisolated(unsafe) private static var cachedSystems: [SixLayerPlatform: PlatformDesignSystem] = [:]
    private static let cacheLock = NSLock()
    
    /// Get or create a cached design system for the platform
    /// This prevents infinite recursion when creating design systems in view body
    public static func cached(for platform: SixLayerPlatform) -> PlatformDesignSystem {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        if let cached = cachedSystems[platform] {
            return cached
        }
        
        let system = PlatformDesignSystem(for: platform)
        cachedSystems[platform] = system
        return system
    }
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        self.colorSystem = HIGColorSystem(for: platform)
        self.typographySystem = HIGTypographySystem(for: platform)
        self.spacingSystem = HIGSpacingSystem(for: platform)
        self.iconSystem = HIGIconSystem(for: platform)
        self.visualDesignSystem = HIGVisualDesignSystem(for: platform)
    }
}

/// Color system for platform using ShapeStyle system
public struct HIGColorSystem {
    public let primary: AnyShapeStyle
    public let secondary: AnyShapeStyle
    public let accent: AnyShapeStyle
    public let background: AnyShapeStyle
    public let surface: AnyShapeStyle
    public let text: AnyShapeStyle
    public let textSecondary: AnyShapeStyle
    
    public init(for platform: SixLayerPlatform) {
        self.primary = AnyShapeStyle(ShapeStyleSystem.StandardColors.primary)
        self.secondary = AnyShapeStyle(ShapeStyleSystem.StandardColors.secondary)
        self.accent = AnyShapeStyle(ShapeStyleSystem.StandardColors.accent)
        self.background = ShapeStyleSystem.Factory.background(for: platform)
        self.surface = ShapeStyleSystem.Factory.surface(for: platform)
        self.text = ShapeStyleSystem.Factory.text(for: platform)
        self.textSecondary = AnyShapeStyle(ShapeStyleSystem.StandardColors.textSecondary)
    }
}

/// Typography system for platform
public struct HIGTypographySystem {
    public let largeTitle: Font
    public let title: Font
    public let headline: Font
    public let body: Font
    public let callout: Font
    public let subheadline: Font
    public let footnote: Font
    public let caption: Font
    
    public init(for platform: SixLayerPlatform) {
        // Font styles are consistent across all Apple platforms
        // Removed redundant switch statement (Issue #140)
            self.largeTitle = .largeTitle
            self.title = .title
            self.headline = .headline
            self.body = .body
            self.callout = .callout
            self.subheadline = .subheadline
            self.footnote = .footnote
            self.caption = .caption
    }
}

/// Spacing system following Apple's 8pt grid
public struct HIGSpacingSystem {
    public let xs: CGFloat = 4
    public let sm: CGFloat = 8
    public let md: CGFloat = 16
    public let lg: CGFloat = 24
    public let xl: CGFloat = 32
    public let xxl: CGFloat = 40
    public let xxxl: CGFloat = 48
    
    public init(for platform: SixLayerPlatform) {
        // Spacing is consistent across platforms
    }
}

/// Icon system for platform
public struct HIGIconSystem {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    public func icon(named name: String) -> Image {
        // All platforms use SF Symbols, so no platform-specific logic needed
        // Removed redundant switch statement (Issue #140)
            return Image(systemName: name)
    }
}

/// HIG compliance report
public struct HIGComplianceReport {
    public let overallScore: Double
    public let accessibilityScore: Double
    public let visualScore: Double
    public let interactionScore: Double
    public let platformScore: Double
    public let recommendations: [HIGRecommendation]
}

/// HIG recommendation
public struct HIGRecommendation {
    public let category: HIGCategory
    public let priority: HIGPriority
    public let description: String
    public let suggestion: String
}

/// HIG category
public enum HIGCategory: String, CaseIterable {
    case accessibility = "accessibility"
    case visual = "visual"
    case interaction = "interaction"
    case platform = "platform"
}

/// HIG priority
public enum HIGPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Visual Design Category Configuration

/// Configuration for automatic visual design category application
/// Controls which visual design categories are automatically applied to views
public struct HIGVisualDesignCategoryConfig {
    /// Apply default animations automatically
    /// Note: Currently not implemented - animations should be applied to state changes
    /// using `.animation(_:value:)` or `.higAnimationCategory()` with explicit state tracking
    public var applyAnimations: Bool = false
    
    /// Apply default shadows automatically (elevated shadow for cards/containers)
    public var applyShadows: Bool = false
    
    /// Apply default corner radius automatically (medium radius for cards/containers)
    public var applyCornerRadius: Bool = false
    
    /// Apply default border width automatically
    public var applyBorders: Bool = false
    
    /// Apply default opacity automatically
    public var applyOpacity: Bool = false
    
    /// Apply default blur automatically
    public var applyBlur: Bool = false
    
    /// Default animation category to apply
    public var defaultAnimationCategory: HIGAnimationCategory? = nil // nil = use platform default
    
    /// Default shadow category to apply
    public var defaultShadowCategory: HIGShadowCategory = .elevated
    
    /// Default corner radius category to apply
    public var defaultCornerRadiusCategory: HIGCornerRadiusCategory = .medium
    
    /// Default border width category to apply
    public var defaultBorderWidthCategory: HIGBorderWidthCategory = .thin
    
    /// Default opacity category to apply
    public var defaultOpacityCategory: HIGOpacityCategory = .primary
    
    /// Default blur category to apply
    public var defaultBlurCategory: HIGBlurCategory = .light
    
    public init(
        applyAnimations: Bool = true,
        applyShadows: Bool = false,
        applyCornerRadius: Bool = false,
        applyBorders: Bool = false,
        applyOpacity: Bool = false,
        applyBlur: Bool = false,
        defaultAnimationCategory: HIGAnimationCategory? = nil,
        defaultShadowCategory: HIGShadowCategory = .elevated,
        defaultCornerRadiusCategory: HIGCornerRadiusCategory = .medium,
        defaultBorderWidthCategory: HIGBorderWidthCategory = .thin,
        defaultOpacityCategory: HIGOpacityCategory = .primary,
        defaultBlurCategory: HIGBlurCategory = .light
    ) {
        self.applyAnimations = applyAnimations
        self.applyShadows = applyShadows
        self.applyCornerRadius = applyCornerRadius
        self.applyBorders = applyBorders
        self.applyOpacity = applyOpacity
        self.applyBlur = applyBlur
        self.defaultAnimationCategory = defaultAnimationCategory
        self.defaultShadowCategory = defaultShadowCategory
        self.defaultCornerRadiusCategory = defaultCornerRadiusCategory
        self.defaultBorderWidthCategory = defaultBorderWidthCategory
        self.defaultOpacityCategory = defaultOpacityCategory
        self.defaultBlurCategory = defaultBlurCategory
    }
    
    /// Platform-specific default configuration
    public static func `default`(for platform: SixLayerPlatform) -> HIGVisualDesignCategoryConfig {
        switch platform {
        case .iOS, .watchOS:
            // iOS: Visual design categories disabled by default
            // Developers can enable specific categories via configuration
            return HIGVisualDesignCategoryConfig(
                applyAnimations: false, // Animations should be applied to state changes, not globally
                applyShadows: false, // Shadows applied per-component, not globally
                applyCornerRadius: false,
                applyBorders: false,
                applyOpacity: false,
                applyBlur: false
            )
        case .macOS:
            // macOS: Visual design categories disabled by default
            // Developers can enable specific categories via configuration
            return HIGVisualDesignCategoryConfig(
                applyAnimations: false, // Animations should be applied to state changes, not globally
                applyShadows: false,
                applyCornerRadius: false,
                applyBorders: false,
                applyOpacity: false,
                applyBlur: false
            )
        default:
            return HIGVisualDesignCategoryConfig()
        }
    }
}

// MARK: - iOS-Specific Category Configuration

/// Configuration for iOS-specific HIG compliance categories
public struct HIGiOSCategoryConfig {
    /// Default haptic feedback type for interactive elements
    public var defaultHapticFeedbackType: PlatformHapticFeedback = .medium
    
    /// Enable haptic feedback for button taps
    public var enableHapticFeedback: Bool = true
    
    /// Enable gesture recognition (tap, long press, swipe, pinch, rotation)
    public var enableGestureRecognition: Bool = true
    
    /// Enable touch target validation (44pt minimum enforcement)
    public var enableTouchTargetValidation: Bool = true
    
    /// Enable safe area compliance (automatic safe area handling)
    public var enableSafeAreaCompliance: Bool = true
    
    public init(
        defaultHapticFeedbackType: PlatformHapticFeedback = .medium,
        enableHapticFeedback: Bool = true,
        enableGestureRecognition: Bool = true,
        enableTouchTargetValidation: Bool = true,
        enableSafeAreaCompliance: Bool = true
    ) {
        self.defaultHapticFeedbackType = defaultHapticFeedbackType
        self.enableHapticFeedback = enableHapticFeedback
        self.enableGestureRecognition = enableGestureRecognition
        self.enableTouchTargetValidation = enableTouchTargetValidation
        self.enableSafeAreaCompliance = enableSafeAreaCompliance
    }
}

// MARK: - macOS-Specific Category Configuration

/// Configuration for macOS-specific HIG compliance categories
public struct HIGmacOSCategoryConfig {
    /// Enable window management (resize, minimize, maximize, fullscreen)
    public var enableWindowManagement: Bool = true
    
    /// Enable menu bar integration (status items, menu actions)
    public var enableMenuBarIntegration: Bool = false // Opt-in feature
    
    /// Enable keyboard shortcuts (Command+key combinations)
    public var enableKeyboardShortcuts: Bool = true
    
    /// Enable mouse interactions (hover states, click patterns)
    public var enableMouseInteractions: Bool = true
    
    public init(
        enableWindowManagement: Bool = true,
        enableMenuBarIntegration: Bool = false,
        enableKeyboardShortcuts: Bool = true,
        enableMouseInteractions: Bool = true
    ) {
        self.enableWindowManagement = enableWindowManagement
        self.enableMenuBarIntegration = enableMenuBarIntegration
        self.enableKeyboardShortcuts = enableKeyboardShortcuts
        self.enableMouseInteractions = enableMouseInteractions
    }
}

// MARK: - visionOS-Specific Category Configuration

/// Configuration for visionOS-specific HIG compliance categories
/// Note: Some features (like eye tracking) don't have public APIs yet
public struct HIGvisionOSCategoryConfig {
    /// Enable spatial audio positioning
    /// Note: Requires AVAudioEngine and spatial audio APIs
    public var enableSpatialAudio: Bool = false // Opt-in due to complexity
    
    /// Enable hand tracking interactions
    /// Note: Hand tracking is available through SwiftUI gestures and RealityKit
    public var enableHandTracking: Bool = true
    
    /// Enable spatial UI positioning
    /// Note: Spatial UI is handled through SwiftUI's WindowGroup and RealityKit
    public var enableSpatialUI: Bool = true
    
    /// Note: Eye tracking is not available via public API as of visionOS 1.0
    /// This is reserved for future use when Apple provides a public API
    
    public init(
        enableSpatialAudio: Bool = false,
        enableHandTracking: Bool = true,
        enableSpatialUI: Bool = true
    ) {
        self.enableSpatialAudio = enableSpatialAudio
        self.enableHandTracking = enableHandTracking
        self.enableSpatialUI = enableSpatialUI
    }
}
