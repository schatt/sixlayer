import SwiftUI

// MARK: - Layer 6: Platform System for Intelligent Card Expansion

/// Native SwiftUI components with platform-specific optimizations
public struct NativeExpandableCardView<Item: Identifiable>: View {
    let item: Item
    let expansionStrategy: ExpansionStrategy
    let platformConfig: CardExpansionPlatformConfig
    let performanceConfig: CardExpansionPerformanceConfig
    let accessibilityConfig: CardExpansionAccessibilityConfig
    
    @State private var isExpanded = false
    @State private var isHovered = false
    
    public init(
        item: Item,
        expansionStrategy: ExpansionStrategy,
        platformConfig: CardExpansionPlatformConfig,
        performanceConfig: CardExpansionPerformanceConfig,
        accessibilityConfig: CardExpansionAccessibilityConfig
    ) {
        self.item = item
        self.expansionStrategy = expansionStrategy
        self.platformConfig = platformConfig
        self.performanceConfig = performanceConfig
        self.accessibilityConfig = accessibilityConfig
    }
    
    public var body: some View {
        let scale = calculateScale()
        let animation = platformConfig.animationEasing
        
        platformVStackContainer(alignment: .leading, spacing: 12) {
            cardContent
        }
        .frame(maxWidth: .infinity, minHeight: platformConfig.minTouchTarget)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .scaleEffect(scale)
        .animation(animation, value: scale)
        .animation(animation, value: isExpanded)
        .animation(animation, value: isHovered)
        .onTapGesture {
            handleTap()
        }
        .platformHoverEffect { hovering in
            if platformConfig.supportsHover {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityAction(named: "Activate") {
            handleTap()
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue)
        .environment(\.accessibilityIdentifierLabel, accessibilityLabel)
        .automaticCompliance(named: "NativeExpandableCardView")
    }
    
    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Icon
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            
            platformVStackContainer(alignment: .leading, spacing: 4) {
                // Title
                Text("Card Title")
                    .font(.headline)
                    .lineLimit(2)
                
                // Subtitle
                Text("Card description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            // Expansion indicator
            if expansionStrategy != .none {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding()
        
        // Expanded content
        if isExpanded && expansionStrategy == .contentReveal {
            expandedContent
        }
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        Divider()
        
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text("Additional Details")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("This content is revealed when the card is expanded.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Action 1") { }
                    .buttonStyle(.bordered)
                
                Button("Action 2") { }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.platformSecondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var shadowColor: Color {
        if isExpanded {
            return .black.opacity(0.2)
        } else if isHovered {
            return .black.opacity(0.15)
        } else {
            return .black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isExpanded {
            return 8
        } else if isHovered {
            return 6
        } else {
            return 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isExpanded {
            return 4
        } else if isHovered {
            return 3
        } else {
            return 2
        }
    }
    
    private var borderColor: Color {
        if isExpanded {
            return .blue
        } else if isHovered {
            return .blue.opacity(0.5)
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isExpanded {
            return 2
        } else if isHovered {
            return 1
        } else {
            return 0
        }
    }
    
    private func calculateScale() -> CGFloat {
        if isExpanded {
            return 1.15
        } else if isHovered && expansionStrategy == .hoverExpand {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    private func handleTap() {
        withAnimation(platformConfig.animationEasing) {
            isExpanded.toggle()
        }
        
        // Haptic feedback
        if platformConfig.supportsHapticFeedback {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        }
        
        // Accessibility announcement
        if accessibilityConfig.supportsVoiceOver {
            DispatchQueue.main.asyncAfter(deadline: .now() + accessibilityConfig.announcementDelay) {
                // VoiceOver will automatically announce the state change
            }
        }
    }
    
    // MARK: - Accessibility Support
    
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        
        if isExpanded {
            _ = traits.insert(.isSelected)
        }
        
        if expansionStrategy != .none {
            _ = traits.insert(.isButton)
        }
        
        return traits
    }
    
    private var accessibilityLabel: String {
        "Card Title"
    }
    
    private var accessibilityHint: String {
        if expansionStrategy == .none {
            return "Double tap to activate"
        } else if isExpanded {
            return "Double tap to collapse"
        } else {
            return "Double tap to expand"
        }
    }
    
    private var accessibilityValue: String {
        if isExpanded {
            return "Expanded"
        } else {
            return "Collapsed"
        }
    }
}

// MARK: - Platform-Specific Implementations

/// iOS-specific card implementation
public struct iOSExpandableCardView<Item: Identifiable>: View {
    let item: Item
    let expansionStrategy: ExpansionStrategy
    
    public var body: some View {
        NativeExpandableCardView(
            item: item,
            expansionStrategy: expansionStrategy,
            platformConfig: getCardExpansionPlatformConfig(),
            performanceConfig: getCardExpansionPerformanceConfig(),
            accessibilityConfig: getCardExpansionAccessibilityConfig()
        )
        .automaticCompliance(named: "iOSExpandableCardView")
    }
}

#if os(macOS)
/// macOS-specific card implementation
public struct macOSExpandableCardView<Item: Identifiable>: View {
    let item: Item
    let expansionStrategy: ExpansionStrategy

    public var body: some View {
        NativeExpandableCardView(
            item: item,
            expansionStrategy: expansionStrategy,
            platformConfig: getCardExpansionPlatformConfig(),
            performanceConfig: getCardExpansionPerformanceConfig(),
            accessibilityConfig: getCardExpansionAccessibilityConfig()
        )
        .platformHoverEffect { hovering in
            // macOS-specific hover behavior
            _ = hovering
        }
        .automaticCompliance(named: "macOSExpandableCardView")
    }
}
#endif

/// visionOS-specific card implementation
public struct visionOSExpandableCardView<Item: Identifiable>: View {
    let item: Item
    let expansionStrategy: ExpansionStrategy
    
    public var body: some View {
        NativeExpandableCardView(
            item: item,
            expansionStrategy: expansionStrategy,
            platformConfig: getCardExpansionPlatformConfig(),
            performanceConfig: getCardExpansionPerformanceConfig(),
            accessibilityConfig: getCardExpansionAccessibilityConfig()
        )
        .modifier(FocusableModifier())
        .automaticCompliance(named: "visionOSExpandableCardView")
    }
}

// MARK: - Platform Detection and Routing

/// Platform-aware card view that automatically chooses the right implementation
public struct PlatformAwareExpandableCardView<Item: Identifiable>: View {
    let item: Item
    let expansionStrategy: ExpansionStrategy
    
    public var body: some View {
        Group {
            switch SixLayerPlatform.current {
            case .iOS:
                iOSExpandableCardView(item: item, expansionStrategy: expansionStrategy)
            case .macOS:
                #if os(macOS)
                macOSExpandableCardView(item: item, expansionStrategy: expansionStrategy)
                #else
                NativeExpandableCardView(
                    item: item,
                    expansionStrategy: expansionStrategy,
                    platformConfig: getCardExpansionPlatformConfig(),
                    performanceConfig: getCardExpansionPerformanceConfig(),
                    accessibilityConfig: getCardExpansionAccessibilityConfig()
                )
                #endif
            case .visionOS:
                visionOSExpandableCardView(item: item, expansionStrategy: expansionStrategy)
            case .watchOS, .tvOS:
                // Fallback to native implementation for constrained platforms
                NativeExpandableCardView(
                    item: item,
                    expansionStrategy: expansionStrategy,
                    platformConfig: getCardExpansionPlatformConfig(),
                    performanceConfig: getCardExpansionPerformanceConfig(),
                    accessibilityConfig: getCardExpansionAccessibilityConfig()
                )
            }
        }
        .automaticCompliance(named: "PlatformAwareExpandableCardView")
    }
}

// MARK: - Focusable Modifier

/// Platform-aware focusable modifier that handles iOS 17.0+ availability
struct FocusableModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content.focusable()
        } else {
            content
        }
    }
}
