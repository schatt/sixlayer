//
//  PlatformLayoutDecisionLayer2.swift
//  SixLayerFramework
//
//  Level 2: Layout Decision Engine - Content-aware layout analysis and decision making
//

import SwiftUI
import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

// MARK: - Layer 2: Layout Decision Engine
// This layer analyzes content and makes layout decisions based on content characteristics
// It is CONTENT-AWARE but NOT platform-aware (platform decisions happen in Layer 3)

// MARK: - Generic Layout Decision Functions

/// Determine optimal layout for any collection of items
/// Analyzes content characteristics and makes layout decisions
@MainActor
    func determineOptimalLayout_L2<Item: Identifiable>(
    items: [Item],
    hints: PresentationHints,
    screenWidth: CGFloat? = nil,
    deviceType: DeviceType? = nil
) -> GenericLayoutDecision {
    
    // Analyze content characteristics
    let itemCount = items.count
    let complexity = analyzeContentComplexity(itemCount: itemCount, hints: hints)
    
    // Get device capabilities - use provided context if available, otherwise detect
    let deviceCapabilities: DeviceCapabilities
    if let width = screenWidth, let _ = deviceType {
        // Use provided device context for more accurate decisions
        deviceCapabilities = DeviceCapabilities(
            screenSize: CGSize(width: width, height: width * 0.75), // Approximate aspect ratio
            orientation: DeviceOrientation.portrait,
            memoryAvailable: 1024 * 1024 * 1024
        )
    } else {
        // Fall back to auto-detection
        deviceCapabilities = getCurrentDeviceCapabilities()
    }
    
    // Make layout decisions based on content analysis
    let layoutApproach = chooseLayoutApproach(complexity: complexity, capabilities: deviceCapabilities)
    let columns = calculateOptimalColumns(itemCount: itemCount, complexity: complexity, capabilities: deviceCapabilities)
    let spacing = calculateOptimalSpacing(complexity: complexity, capabilities: deviceCapabilities)
    let performance = choosePerformanceStrategy(complexity: complexity, capabilities: deviceCapabilities)
    
    return GenericLayoutDecision(
        approach: layoutApproach,
        columns: columns,
        spacing: spacing,
        performance: performance,
        reasoning: generateLayoutReasoning(approach: layoutApproach, columns: columns, spacing: spacing, performance: performance)
    )
}

/// Determine optimal form layout based on content analysis
@MainActor
    func determineOptimalFormLayout_L2(
    hints: PresentationHints
) -> GenericFormLayoutDecision {
    
    // Analyze form content complexity based on hints
    let fieldCount = Int(hints.customPreferences["fieldCount"] ?? "5") ?? 5
    let hasComplexFields = hints.customPreferences["hasComplexFields"] == "true"
    let hasValidation = hints.customPreferences["hasValidation"] == "true"
    
    // Content complexity analysis
    let contentComplexity: ContentComplexity = {
        if fieldCount >= 8 && hasComplexFields && hasValidation {
            return .complex
        } else if fieldCount >= 5 {
            return .moderate
        } else {
            return .simple
        }
    }()
    
    // Layout decision based on content analysis (not platform!)
    return GenericFormLayoutDecision(
        preferredContainer: .adaptive, // Let Layer 3 decide Form vs ScrollView based on platform
        fieldLayout: .standard, // Standard forms work well with standard layout
        spacing: .comfortable, // Complex forms need breathing room
        validation: hasValidation ? .realTime : .none, // Use validation if specified
        contentComplexity: contentComplexity,
        reasoning: "Form layout optimized based on field count and complexity"
    )
}

// MARK: - Content Analysis Functions

private func analyzeContentComplexity(itemCount: Int, hints: PresentationHints) -> ContentComplexity {
    switch itemCount {
    case 0...5:
        return .simple
    case 6...9:
        return .moderate
    case 10...25:
        return .complex
    default:
        return .veryComplex
    }
}

private func chooseLayoutApproach(complexity: ContentComplexity, capabilities: DeviceCapabilities) -> LayoutApproach {
    switch complexity {
    case .simple:
        return .uniform
    case .moderate:
        return .adaptive
    case .complex:
        return .responsive
    case .veryComplex:
        return .dynamic
    case .advanced:
        return .dynamic
    }
}

