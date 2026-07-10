import SwiftUI

// MARK: - Layer 2: Layout Decision Engine for Intelligent Card Expansion

private enum PhoneCardViewportHeightClamp {
    /// When the phone grid has more than this many rows, prefer scrolling over squashing card height (GitHub #249).
    static let maxRows: Int = 2
}

private enum IntelligentCardResizeBudget {
    /// Preferred minimum card width when the pane can afford it (GitHub #330).
    static let preferredMinCardWidth: CGFloat = 200
    static let maxCardWidth: CGFloat = 400
    /// Default ceiling when sparse cards grow with viewport height (#330).
    static let defaultMaxCardHeight: CGFloat = 600
    /// Grow/shrink with viewport when the grid has at most this many rows (mac/pad).
    static let sparseMaxRows: Int = 2
}

/// Layout decision result for intelligent card expansion
public struct IntelligentCardLayoutDecision: Sendable {
    public let columns: Int
    public let spacing: CGFloat
    public let cardWidth: CGFloat
    public let cardHeight: CGFloat
    public let padding: CGFloat
    public let expansionScale: Double
    public let animationDuration: TimeInterval
    
    public init(
        columns: Int,
        spacing: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        padding: CGFloat,
        expansionScale: Double = 1.15,
        animationDuration: TimeInterval = 0.3
    ) {
        self.columns = columns
        self.spacing = spacing
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.padding = padding
        self.expansionScale = expansionScale
        self.animationDuration = animationDuration
    }
}

// ContentComplexity is already defined in PlatformTypes.swift

/// Intelligent layout decision engine for card collections
/// - Parameters:
///   - availableHeight: Vertical size of the collection’s layout region (e.g. `GeometryReader` height).
///     When provided, card height is capped so rows fit within that budget, and phone + two items
///     may use two columns in landscape (wider than tall) to reduce row count.
public func determineIntelligentCardLayout_L2(
    contentCount: Int,
    screenWidth: CGFloat,
    deviceType: DeviceType,
    contentComplexity: ContentComplexity,
    viewportHeight: CGFloat? = nil,
    viewportHints: CardViewportHints? = nil,
    preferredContentSizeCategory: SixLayerContentSizeCategory? = nil
) -> IntelligentCardLayoutDecision {
    
    // Base calculations
    let layoutPadding: CGFloat = 16
    let availableWidth = screenWidth - layoutPadding * 2
    let minCardWidth = IntelligentCardResizeBudget.preferredMinCardWidth
    let maxCardWidth = IntelligentCardResizeBudget.maxCardWidth
    let spacing = calculateOptimalSpacing(deviceType: deviceType, contentComplexity: contentComplexity)

    // Desired columns from device/content, then cap by width budget (GitHub #330).
    let desiredColumns = calculateOptimalColumns(
        contentCount: contentCount,
        screenWidth: screenWidth,
        deviceType: deviceType,
        contentComplexity: contentComplexity,
        availableHeight: viewportHeight
    )
    let columns = columnsCappedByAvailableWidth(
        desiredColumns: desiredColumns,
        availableWidth: availableWidth,
        minCardWidth: minCardWidth,
        spacing: spacing,
        deviceType: deviceType
    )
    
    // Share of remaining width; may shrink below preferred min when the pane is narrower (#330).
    let rawCardWidth = (availableWidth - spacing * CGFloat(max(0, columns - 1))) / CGFloat(max(1, columns))
    let cardWidth = min(maxCardWidth, max(0, rawCardWidth))
    let defaultIntrinsicHeight = calculateOptimalHeight(
        cardWidth: cardWidth,
        contentComplexity: contentComplexity,
        contentCount: contentCount,
        deviceType: deviceType,
        preferredContentSizeCategory: nil
    )
    let contentSize = preferredContentSizeCategory ?? .large
    let contentIntrinsicHeight = calculateOptimalHeight(
        cardWidth: cardWidth,
        contentComplexity: contentComplexity,
        contentCount: contentCount,
        deviceType: deviceType,
        preferredContentSizeCategory: contentSize
    )
    let cardHeight = resolvedIntelligentCardHeight(
        defaultIntrinsicHeight: defaultIntrinsicHeight,
        contentIntrinsicHeight: contentIntrinsicHeight,
        contentCount: contentCount,
        columns: columns,
        spacing: spacing,
        layoutPadding: layoutPadding,
        deviceType: deviceType,
        viewportHeight: viewportHeight,
        viewportHints: viewportHints
    )
    
    // Determine expansion behavior
    let expansionScale = calculateExpansionScale(deviceType: deviceType, contentComplexity: contentComplexity)
    let animationDuration = calculateAnimationDuration(deviceType: deviceType)
    
    return IntelligentCardLayoutDecision(
        columns: columns,
        spacing: spacing,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        padding: layoutPadding,
        expansionScale: expansionScale,
        animationDuration: animationDuration
    )
}

