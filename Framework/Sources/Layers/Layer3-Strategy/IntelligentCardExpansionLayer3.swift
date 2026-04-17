import SwiftUI

// MARK: - Layer 3: Strategy Selection for Intelligent Card Expansion

/// Expansion strategies available for card collections
public enum ExpansionStrategy: String, CaseIterable, Sendable {
    case hoverExpand = "hoverExpand"
    case contentReveal = "contentReveal"
    case gridReorganize = "gridReorganize"
    case focusMode = "focusMode"
    case none = "none"
}

/// Interaction styles for card collections
public enum InteractionStyle: String, CaseIterable {
    case expandable = "expandable"
    case `static` = "static"
    case interactive = "interactive"
}

/// Content density levels
public enum ContentDensity: String, CaseIterable {
    case dense = "dense"
    case balanced = "balanced"
    case spacious = "spacious"
}

/// Card expansion strategy configuration
public struct CardExpansionStrategy: Sendable {
    public let supportedStrategies: [ExpansionStrategy]
    public let primaryStrategy: ExpansionStrategy
    public let expansionScale: Double
    public let animationDuration: TimeInterval
    public let hapticFeedback: Bool
    public let accessibilitySupport: Bool
    
    public init(
        supportedStrategies: [ExpansionStrategy],
        primaryStrategy: ExpansionStrategy,
        expansionScale: Double,
        animationDuration: TimeInterval,
        hapticFeedback: Bool = false,
        accessibilitySupport: Bool = true
    ) {
        self.supportedStrategies = supportedStrategies
        self.primaryStrategy = primaryStrategy
        self.expansionScale = expansionScale
        self.animationDuration = animationDuration
        self.hapticFeedback = hapticFeedback
        self.accessibilitySupport = accessibilitySupport
    }
}

/// Intelligent strategy selection for card expansion
public func selectCardExpansionStrategy_L3(
    contentCount: Int,
    screenWidth: CGFloat,
    deviceType: DeviceType,
    interactionStyle: InteractionStyle,
    contentDensity: ContentDensity
) -> CardExpansionStrategy {
    
    // If interaction is static, no expansion strategies
    guard interactionStyle != .static else {
        return CardExpansionStrategy(
            supportedStrategies: [.none],
            primaryStrategy: .none,
            expansionScale: 1.0,
            animationDuration: 0.0
        )
    }
    
    // Determine supported strategies based on device and context
    let supportedStrategies = determineSupportedStrategies(
        deviceType: deviceType,
        contentCount: contentCount,
        screenWidth: screenWidth,
        contentDensity: contentDensity
    )
    
    // Select primary strategy
    let primaryStrategy = selectPrimaryStrategy(
        supportedStrategies: supportedStrategies,
        deviceType: deviceType,
        contentCount: contentCount,
        contentDensity: contentDensity
    )
    
    // Calculate expansion parameters
    let expansionScale = calculateExpansionScale(
        strategy: primaryStrategy,
        deviceType: deviceType,
        contentDensity: contentDensity
    )
    
    let animationDuration = calculateAnimationDuration(
        strategy: primaryStrategy,
        deviceType: deviceType
    )
    
    let hapticFeedback = shouldUseHapticFeedback(deviceType: deviceType, strategy: primaryStrategy)
    
    return CardExpansionStrategy(
        supportedStrategies: supportedStrategies,
        primaryStrategy: primaryStrategy,
        expansionScale: expansionScale,
        animationDuration: animationDuration,
        hapticFeedback: hapticFeedback,
        accessibilitySupport: true
    )
}

/// Determine which expansion strategies are supported for the given context
private func determineSupportedStrategies(
    deviceType: DeviceType,
    contentCount: Int,
    screenWidth: CGFloat,
    contentDensity: ContentDensity
) -> [ExpansionStrategy] {
    
    var strategies: [ExpansionStrategy] = []
    
    // Hover expand - supported on devices with hover capability
    if deviceType == .mac || deviceType == .pad {
        strategies.append(.hoverExpand)
    }
    
    // Content reveal - supported when there's space for additional content
    if contentDensity != .dense && contentCount <= 12 {
        strategies.append(.contentReveal)
    }
    
    // Grid reorganize - supported on larger screens with multiple items
    if screenWidth > 600 && contentCount > 4 {
        strategies.append(.gridReorganize)
    }
    
    // Focus mode - supported on touch devices, tvOS (focus engine is the sole
    // interaction model), watchOS crown/tap, CarPlay, visionOS, and any dense-content
    // context. Issue #237: tvOS must advertise focusMode so action buttons route
    // through the platform's focus-based navigation.
    if deviceType == .phone
        || deviceType == .pad
        || deviceType == .tv
        || deviceType == .watch
        || deviceType == .car
        || deviceType == .vision
        || contentDensity == .dense {
        strategies.append(.focusMode)
    }
    
    // If no strategies are supported, default to none
    if strategies.isEmpty {
        strategies.append(.none)
    }
    
    return strategies
}