private func calculateOptimalColumns(itemCount: Int, complexity: ContentComplexity, capabilities: DeviceCapabilities) -> Int {
    let baseColumns = max(1, min(6, itemCount / 3))
    
    // Apply complexity-based limits
    let complexityLimit: Int
    switch complexity {
    case .simple:
        complexityLimit = 3
    case .moderate:
        complexityLimit = 4
    case .complex:
        complexityLimit = 5
    case .veryComplex:
        complexityLimit = 6
    case .advanced:
        complexityLimit = 6
    }
    
    // Apply device capability limits
    let deviceLimit: Int
    if capabilities.screenSize.width < 768 { // Mobile/phone
        deviceLimit = 2
    } else if capabilities.screenSize.width < 1024 { // Tablet
        deviceLimit = 3
    } else { // Desktop
        deviceLimit = 6
    }
    
    // Return the most restrictive limit
    return min(baseColumns, complexityLimit, deviceLimit)
}

private func calculateOptimalSpacing(complexity: ContentComplexity, capabilities: DeviceCapabilities) -> CGFloat {
    switch complexity {
    case .simple:
        return 8
    case .moderate:
        return 16
    case .complex:
        return 24
    case .veryComplex:
        return 32
    case .advanced:
        return 32
    }
}

private func choosePerformanceStrategy(complexity: ContentComplexity, capabilities: DeviceCapabilities) -> PerformanceStrategy {
    switch complexity {
    case .simple:
        return .standard
    case .moderate:
        return .optimized
    case .complex:
        return .highPerformance
    case .veryComplex:
        return .maximumPerformance
    case .advanced:
        return .maximumPerformance
    }
}

@MainActor
private func getCurrentDeviceCapabilities() -> DeviceCapabilities {
    return DeviceCapabilities()
}

// MARK: - Data Structures

/// Generic layout decision structure
public struct GenericLayoutDecision {
    public let approach: LayoutApproach
    public let columns: Int
    public let spacing: CGFloat
    public let performance: PerformanceStrategy
    public let reasoning: String
    
    public init(
        approach: LayoutApproach,
        columns: Int,
        spacing: CGFloat,
        performance: PerformanceStrategy,
        reasoning: String
    ) {
        self.approach = approach
        self.columns = columns
        self.spacing = spacing
        self.performance = performance
        self.reasoning = reasoning
    }
}

/// Generic form layout decision structure
public struct GenericFormLayoutDecision {
    public let preferredContainer: ContainerPreference
    public let fieldLayout: FieldLayout
    public let spacing: SpacingPreference
    public let validation: ValidationStrategy
    public let contentComplexity: ContentComplexity
    public let reasoning: String
    
    public init(
        preferredContainer: ContainerPreference,
        fieldLayout: FieldLayout,
        spacing: SpacingPreference,
        validation: ValidationStrategy,
        contentComplexity: ContentComplexity,
        reasoning: String
    ) {
        self.preferredContainer = preferredContainer
        self.fieldLayout = fieldLayout
        self.spacing = spacing
        self.validation = validation
        self.contentComplexity = contentComplexity
        self.reasoning = reasoning
    }
}

// Layout approach is defined in PlatformTypes.swift to avoid duplication



/// Container preference (content-based, not platform-based)
public enum ContainerPreference: String, CaseIterable {
    case adaptive = "adaptive"         // Let Layer 3 choose based on platform capabilities
    case structured = "structured"     // Prefer structured container (Form-like)
    case flexible = "flexible"         // Prefer flexible container (ScrollView-like)
}



/// Performance strategy
public enum PerformanceStrategy: String, CaseIterable {
    case standard = "standard"         // Standard performance
    case optimized = "optimized"       // Optimized performance
    case highPerformance = "highPerformance" // High performance
    case maximumPerformance = "maximumPerformance" // Maximum performance
}

/// Device capabilities for layout decisions
public struct DeviceCapabilities {
    public let screenSize: CGSize
    public let orientation: DeviceOrientation
    public let memoryAvailable: Int64
    
    @MainActor
    public init() {
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            self.screenSize = window.bounds.size
        } else {
            self.screenSize = UIScreen.main.bounds.size
        }
        self.orientation = DeviceOrientation.fromUIDeviceOrientation(UIDevice.current.orientation)
        #elseif os(tvOS)
        self.screenSize = UIScreen.main.bounds.size
        self.orientation = .landscape
        #elseif os(visionOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            self.screenSize = window.bounds.size
        } else {
            self.screenSize = CGSize(width: 1280, height: 720)
        }
        self.orientation = .unknown
        #elseif os(watchOS)
        self.screenSize = WKInterfaceDevice.current().screenBounds.size
        self.orientation = .portrait
        #else
        self.screenSize = CGSize(width: 1024, height: 768)
        self.orientation = .portrait
        #endif
        
        // Placeholder for memory availability
        self.memoryAvailable = 1024 * 1024 * 1024 // 1GB default
    }
    
    public init(screenSize: CGSize, orientation: DeviceOrientation, memoryAvailable: Int64) {
        self.screenSize = screenSize
        self.orientation = orientation
        self.memoryAvailable = memoryAvailable
    }
}

