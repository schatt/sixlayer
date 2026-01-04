//
//  PlatformNavigationDecisionLayer2.swift
//  SixLayerFramework
//
//  Layer 2: Navigation Decision Engine
//  Content-aware navigation decision making (NOT platform-aware)
//

import SwiftUI
import Foundation

// MARK: - Layer 2: Navigation Decision Engine
// This layer analyzes content and makes navigation decisions based on content characteristics
// It is CONTENT-AWARE but NOT platform-aware (platform decisions happen in Layer 3)

// MARK: - Navigation Decision Data Structure

/// Navigation decision result from Layer 2 analysis
public struct NavigationStackDecision: Sendable {
    public let strategy: NavigationStrategy?
    public let reasoning: String?
    
    public init(
        strategy: NavigationStrategy?,
        reasoning: String?
    ) {
        self.strategy = strategy
        self.reasoning = reasoning
    }
}

// MARK: - Navigation Decision Functions

/// Determine optimal navigation strategy based on content analysis
/// Analyzes content characteristics and makes navigation decisions
/// This is CONTENT-AWARE but NOT platform-aware
///
/// - Parameters:
///   - items: Collection of items to navigate
///   - hints: Presentation hints that guide navigation decisions
/// - Returns: Navigation decision with recommended strategy and reasoning
@MainActor
public func determineNavigationStackStrategy_L2<Item: Identifiable>(
    items: [Item],
    hints: PresentationHints
) -> NavigationStackDecision {
    
    // Analyze content characteristics
    let analysis = DataIntrospectionEngine.analyzeCollection(items)
    
    // Check hints first for explicit preferences
    switch hints.presentationPreference {
    case .navigation:
        return NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "Navigation strategy selected based on explicit hints preference"
        )
    case .detail:
        return NavigationStackDecision(
            strategy: .splitView,
            reasoning: "Split view strategy selected based on detail preference in hints"
        )
    case .modal:
        return NavigationStackDecision(
            strategy: .modal,
            reasoning: "Modal strategy selected based on modal preference in hints"
        )
    default:
        break // Let other logic handle countBased and other preferences
    }
    
    // Analyze data characteristics to determine optimal strategy
    // This is content-aware analysis, not platform-aware
    let strategy: NavigationStrategy
    let reasoning: String
    
    switch (analysis.collectionType, analysis.itemComplexity) {
    case (.empty, _):
        strategy = .navigationStack
        reasoning = "Empty collection: NavigationStack provides clean empty state handling"
        
    case (.single, _):
        strategy = .navigationStack
        reasoning = "Single item: NavigationStack provides simple navigation pattern"
        
    case (.small, .simple):
        strategy = .navigationStack
        reasoning = "Small simple collection: NavigationStack provides efficient navigation"
        
    case (.small, .moderate):
        strategy = .navigationStack
        reasoning = "Small moderate collection: NavigationStack handles moderate complexity well"
        
    case (.medium, .simple):
        strategy = .navigationStack
        reasoning = "Medium simple collection: NavigationStack scales well for simple content"
        
    case (.medium, .moderate):
        // For medium moderate, could go either way - prefer NavigationStack for consistency
        strategy = .navigationStack
        reasoning = "Medium moderate collection: NavigationStack provides consistent navigation"
        
    case (.medium, .complex):
        // Complex content might benefit from split view, but NavigationStack can handle it
        strategy = .adaptive
        reasoning = "Medium complex collection: Adaptive strategy allows platform-specific optimization"
        
    case (.large, .simple):
        strategy = .adaptive
        reasoning = "Large simple collection: Adaptive strategy optimizes for platform capabilities"
        
    case (.large, .moderate):
        strategy = .adaptive
        reasoning = "Large moderate collection: Adaptive strategy balances navigation and detail views"
        
    case (.large, .complex):
        strategy = .adaptive
        reasoning = "Large complex collection: Adaptive strategy handles complex navigation needs"
        
    case (.veryLarge, _):
        strategy = .adaptive
        reasoning = "Very large collection: Adaptive strategy optimizes for performance and usability"
        
    default:
        strategy = .adaptive
        reasoning = "Default: Adaptive strategy provides best platform-specific experience"
    }
    
    return NavigationStackDecision(
        strategy: strategy,
        reasoning: reasoning
    )
}

// MARK: - App Navigation Decision Functions

/// App navigation decision result from Layer 2 analysis
public struct AppNavigationDecision: Sendable {
    public let useSplitView: Bool
    public let reasoning: String
    
    public init(
        useSplitView: Bool,
        reasoning: String
    ) {
        self.useSplitView = useSplitView
        self.reasoning = reasoning
    }
}

// MARK: - App Navigation Decision Constants

/// Minimum screen width (in landscape) to consider split view for iPhone
private let iPhoneLandscapeSplitViewThreshold: CGFloat = 900

// MARK: - App Navigation Decision Helpers