/// Caps desired column count so `minCardWidth` columns fit in `availableWidth` (floor 1).
/// Phone keeps its own width thresholds; mac/pad (and other multi-column types) are capped (#330).
private func columnsCappedByAvailableWidth(
    desiredColumns: Int,
    availableWidth: CGFloat,
    minCardWidth: CGFloat,
    spacing: CGFloat,
    deviceType: DeviceType
) -> Int {
    let desired = max(1, desiredColumns)
    switch deviceType {
    case .phone, .watch, .vision:
        return desired
    case .pad, .mac, .tv, .car:
        let denominator = minCardWidth + spacing
        guard denominator > 0, availableWidth.isFinite, availableWidth > 0 else {
            return 1
        }
        let maxColumns = max(1, Int(floor((availableWidth + spacing) / denominator)))
        return min(desired, maxColumns)
    }
}

/// Calculate optimal number of columns
private func calculateOptimalColumns(
    contentCount: Int,
    screenWidth: CGFloat,
    deviceType: DeviceType,
    contentComplexity: ContentComplexity,
    availableHeight: CGFloat?
) -> Int {
    
    switch deviceType {
    case .phone:
        // iPhone: 1-2 columns based on content
        if contentCount <= 2 {
            if contentCount == 2,
               let height = availableHeight,
               height > 0,
               screenWidth > height {
                return 2
            }
            return 1
        } else if screenWidth > 400 {
            return 2
        } else {
            return 1
        }
    case .vision:
        // Vision: 1 column for immersive experience
        return 1
        
    case .pad:
        // iPad: 2-4 columns based on content and complexity
        switch contentComplexity {
        case .simple:
            return min(4, max(2, contentCount / 2))
        case .moderate:
            return min(3, max(2, contentCount / 3))
        case .complex, .veryComplex, .advanced:
            return min(2, max(1, contentCount / 4))
        }
        
    case .mac:
        // Mac: 3-6 columns based on screen width
        if screenWidth < 1200 {
            return min(3, max(2, contentCount / 3))
        } else if screenWidth < 1800 {
            return min(4, max(3, contentCount / 4))
        } else {
            return min(6, max(4, contentCount / 6))
        }
        
    case .watch:
        // Apple Watch: Always 1 column
        return 1
        
    case .tv:
        // Apple TV: 2-3 columns
        return min(3, max(2, contentCount / 3))
        
    case .car:
        // CarPlay: 1-2 columns for safety
        return min(2, max(1, contentCount / 2))
    }
}

/// Calculate optimal spacing between cards
private func calculateOptimalSpacing(deviceType: DeviceType, contentComplexity: ContentComplexity) -> CGFloat {
    let baseSpacing: CGFloat
    
    switch deviceType {
    case .phone:
        baseSpacing = 12
    case .vision:
        baseSpacing = 16
    case .pad:
        baseSpacing = 16
    case .mac:
        baseSpacing = 20
    case .watch:
        baseSpacing = 8
    case .tv:
        baseSpacing = 24
    case .car:
        baseSpacing = 16
    }
    
    // Adjust based on content complexity
    switch contentComplexity {
    case .simple:
        return baseSpacing
    case .moderate:
        return baseSpacing * 1.2
    case .complex:
        return baseSpacing * 1.5
    case .veryComplex:
        return baseSpacing * 2.0
    case .advanced:
        return baseSpacing * 2.0
    }
}

