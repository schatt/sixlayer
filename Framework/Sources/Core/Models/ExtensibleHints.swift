//
//  ExtensibleHints.swift
//  SixLayerFramework
//
//  Extensible hints system for framework users
//

import Foundation
import SwiftUI

// MARK: - Extensible Hints Protocol

/// Protocol that allows framework users to define custom hint types
public protocol ExtensibleHint: Sendable {
    /// Unique identifier for the hint type
    var hintType: String { get }
    
    /// Priority level for this hint (higher = more important)
    var priority: HintPriority { get }
    
    /// Whether this hint should override default framework behavior
    var overridesDefault: Bool { get }
    
    /// Custom data associated with this hint
    var customData: [String: Any] { get }
}

/// Hint priority levels
public enum HintPriority: Int, CaseIterable, Comparable, Sendable {
    case low = 1
    case normal = 5
    case high = 10
    case critical = 15
    
    public static func < (lhs: HintPriority, rhs: HintPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Framework User Extensibility

/// Base class for framework users to create custom hints.
///
/// **Sendable:** `@unchecked Sendable` because ``ExtensibleHint`` requires `Sendable` but
/// ``customData`` is `[String: Any]`. Prefer typed hint structs or `[String: String]` metadata
/// when crossing actors; audit before adding new `@unchecked` conformers.
open class CustomHint: ExtensibleHint, @unchecked Sendable {
    public let hintType: String
    public let priority: HintPriority
    public let overridesDefault: Bool
    public let customData: [String: Any]
    
    public init(
        hintType: String,
        priority: HintPriority = .normal,
        overridesDefault: Bool = false,
        customData: [String: Any] = [:]
    ) {
        self.hintType = hintType
        self.priority = priority
        self.overridesDefault = overridesDefault
        self.customData = customData
    }
}

/// Example of how framework users can create custom hints
public extension CustomHint {
    /// Create a hint for e-commerce product display
    static func forEcommerceProduct(
        category: String,
        showPricing: Bool = true,
        showReviews: Bool = true,
        layoutStyle: String = "grid"
    ) -> CustomHint {
        return CustomHint(
            hintType: "ecommerce.product",
            priority: .high,
            overridesDefault: false,
            customData: [
                "category": category,
                "showPricing": showPricing,
                "showReviews": showReviews,
                "layoutStyle": layoutStyle,
                "recommendedColumns": 3,
                "showWishlist": true
            ]
        )
    }
    
    /// Create a hint for social media feed
    static func forSocialFeed(
        contentType: String,
        showInteractions: Bool = true,
        autoPlay: Bool = false
    ) -> CustomHint {
        return CustomHint(
            hintType: "social.feed",
            priority: .normal,
            overridesDefault: false,
            customData: [
                "contentType": contentType,
                "showInteractions": showInteractions,
                "autoPlay": autoPlay,
                "infiniteScroll": true,
                "pullToRefresh": true
            ]
        )
    }
    
    /// Create a hint for financial dashboard
    static func forFinancialDashboard(
        timeRange: String,
        showCharts: Bool = true,
        refreshRate: Int = 60
    ) -> CustomHint {
        return CustomHint(
            hintType: "financial.dashboard",
            priority: .critical,
            overridesDefault: true,
            customData: [
                "timeRange": timeRange,
                "showCharts": showCharts,
                "refreshRate": refreshRate,
                "realTimeUpdates": true,
                "exportEnabled": true,
                "drillDownEnabled": true
            ]
        )
    }
}

// MARK: - Enhanced Presentation Hints

/// Enhanced presentation hints that support custom extensible hints
public struct EnhancedPresentationHints: Sendable {
    public let dataType: DataTypeHint
    public let presentationPreference: PresentationPreference
    public let complexity: ContentComplexity
    public let context: PresentationContext
    public let customPreferences: [String: String]
    public let extensibleHints: [ExtensibleHint]
    
    /// Field-level display hints keyed by field ID
    public let fieldHints: [String: FieldDisplayHints]
    
    /// Optional deterministic field ordering rules (non-breaking default: nil)
    public let fieldOrderRules: FieldOrderRules?
    
    public init(
        dataType: DataTypeHint,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:],
        extensibleHints: [ExtensibleHint] = [],
        fieldHints: [String: FieldDisplayHints] = [:],
        fieldOrderRules: FieldOrderRules? = nil
    ) {
        self.dataType = dataType
        self.presentationPreference = presentationPreference
        self.complexity = complexity
        self.context = context
        self.customPreferences = customPreferences
        self.extensibleHints = extensibleHints
        self.fieldHints = fieldHints
        self.fieldOrderRules = fieldOrderRules
    }
    
    /// Get field-level hints for a specific field
    public func hints(forFieldId fieldId: String) -> FieldDisplayHints? {
        return fieldHints[fieldId]
    }
    
    /// Check if hints exist for a specific field
    public func hasHints(forFieldId fieldId: String) -> Bool {
        return fieldHints[fieldId] != nil
    }
    
    /// Get hints of a specific type
        func hints<T: ExtensibleHint>(ofType type: T.Type) -> [T] {
        return extensibleHints.compactMap { $0 as? T }
    }
    
    /// Get the highest priority hint
    public var highestPriorityHint: ExtensibleHint? {
        return extensibleHints.max { $0.priority < $1.priority }
    }
    
    /// Check if any hints override default behavior
    public var hasOverridingHints: Bool {
        return extensibleHints.contains { $0.overridesDefault }
    }
    
    /// Get custom data from all hints
    public var allCustomData: [String: Any] {
        var combined: [String: Any] = [:]
        
        // Add custom preferences
        for (key, value) in customPreferences {
            combined[key] = value
        }
        
        // Add extensible hint data (higher priority hints override lower ones)
        let sortedHints = extensibleHints.sorted { $0.priority > $1.priority }
        for hint in sortedHints {
            for (key, value) in hint.customData {
                combined[key] = value
            }
        }
        
        return combined
    }
}

// MARK: - Hint Processing Engine

/// Engine that processes extensible hints and integrates them with framework decisions
public class HintProcessingEngine {
    