/// Check if orientation is landscape
private func isLandscapeOrientation(_ orientation: DeviceOrientation) -> Bool {
    return orientation == .landscape || 
           orientation == .landscapeLeft || 
           orientation == .landscapeRight
}

/// Determine if iPhone landscape should use split view based on screen dimensions
private func shouldUseSplitViewForiPhoneLandscape(
    maxDimension: CGFloat,
    sizeCategory: iPhoneSizeCategory?
) -> (useSplitView: Bool, reasoning: String) {
    if maxDimension >= iPhoneLandscapeSplitViewThreshold {
        if let category = sizeCategory {
            return (
                useSplitView: true,
                reasoning: "iPhone \(category.rawValue) landscape with width >= \(Int(iPhoneLandscapeSplitViewThreshold)): Split view utilizes larger screen effectively"
            )
        } else {
            return (
                useSplitView: true,
                reasoning: "iPhone landscape with width >= \(Int(iPhoneLandscapeSplitViewThreshold)): Split view utilizes larger screen effectively"
            )
        }
    } else {
        if let category = sizeCategory {
            return (
                useSplitView: false,
                reasoning: "iPhone \(category.rawValue) landscape: Detail-only view maintains mobile-first experience"
            )
        } else {
            return (
                useSplitView: false,
                reasoning: "iPhone landscape: Detail-only view maintains mobile-first experience"
            )
        }
    }
}

/// Determine optimal app navigation pattern based on device capabilities and orientation
/// Analyzes device type, orientation, and screen size to decide between split view and detail-only
/// This is DEVICE-AWARE and ORIENTATION-AWARE but NOT platform-aware (platform decisions happen in Layer 3)
///
/// - Parameters:
///   - deviceType: Current device type
///   - orientation: Current device orientation
///   - screenSize: Current screen size
///   - iPhoneSizeCategory: iPhone size category (if device is iPhone)
/// - Returns: App navigation decision with recommended pattern and reasoning
@MainActor
public func determineAppNavigationStrategy_L2(
    deviceType: DeviceType,
    orientation: DeviceOrientation,
    screenSize: CGSize,
    iPhoneSizeCategory: iPhoneSizeCategory? = nil
) -> AppNavigationDecision {
    
    // iPad: Always use split view (regardless of orientation)
    if deviceType == .pad {
        return AppNavigationDecision(
            useSplitView: true,
            reasoning: "iPad: Split view provides optimal navigation experience on larger screens"
        )
    }
    
    // macOS: Always use split view
    if deviceType == .mac {
        return AppNavigationDecision(
            useSplitView: true,
            reasoning: "macOS: Split view is the standard navigation pattern for desktop"
        )
    }
    
    // iPhone: Decision depends on orientation and screen size
    if deviceType == .phone {
        // iPhone in portrait: Always detail-only (sidebar as sheet)
        if !isLandscapeOrientation(orientation) {
            return AppNavigationDecision(
                useSplitView: false,
                reasoning: "iPhone portrait: Detail-only view with sidebar as sheet provides optimal mobile experience"
            )
        }
        
        // iPhone in landscape: Consider screen size and category
        let maxDimension = max(screenSize.width, screenSize.height)
        
        if let sizeCategory = iPhoneSizeCategory {
            switch sizeCategory {
            case .plus, .proMax:
                // Large iPhones in landscape: Always use split view
                return AppNavigationDecision(
                    useSplitView: true,
                    reasoning: "iPhone \(sizeCategory.rawValue) landscape: Split view utilizes larger screen effectively"
                )
            case .pro:
                // Pro models: Check screen width threshold
                let decision = shouldUseSplitViewForiPhoneLandscape(
                    maxDimension: maxDimension,
                    sizeCategory: sizeCategory
                )
                return AppNavigationDecision(
                    useSplitView: decision.useSplitView,
                    reasoning: decision.reasoning
                )
            case .standard, .mini:
                // Standard and mini iPhones: Detail-only even in landscape
                return AppNavigationDecision(
                    useSplitView: false,
                    reasoning: "iPhone \(sizeCategory.rawValue) landscape: Detail-only view maintains mobile-first experience"
                )
            case .unknown:
                // Unknown size: Use screen dimensions as fallback
                let decision = shouldUseSplitViewForiPhoneLandscape(
                    maxDimension: maxDimension,
                    sizeCategory: nil
                )
                return AppNavigationDecision(
                    useSplitView: decision.useSplitView,
                    reasoning: decision.reasoning
                )
            }
        } else {
            // No size category available: Use screen dimensions as fallback
            let decision = shouldUseSplitViewForiPhoneLandscape(
                maxDimension: maxDimension,
                sizeCategory: nil
            )
            return AppNavigationDecision(
                useSplitView: decision.useSplitView,
                reasoning: decision.reasoning
            )
        }
    }
    
    // Default fallback: Detail-only for unknown device types
    return AppNavigationDecision(
        useSplitView: false,
        reasoning: "Unknown device type: Defaulting to detail-only view"
    )
}