/// Caps card height when a finite viewport height is supplied so collections can fit without scrolling.
/// Legacy phone behavior (#249) applies when `viewportHints` is nil; hosts override via `preferFitInViewport` and `maxCardHeight` (#306).
/// Mac/pad sparse grids grow/shrink with viewport share up to a max (#330); dense grids keep intrinsic height and scroll.
private func cardHeightRespectingViewport(
    intrinsicHeight: CGFloat,
    contentCount: Int,
    columns: Int,
    spacing: CGFloat,
    layoutPadding: CGFloat,
    deviceType: DeviceType,
    viewportHeight: CGFloat?,
    viewportHints: CardViewportHints?
) -> CGFloat {
    var height = intrinsicHeight
    let columnCount = max(columns, 1)
    let rows = max(1, Int(ceil(Double(contentCount) / Double(columnCount))))
    let maxCardHeight = viewportHints?.maxCardHeight
    let ceiling = (maxCardHeight?.isFinite == true && (maxCardHeight ?? 0) > 0)
        ? maxCardHeight!
        : IntelligentCardResizeBudget.defaultMaxCardHeight

    if supportsSparseViewportHeightTracking(deviceType),
       let viewport = viewportHeight,
       viewport.isFinite,
       viewport > 0,
       rows <= IntelligentCardResizeBudget.sparseMaxRows {
        let interRowSpacing = CGFloat(max(0, rows - 1)) * spacing
        let verticalChrome = layoutPadding * 2 + interRowSpacing
        let heightBudget = viewport - verticalChrome
        if heightBudget.isFinite, heightBudget > 0 {
            let share = heightBudget / CGFloat(rows)
            if share.isFinite, share > 0 {
                height = min(ceiling, max(0, share))
            }
        }
    }

    let fitInViewport: Bool = {
        if let hints = viewportHints { return hints.preferFitInViewport }
        return deviceType == .phone
    }()

    if fitInViewport, let viewport = viewportHeight, viewport.isFinite, viewport > 0 {
        let enforceLegacyRowCap = viewportHints == nil
        if !enforceLegacyRowCap || rows <= PhoneCardViewportHeightClamp.maxRows {
            let interRowSpacing = CGFloat(max(0, rows - 1)) * spacing
            let verticalChrome = layoutPadding * 2 + interRowSpacing
            let heightBudget = viewport - verticalChrome
            if heightBudget.isFinite, heightBudget > 0 {
                let maxHeightPerRow = heightBudget / CGFloat(rows)
                if maxHeightPerRow.isFinite, maxHeightPerRow > 0 {
                    height = min(height, maxHeightPerRow)
                }
            }
        }
    }

    if let cap = maxCardHeight, cap.isFinite, cap > 0 {
        height = min(height, cap)
    }
    return height
}

private func supportsSparseViewportHeightTracking(_ deviceType: DeviceType) -> Bool {
    switch deviceType {
    case .mac, .pad:
        return true
    case .phone, .vision, .watch, .tv, .car:
        return false
    }
}

/// Applies viewport clamp; when the budget is binding, ignore Dynamic Type uplift (#309).
private func resolvedIntelligentCardHeight(
    defaultIntrinsicHeight: CGFloat,
    contentIntrinsicHeight: CGFloat,
    contentCount: Int,
    columns: Int,
    spacing: CGFloat,
    layoutPadding: CGFloat,
    deviceType: DeviceType,
    viewportHeight: CGFloat?,
    viewportHints: CardViewportHints?
) -> CGFloat {
    let defaultClampedHeight = cardHeightRespectingViewport(
        intrinsicHeight: defaultIntrinsicHeight,
        contentCount: contentCount,
        columns: columns,
        spacing: spacing,
        layoutPadding: layoutPadding,
        deviceType: deviceType,
        viewportHeight: viewportHeight,
        viewportHints: viewportHints
    )
    let contentClampedHeight = cardHeightRespectingViewport(
        intrinsicHeight: contentIntrinsicHeight,
        contentCount: contentCount,
        columns: columns,
        spacing: spacing,
        layoutPadding: layoutPadding,
        deviceType: deviceType,
        viewportHeight: viewportHeight,
        viewportHints: viewportHints
    )
    let viewportLimited = contentClampedHeight < contentIntrinsicHeight - 0.5
        || defaultClampedHeight < defaultIntrinsicHeight - 0.5
    return viewportLimited ? defaultClampedHeight : contentClampedHeight
}

private func typographyContentDensity(for contentComplexity: ContentComplexity) -> CGFloat {
    switch contentComplexity {
    case .simple: return 0.35
    case .moderate: return 0.5
    case .complex: return 0.65
    case .veryComplex, .advanced: return 0.85
    }
}

private func contentAwareTextLineCount(for contentComplexity: ContentComplexity) -> CGFloat {
    switch contentComplexity {
    case .simple: return 2
    case .moderate: return 3
    case .complex: return 4
    case .veryComplex, .advanced: return 5
    }
}