/// Cross-platform device orientation
public enum DeviceOrientation: String, CaseIterable {
    case portrait = "portrait"
    case landscape = "landscape"
    case portraitUpsideDown = "portraitUpsideDown"
    case landscapeLeft = "landscapeLeft"
    case landscapeRight = "landscapeRight"
    case flat = "flat"
    case unknown = "unknown"
    
    #if os(iOS)
    static func fromUIDeviceOrientation(_ uiOrientation: UIDeviceOrientation) -> DeviceOrientation {
        switch uiOrientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .faceUp: return .flat
        case .faceDown: return .flat
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
    #endif
}

// Responsive behavior types are defined in PlatformTypes.swift to avoid duplication





// MARK: - Helper Functions

private func generateLayoutReasoning(approach: LayoutApproach, columns: Int, spacing: CGFloat, performance: PerformanceStrategy) -> String {
    return "Layout optimized for current device and content: \(approach.rawValue) approach with \(columns) columns, \(spacing)pt spacing, and \(performance.rawValue) performance"
}

// MARK: - Card Layout Decision Functions

private func cardLayoutDeviceColumnLimit(deviceType: DeviceType) -> Int {
    switch deviceType {
    case .phone, .car:
        return 2
    case .vision, .watch:
        return 1
    case .pad:
        return 3
    case .mac, .tv:
        return 4
    }
}

private func maximumCardColumnsForWidth(_ screenWidth: CGFloat, minimumCellWidth: CGFloat = 158) -> Int {
    max(1, Int(floor(screenWidth / minimumCellWidth)))
}

/// Row height for responsive demo cards: uses viewport budget when height is finite; otherwise 120pt default.
private func recommendedOptimalCardRowHeight(
    contentCount: Int,
    columns: Int,
    spacing: CGFloat,
    viewportHeight: CGFloat?
) -> CGFloat {
    let fallback: CGFloat = 120
    guard let viewport = viewportHeight, viewport.isFinite, viewport > 0, contentCount > 0 else {
        return fallback
    }
    let cols = max(1, columns)
    let rows = max(1, Int(ceil(Double(contentCount) / Double(cols))))
    let layoutPadding: CGFloat = 16
    let verticalChrome = layoutPadding * 2 + CGFloat(max(0, rows - 1)) * spacing
    let budget = viewport - verticalChrome
    guard budget.isFinite, budget > 0 else { return fallback }
    let perRow = budget / CGFloat(rows)
    return max(64, min(fallback, perRow))
}

private func refineOptimalCardColumnsForViewport(
    contentCount: Int,
    screenWidth: CGFloat,
    deviceType: DeviceType,
    spacing: CGFloat,
    viewportHeight: CGFloat?,
    widthBasedColumns: Int
) -> Int {
    guard let viewport = viewportHeight, viewport.isFinite, viewport > 0, contentCount > 0 else {
        return max(1, widthBasedColumns)
    }
    let deviceCap = cardLayoutDeviceColumnLimit(deviceType: deviceType)
    let widthCap = maximumCardColumnsForWidth(screenWidth)
    let cMax = max(1, min(deviceCap, widthCap))
    let cStart = max(1, min(widthBasedColumns, cMax))
    var bestColumns = cStart
    var bestRowHeight = recommendedOptimalCardRowHeight(
        contentCount: contentCount,
        columns: bestColumns,
        spacing: spacing,
        viewportHeight: viewport
    )
    for candidateColumns in cStart...cMax {
        let rowHeight = recommendedOptimalCardRowHeight(
            contentCount: contentCount,
            columns: candidateColumns,
            spacing: spacing,
            viewportHeight: viewport
        )
        if rowHeight > bestRowHeight + 0.5 {
            bestRowHeight = rowHeight
            bestColumns = candidateColumns
        }
    }
    return bestColumns
}

/// Determine optimal card layout for the given content and device
/// Layer 2: Layout Decision
@MainActor
    func determineOptimalCardLayout_L2(
    contentCount: Int,
    screenWidth: CGFloat,
    deviceType: DeviceType,
    contentComplexity: ContentComplexity,
    viewportHeight: CGFloat? = nil
) -> CardLayoutDecision {
    
    // Analyze content and device capabilities
    let analysis = analyzeCardContent(
        count: contentCount,
        width: screenWidth,
        device: deviceType,
        complexity: contentComplexity
    )
    
    // Choose optimal approach
    let approach = analysis.recommendedApproach
    let widthBasedColumns = calculateOptimalCardColumns(
        screenWidth: screenWidth,
        deviceType: deviceType,
        contentComplexity: contentComplexity
    )
    let spacing = analysis.optimalSpacing
    let columns = refineOptimalCardColumnsForViewport(
        contentCount: contentCount,
        screenWidth: screenWidth,
        deviceType: deviceType,
        spacing: spacing,
        viewportHeight: viewportHeight,
        widthBasedColumns: widthBasedColumns
    )
    let cardRowHeight = recommendedOptimalCardRowHeight(
        contentCount: contentCount,
        columns: columns,
        spacing: spacing,
        viewportHeight: viewportHeight
    )
    let responsive = determineResponsiveBehavior(
        deviceType: deviceType,
        contentComplexity: contentComplexity
    )
    
    let _ = generateStrategyReasoning(
        approach: approach,
        columns: columns,
        spacing: spacing,
        responsive: responsive
    )
    
    return CardLayoutDecision(
        layout: .uniform,
        sizing: .adaptive,
        interaction: .tap,
        responsive: ResponsiveBehavior(
            type: .adaptive,
            breakpoints: [320, 768, 1024, 1440],
            adaptive: true
        ),
        spacing: spacing,
        columns: columns,
        viewportHeight: viewportHeight,
        cardRowHeight: cardRowHeight
    )
}

/// Analyze card content for layout decisions
@MainActor
private func analyzeCardContent(
    count: Int,
    width: CGFloat,
    device: DeviceType,
    complexity: ContentComplexity
) -> ContentAnalysis {
    
    var considerations: [String] = []
    
    if complexity == .complex || complexity == .veryComplex {
        considerations.append("Optimize rendering for complex content")
    }
    
    if device == .phone && count > 10 {
        considerations.append("Prioritize performance on mobile devices")
    }
    
    // Use the spacing calculation function instead of hardcoding
    let deviceCapabilities = DeviceCapabilities()
    let optimalSpacing = calculateOptimalSpacing(complexity: complexity, capabilities: deviceCapabilities)
    
    return ContentAnalysis(
        recommendedApproach: .adaptive,
        optimalSpacing: optimalSpacing,
        performanceConsiderations: considerations
    )
}

/// Calculate optimal number of columns for card layouts based on screen width and device
private func calculateOptimalCardColumns(
    screenWidth: CGFloat,
    deviceType: DeviceType,
    contentComplexity: ContentComplexity
) -> Int {
    // Base columns based on screen width
    let baseColumns: Int
    if screenWidth < 768 { // Mobile/phone
        baseColumns = 1
    } else if screenWidth < 1024 { // Tablet
        baseColumns = 2
    } else if screenWidth < 1440 { // Small desktop
        baseColumns = 3
    } else { // Large desktop
        baseColumns = 4
    }
    
    // Adjust based on content complexity - simple content uses fewer columns
    let complexityAdjustment: Int
    switch contentComplexity {
    case .simple:
        complexityAdjustment = -1 // Reduce columns for simple content
    case .moderate:
        complexityAdjustment = 0  // No adjustment
    case .complex:
        complexityAdjustment = 1  // Increase columns for complex content
    case .veryComplex:
        complexityAdjustment = 1  // Increase columns for very complex content
    case .advanced:
        complexityAdjustment = 1  // Increase columns for advanced content
    }
    
    let adjustedColumns = max(1, baseColumns + complexityAdjustment)
    return min(adjustedColumns, cardLayoutDeviceColumnLimit(deviceType: deviceType))
}



/// Generate strategy reasoning for card layout
private func generateStrategyReasoning(
    approach: LayoutApproach,
    columns: Int,
    spacing: CGFloat,
    responsive: ResponsiveBehavior
) -> String {
    
    var reasoning = "Selected \(approach.rawValue) layout with \(columns) columns"
    
    if responsive.adaptive {
        reasoning += " and adaptive behavior"
    }
    
    reasoning += " for optimal user experience"
    
    return reasoning
}