/// Select the primary strategy from supported strategies
private func selectPrimaryStrategy(
    supportedStrategies: [ExpansionStrategy],
    deviceType: DeviceType,
    contentCount: Int,
    contentDensity: ContentDensity
) -> ExpansionStrategy {
    
    // Priority order based on device type and context
    switch deviceType {
    case .mac:
        // Desktop: prefer hover expand, then content reveal
        if supportedStrategies.contains(.hoverExpand) {
            return .hoverExpand
        } else if supportedStrategies.contains(.contentReveal) {
            return .contentReveal
        }
    case .vision:
        // Vision: prefer content reveal for immersive experience
        if supportedStrategies.contains(.contentReveal) {
            return .contentReveal
        } else if supportedStrategies.contains(.hoverExpand) {
            return .hoverExpand
        }
        
    case .pad:
        // Tablet: prefer content reveal, then focus mode
        if supportedStrategies.contains(.contentReveal) {
            return .contentReveal
        } else if supportedStrategies.contains(.focusMode) {
            return .focusMode
        }
        
    case .phone:
        // Phone: prefer focus mode, then content reveal
        if supportedStrategies.contains(.focusMode) {
            return .focusMode
        } else if supportedStrategies.contains(.contentReveal) {
            return .contentReveal
        }
        
    case .watch, .tv:
        // Constrained devices: prefer focus mode
        if supportedStrategies.contains(.focusMode) {
            return .focusMode
        }
        
    case .car:
        // CarPlay: prefer focus mode for safety
        if supportedStrategies.contains(.focusMode) {
            return .focusMode
        }
    }
    
    // Fallback to first supported strategy
    return supportedStrategies.first ?? .none
}

/// Calculate expansion scale for the given strategy and context
private func calculateExpansionScale(
    strategy: ExpansionStrategy,
    deviceType: DeviceType,
    contentDensity: ContentDensity
) -> Double {
    
    let baseScale: Double
    
    switch strategy {
    case .hoverExpand:
        baseScale = 1.15 // 15% expansion for hover
    case .contentReveal:
        baseScale = 1.2 // 20% expansion to reveal content
    case .gridReorganize:
        baseScale = 1.1 // 10% expansion for grid reorganization
    case .focusMode:
        baseScale = 1.25 // 25% expansion for focus mode
    case .none:
        return 1.0
    }
    
    // Adjust based on device type
    let deviceMultiplier: Double
    switch deviceType {
    case .phone:
        deviceMultiplier = 0.9 // Slightly less expansion on small screens
    case .vision:
        deviceMultiplier = 0.95 // Minimal expansion for immersive experience
    case .pad:
        deviceMultiplier = 1.0
    case .mac:
        deviceMultiplier = 1.1 // More expansion on desktop
    case .watch:
        deviceMultiplier = 0.8 // Less expansion on watch
    case .tv:
        deviceMultiplier = 1.2 // More expansion for TV viewing
    case .car:
        deviceMultiplier = 0.9 // Conservative expansion for CarPlay safety
    }
    
    // Adjust based on content density
    let densityMultiplier: Double
    switch contentDensity {
    case .dense:
        densityMultiplier = 0.9 // Less expansion when dense
    case .balanced:
        densityMultiplier = 1.0
    case .spacious:
        densityMultiplier = 1.1 // More expansion when spacious
    }
    
    return baseScale * deviceMultiplier * densityMultiplier
}

/// Calculate animation duration for the given strategy and device
private func calculateAnimationDuration(
    strategy: ExpansionStrategy,
    deviceType: DeviceType
) -> TimeInterval {
    
    let baseDuration: TimeInterval
    
    switch strategy {
    case .hoverExpand:
        baseDuration = 0.2 // Fast for hover
    case .contentReveal:
        baseDuration = 0.3 // Medium for content reveal
    case .gridReorganize:
        baseDuration = 0.4 // Slower for grid changes
    case .focusMode:
        baseDuration = 0.25 // Medium for focus
    case .none:
        return 0.0
    }
    
    // Adjust based on device type
    switch deviceType {
    case .phone, .pad:
        return baseDuration * 0.8 // Faster on touch devices
    case .vision:
        return baseDuration * 0.9 // Slightly slower for immersive experience
    case .mac:
        return baseDuration // Standard on desktop
    case .watch:
        return baseDuration * 0.6 // Very fast on watch
    case .tv:
        return baseDuration * 1.2 // Slower on TV
    case .car:
        return baseDuration * 0.7 // Fast for CarPlay safety
    }
}

/// Determine if haptic feedback should be used
private func shouldUseHapticFeedback(deviceType: DeviceType, strategy: ExpansionStrategy) -> Bool {
    // Only use haptic feedback on devices that support it and for certain strategies
    guard deviceType == .phone || deviceType == .pad else { return false }
    
    switch strategy {
    case .focusMode, .contentReveal:
        return true
    case .hoverExpand, .gridReorganize, .none:
        return false
    }
}