    /// Process hints to determine if they should override framework defaults
        static func shouldOverrideFramework(
        hints: EnhancedPresentationHints,
        for decisionType: String
    ) -> Bool {
        return hints.hasOverridingHints
    }
    
    /// Extract layout preferences from hints
        static func extractLayoutPreferences(
        from hints: EnhancedPresentationHints
    ) -> [String: Any] {
        var preferences: [String: Any] = [:]
        
        // Process extensible hints
        for hint in hints.extensibleHints {
            if let layoutData = hint.customData["layoutStyle"] {
                preferences["layoutStyle"] = layoutData
            }
            if let columns = hint.customData["recommendedColumns"] {
                preferences["columns"] = columns
            }
            if let spacing = hint.customData["spacing"] {
                preferences["spacing"] = spacing
            }
        }
        
        return preferences
    }
    
    /// Extract performance preferences from hints
        static func extractPerformancePreferences(
        from hints: EnhancedPresentationHints
    ) -> [String: Any] {
        var preferences: [String: Any] = [:]
        
        for hint in hints.extensibleHints {
            if let refreshRate = hint.customData["refreshRate"] {
                preferences["refreshRate"] = refreshRate
            }
            if let autoPlay = hint.customData["autoPlay"] {
                preferences["autoPlay"] = autoPlay
            }
            if let infiniteScroll = hint.customData["infiniteScroll"] {
                preferences["infiniteScroll"] = infiniteScroll
            }
        }
        
        return preferences
    }
    
    /// Extract accessibility preferences from hints
        static func extractAccessibilityPreferences(
        from hints: EnhancedPresentationHints
    ) -> [String: Any] {
        var preferences: [String: Any] = [:]
        
        for hint in hints.extensibleHints {
            if let showInteractions = hint.customData["showInteractions"] {
                preferences["showInteractions"] = showInteractions
            }
            if let drillDownEnabled = hint.customData["drillDownEnabled"] {
                preferences["drillDownEnabled"] = drillDownEnabled
            }
        }
        
        return preferences
    }
}

// MARK: - Framework User Integration Examples

/// Example of how framework users can integrate custom hints
public extension EnhancedPresentationHints {
    
    /// Create hints for a blog post list
    static func forBlogPosts(
        showExcerpts: Bool = true,
        showAuthor: Bool = true,
        showDate: Bool = true
    ) -> EnhancedPresentationHints {
        let blogHint = CustomHint(
            hintType: "blog.posts",
            priority: .normal,
            overridesDefault: false,
            customData: [
                "showExcerpts": showExcerpts,
                "showAuthor": showAuthor,
                "showDate": showDate,
                "layoutStyle": "list",
                "recommendedColumns": 1,
                "showReadMore": true,
                "estimatedReadingTime": true
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [blogHint]
        )
    }
    
    /// Create hints for a photo gallery
    static func forPhotoGallery(
        showMetadata: Bool = true,
        allowFullscreen: Bool = true,
        gridStyle: String = "masonry"
    ) -> EnhancedPresentationHints {
        let photoHint = CustomHint(
            hintType: "photo.gallery",
            priority: .high,
            overridesDefault: false,
            customData: [
                "showMetadata": showMetadata,
                "allowFullscreen": allowFullscreen,
                "gridStyle": gridStyle,
                "lazyLoading": true,
                "zoomEnabled": true,
                "shareEnabled": true
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .media,
            presentationPreference: .masonry,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [photoHint]
        )
    }
}