/// Calculate optimal card height
private func calculateOptimalHeight(
    cardWidth: CGFloat,
    contentComplexity: ContentComplexity,
    contentCount: Int,
    deviceType: DeviceType,
    preferredContentSizeCategory: SixLayerContentSizeCategory? = nil
) -> CGFloat {
    let aspectRatio: CGFloat
    
    switch contentComplexity {
    case .simple:
        aspectRatio = 1.2 // Slightly taller than wide
    case .moderate:
        aspectRatio = 1.4
    case .complex:
        aspectRatio = 1.6
    case .veryComplex:
        aspectRatio = 1.8
    case .advanced:
        aspectRatio = 1.8
    }
    
    var height = cardWidth * aspectRatio
    
    // Two full-width portrait cards (All Vehicles, etc.) used ~2 × 1.4× width in height plus grid
    // padding—almost always taller than the visible area under a large navigation title. Cap height
    // so two stacked cards fit without scrolling on typical iPhone layouts.
    if deviceType == .phone && contentCount == 2 {
        let maxHeightForTwoUpPortrait = cardWidth * 0.74
        height = min(height, maxHeightForTwoUpPortrait)
    }

    let contentSize = preferredContentSizeCategory ?? .large
    let typographyScale = contentSize.typographyScaleFactor
    if typographyScale > 1.0 {
        let contentDensity = typographyContentDensity(for: contentComplexity)
        height *= 1 + (typographyScale - 1) * contentDensity
    }

    let floor = contentAwareMinimumIntelligentCardHeight(
        cardWidth: cardWidth,
        contentComplexity: contentComplexity,
        contentSizeCategory: contentSize
    )
    return max(height, floor)
}

/// Minimum card height from content complexity and accessibility text metrics (GitHub #309).
public func contentAwareMinimumIntelligentCardHeight(
    cardWidth: CGFloat,
    contentComplexity: ContentComplexity,
    contentSizeCategory: SixLayerContentSizeCategory = .large
) -> CGFloat {
    _ = cardWidth
    let policy = HIGMinimumTypographyPolicy.forCurrentPlatform()
    let scale = contentSizeCategory.typographyScaleFactor
    let bodySize = policy.minimumReadableBodyPointSize * scale
    let captionSize = policy.minimumReadableCaptionPointSize * scale

    let textLineCount = contentAwareTextLineCount(for: contentComplexity)

    let lineGap = 4 * scale
    let verticalInset: CGFloat = 24
    let textStackHeight = bodySize * textLineCount
        + captionSize
        + lineGap * max(0, textLineCount - 1)
    let legacyFloor: CGFloat = 110

    return max(legacyFloor, verticalInset * 2 + textStackHeight)
}

/// Calculate expansion scale based on device and content
private func calculateExpansionScale(deviceType: DeviceType, contentComplexity: ContentComplexity) -> Double {
    let baseScale: Double
    
    switch deviceType {
    case .phone:
        baseScale = 1.1 // Subtle expansion on small screens
    case .vision:
        baseScale = 1.05 // Minimal expansion for immersive experience
    case .pad:
        baseScale = 1.15 // Moderate expansion on tablets
    case .mac:
        baseScale = 1.2 // More pronounced expansion on desktop
    case .watch:
        baseScale = 1.05 // Minimal expansion on watch
    case .tv:
        baseScale = 1.25 // Large expansion for TV viewing
    case .car:
        baseScale = 1.1 // Conservative expansion for CarPlay safety
    }
    
    // Adjust based on content complexity
    switch contentComplexity {
    case .simple:
        return baseScale
    case .moderate:
        return baseScale * 1.05
    case .complex:
        return baseScale * 1.1
    case .veryComplex:
        return baseScale * 1.15
    case .advanced:
        return baseScale * 1.15
    }
}

/// Calculate animation duration based on device
private func calculateAnimationDuration(deviceType: DeviceType) -> TimeInterval {
    switch deviceType {
    case .phone, .pad:
        return 0.25 // Fast animations for touch interfaces
    case .vision:
        return 0.3 // Slightly slower for immersive experience
    case .mac:
        return 0.3 // Slightly slower for desktop
    case .watch:
        return 0.15 // Very fast for watch
    case .tv:
        return 0.4 // Slower for TV viewing
    case .car:
        return 0.2 // Fast for CarPlay safety
    }
}
