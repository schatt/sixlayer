//
//  PlatformTypes.swift
//  SixLayerFramework
//
//  Core platform and device type definitions for the 6-layer architecture
//

import Foundation
import SwiftUI

// MARK: - Platform Enumeration

/// Represents the target platform for optimization and adaptation
public enum SixLayerPlatform: String, CaseIterable, Sendable {
    case iOS = "iOS"
    case macOS = "macOS"
    case watchOS = "watchOS"
    case tvOS = "tvOS"
    case visionOS = "visionOS"
    
    /// Current platform detection (compile-time only)
    public static var current: SixLayerPlatform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .iOS // Default fallback
        #endif
    }
    
    /// Current platform detection (uses compile-time platform detection)
    /// Tests should run on actual platforms/simulators to test platform-specific behavior
    public static var currentPlatform: SixLayerPlatform {
        return current
    }
    
    /// Current device type detection (uses compile-time device type detection)
    /// Tests should run on actual platforms/simulators to test platform-specific behavior
    @MainActor
    public static var deviceType: DeviceType {
        return DeviceType.current
    }
    
    /// Derive device type from platform for testing purposes
    private static func deriveDeviceTypeFromPlatform(_ platform: SixLayerPlatform) -> DeviceType {
        switch platform {
        case .iOS:
            // For iOS testing, default to phone unless specifically testing iPad
            // This could be enhanced with a specific test device type override
            return .phone
        case .macOS:
            return .mac
        case .watchOS:
            return .watch
        case .tvOS:
            return .tv
        case .visionOS:
            // visionOS doesn't have a specific DeviceType, use tv as placeholder
            return .tv
        }
    }
}

// MARK: - Device Type Enumeration

/// Represents the device type for responsive design and optimization
public enum DeviceType: String, CaseIterable, Sendable {
    case phone = "phone"
    case pad = "pad"
    case mac = "mac"
    case tv = "tv"
    case watch = "watch"
    case car = "car"
    case vision = "vision"
    
    /// Current device type detection
    @MainActor
    public static var current: DeviceType {
        #if os(iOS)
        // Check for CarPlay first
        if CarPlayCapabilityDetection.isCarPlayActive {
            return .car
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .pad
        } else {
            return .phone
        }
        #elseif os(macOS)
        return .mac
        #elseif os(watchOS)
        return .watch
        #elseif os(tvOS)
        return .tv
        #else
        return .phone // Default fallback
        #endif
    }
    
    /// Detect device type from screen size
    public static func from(screenSize: CGSize) -> DeviceType {
        let width = screenSize.width
        let height = screenSize.height
        let minDimension = min(width, height)
        let maxDimension = max(width, height)
        
        #if os(iOS)
        // iOS device detection based on screen dimensions
        if minDimension >= 768 {
            return .pad
        } else {
            return .phone
        }
        #elseif os(macOS)
        return .mac
        #elseif os(watchOS)
        return .watch
        #elseif os(tvOS)
        return .tv
        #else
        // Fallback based on screen size
        if minDimension >= 768 {
            return .pad
        } else if minDimension >= 162 && maxDimension >= 197 {
            return .watch
        } else if minDimension >= 1920 {
            return .tv
        } else {
            return .phone
        }
        #endif
    }
}

// MARK: - Device Context Enumeration

/// Represents the context in which the app is running for specialized optimizations
public enum DeviceContext: String, CaseIterable {
    case standard = "standard"
    case carPlay = "carPlay"
    case externalDisplay = "externalDisplay"
    case splitView = "splitView"
    case stageManager = "stageManager"
    
    /// Current device context detection
    @MainActor
    public static var current: DeviceContext {
        #if os(iOS)
        // Check for CarPlay
        if CarPlayCapabilityDetection.isCarPlayActive {
            return .carPlay
        }
        
        // Check for external display
        if #available(iOS 16.0, *) {
            // Use the new API
            if UIApplication.shared.openSessions.count > 1 {
                return .externalDisplay
            }
        } else {
            // Use the deprecated API for older iOS versions
            if UIScreen.screens.count > 1 {
                return .externalDisplay
            }
        }
        
        // Check for split view (iPad only)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if windowScene.traitCollection.horizontalSizeClass == .regular &&
                   windowScene.traitCollection.verticalSizeClass == .regular {
                    return .splitView
                }
            }
        }
        
        return .standard
        #else
        return .standard
        #endif
    }
}

// MARK: - CarPlay Capability Detection

/// CarPlay-specific capability detection and optimization
public struct CarPlayCapabilityDetection {
    
    /// Whether CarPlay is currently active
    @MainActor
    public static var isCarPlayActive: Bool {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            // Check if we're in a CarPlay context
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.traitCollection.userInterfaceIdiom == .carPlay
            }
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Whether the app supports CarPlay
    public static var supportsCarPlay: Bool {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            return true
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Get CarPlay-specific device type
    @MainActor
    public static var carPlayDeviceType: DeviceType {
        return .car
    }
    
    /// Get CarPlay-optimized layout preferences
    public static var carPlayLayoutPreferences: CarPlayLayoutPreferences {
        return CarPlayLayoutPreferences(
            prefersLargeText: true,
            prefersHighContrast: true,
            prefersMinimalUI: true,
            supportsVoiceControl: true,
            supportsTouch: true,
            supportsKnobControl: true
        )
    }
    
    /// Check if specific CarPlay features are available
    @MainActor
    public static func isFeatureAvailable(_ feature: CarPlayFeature) -> Bool {
        guard isCarPlayActive else { return false }
        
        switch feature {
        case .navigation:
            return true
        case .music:
            return true
        case .phone:
            return true
        case .messages:
            return true
        case .voiceControl:
            return true
        case .knobControl:
            return true
        case .touchControl:
            return true
        }
    }
}

// MARK: - CarPlay Layout Preferences

/// CarPlay-specific layout and interaction preferences
public struct CarPlayLayoutPreferences {
    public let prefersLargeText: Bool
    public let prefersHighContrast: Bool
    public let prefersMinimalUI: Bool
    public let supportsVoiceControl: Bool
    public let supportsTouch: Bool
    public let supportsKnobControl: Bool
    
    public init(
        prefersLargeText: Bool = true,
        prefersHighContrast: Bool = true,
        prefersMinimalUI: Bool = true,
        supportsVoiceControl: Bool = true,
        supportsTouch: Bool = true,
        supportsKnobControl: Bool = true
    ) {
        self.prefersLargeText = prefersLargeText
        self.prefersHighContrast = prefersHighContrast
        self.prefersMinimalUI = prefersMinimalUI
        self.supportsVoiceControl = supportsVoiceControl
        self.supportsTouch = supportsTouch
        self.supportsKnobControl = supportsKnobControl
    }
}

// MARK: - CarPlay Features

/// Available CarPlay features for capability detection
public enum CarPlayFeature: String, CaseIterable {
    case navigation = "navigation"
    case music = "music"
    case phone = "phone"
    case messages = "messages"
    case voiceControl = "voiceControl"
    case knobControl = "knobControl"
    case touchControl = "touchControl"
}

// MARK: - Keyboard Type Enumeration

/// Represents different keyboard types for text input optimization
public enum KeyboardType: String, CaseIterable {
    case `default` = "default"
    case asciiCapable = "asciiCapable"
    case numbersAndPunctuation = "numbersAndPunctuation"
    case URL = "URL"
    case numberPad = "numberPad"
    case phonePad = "phonePad"
    case namePhonePad = "namePhonePad"
    case emailAddress = "emailAddress"
    case decimalPad = "decimalPad"
    case twitter = "twitter"
    case webSearch = "webSearch"
    
    /// Platform-specific decimal keyboard type
        static func platformDecimalKeyboardType() -> KeyboardType {
        #if os(iOS)
        return .decimalPad
        #else
        return .default
        #endif
    }
}

// MARK: - Form Content Metrics

/// Metrics for analyzing form content and determining optimal layout
public struct FormContentMetrics: Equatable, Sendable {
    public let fieldCount: Int
    public let estimatedComplexity: ContentComplexity
    public let preferredLayout: LayoutPreference
    public let sectionCount: Int
    public let hasComplexContent: Bool
    
    public init(
        fieldCount: Int,
        estimatedComplexity: ContentComplexity = .simple,
        preferredLayout: LayoutPreference = .adaptive,
        sectionCount: Int = 1,
        hasComplexContent: Bool = false
    ) {
        self.fieldCount = fieldCount
        self.estimatedComplexity = estimatedComplexity
        self.preferredLayout = preferredLayout
        self.sectionCount = sectionCount
        self.hasComplexContent = hasComplexContent
    }
}

// MARK: - Form Content Key

/// Preference key for form content metrics
public struct FormContentKey: PreferenceKey {
    public static let defaultValue: FormContentMetrics = FormContentMetrics(
        fieldCount: 0,
        estimatedComplexity: .simple,
        preferredLayout: .adaptive,
        sectionCount: 1,
        hasComplexContent: false
    )
    
        public static func reduce(value: inout FormContentMetrics, nextValue: () -> FormContentMetrics) {
        value = nextValue()
    }
}


// MARK: - Layout Preference

/// Represents the preferred layout approach for content
public enum LayoutPreference: String, CaseIterable, Sendable {
    case compact = "compact"
    case adaptive = "adaptive"
    case spacious = "spacious"
    case custom = "custom"
    case grid = "grid"
    case list = "list"
}

// MARK: - Platform Device Capabilities

/// Provides information about device capabilities for optimization
public struct PlatformDeviceCapabilities {
    /// Current device type
    @MainActor
    public static var deviceType: DeviceType {
        return DeviceType.current
    }
    
    /// Whether the device supports haptic feedback
    public static var supportsHapticFeedback: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Whether the device supports keyboard shortcuts
    public static var supportsKeyboardShortcuts: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Whether the device supports context menus
    public static var supportsContextMenus: Bool {
        #if os(macOS) || os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Whether the device supports CarPlay
    public static var supportsCarPlay: Bool {
        return CarPlayCapabilityDetection.supportsCarPlay
    }
    
    /// Whether CarPlay is currently active
    @MainActor
    public static var isCarPlayActive: Bool {
        return CarPlayCapabilityDetection.isCarPlayActive
    }
    
    /// Current device context
    @MainActor
    public static var deviceContext: DeviceContext {
        return DeviceContext.current
    }
}

// MARK: - Modal Platform Types

/// Represents the platform for modal presentations
public enum ModalPlatform: String, CaseIterable {
    case iOS = "iOS"
    case macOS = "macOS"
}

/// Represents different modal presentation types
public enum ModalPresentationType: String, CaseIterable {
    case sheet = "sheet"
    case popover = "popover"
    case fullScreen = "fullScreen"
    case custom = "custom"
}

/// Represents modal sizing options
public enum ModalSizing: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case custom = "custom"
}

/// Represents modal constraints for different platforms
public struct ModalConstraint {
    public let maxWidth: CGFloat?
    public let maxHeight: CGFloat?
    public let preferredSize: CGSize?
    
    public init(
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        preferredSize: CGSize? = nil
    ) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.preferredSize = preferredSize
    }
}

/// Represents platform adaptations for different devices
public enum PlatformAdaptation: String, CaseIterable {
    case largeFields = "largeFields"
    case standardFields = "standardFields"
    case compactFields = "compactFields"
}

// MARK: - Form Layout Types

/// Represents form layout decisions for different platforms
public struct FormLayoutDecision {
    public let containerType: FormContainerType
    public let fieldLayout: FieldLayout
    public let spacing: SpacingPreference
    public let validation: ValidationStrategy
    
    public init(
        containerType: FormContainerType,
        fieldLayout: FieldLayout,
        spacing: SpacingPreference,
        validation: ValidationStrategy
    ) {
        self.containerType = containerType
        self.fieldLayout = fieldLayout
        self.spacing = spacing
        self.validation = validation
    }
}

/// Represents form container types
public enum FormContainerType: String, CaseIterable {
    case form = "form"
    case scrollView = "scrollView"
    case custom = "custom"
    case adaptive = "adaptive"
    case standard = "standard"
}

/// Represents validation strategies
public enum ValidationStrategy: String, CaseIterable {
    case none = "none"
    case realTime = "realTime"
    case onSubmit = "onSubmit"
    case custom = "custom"
    case immediate = "immediate"
    case deferred = "deferred"
}

/// Represents spacing preferences
public enum SpacingPreference: String, CaseIterable {
    case compact = "compact"
    case comfortable = "comfortable"
    case generous = "generous"
    case standard = "standard"
    case spacious = "spacious"
}

/// Represents field layout strategies
public enum FieldLayout: String, CaseIterable {
    case standard = "standard"
    case compact = "compact"
    case spacious = "spacious"
    case adaptive = "adaptive"
    case vertical = "vertical"
    case horizontal = "horizontal"
    case grid = "grid"
}

/// Represents modal layout decisions
public struct ModalLayoutDecision {
    public let presentationType: ModalPresentationType
    public let sizing: ModalSizing
    public let detents: [SheetDetent]
    public let platformConstraints: [ModalPlatform: ModalConstraint]
    
    public init(
        presentationType: ModalPresentationType,
        sizing: ModalSizing,
        detents: [SheetDetent] = [],
        platformConstraints: [ModalPlatform: ModalConstraint] = [:]
    ) {
        self.presentationType = presentationType
        self.sizing = sizing
        self.detents = detents
        self.platformConstraints = platformConstraints
    }
}

/// Represents sheet detents for modal presentations
public enum SheetDetent: CaseIterable {
    case small
    case medium
    case large
    case custom(height: CGFloat)
    
    public static var allCases: [SheetDetent] {
        return [.small, .medium, .large, .custom(height: 300)] // Default height for custom
    }
}

/// Represents form strategy for different platforms
public struct FormStrategy {
    public let containerType: FormContainerType
    public let fieldLayout: FieldLayout
    public let validation: ValidationStrategy
    public let platformAdaptations: [ModalPlatform: PlatformAdaptation]
    
    public init(
        containerType: FormContainerType,
        fieldLayout: FieldLayout,
        validation: ValidationStrategy,
        platformAdaptations: [ModalPlatform: PlatformAdaptation] = [:]
    ) {
        self.containerType = containerType
        self.fieldLayout = fieldLayout
        self.validation = validation
        self.platformAdaptations = platformAdaptations
    }
}

// MARK: - Card Layout Types

/// Represents card layout decisions for different platforms
public struct CardLayoutDecision {
    public let layout: CardLayoutType
    public let sizing: CardSizing
    public let interaction: CardInteraction
    public let responsive: ResponsiveBehavior
    public let spacing: CGFloat
    public let columns: Int
    
    public init(
        layout: CardLayoutType,
        sizing: CardSizing,
        interaction: CardInteraction,
        responsive: ResponsiveBehavior,
        spacing: CGFloat,
        columns: Int
    ) {
        self.layout = layout
        self.sizing = sizing
        self.interaction = interaction
        self.responsive = responsive
        self.spacing = spacing
        self.columns = columns
    }
}

/// Represents card layout types
public enum CardLayoutType: String, CaseIterable {
    case uniform = "uniform"
    case contentAware = "contentAware"
    case aspectRatio = "aspectRatio"
    case dynamic = "dynamic"
}

/// Represents card sizing options
public enum CardSizing: String, CaseIterable {
    case fixed = "fixed"
    case flexible = "flexible"
    case adaptive = "adaptive"
    case contentBased = "contentBased"
}

/// Represents card interaction options
public enum CardInteraction: String, CaseIterable {
    case tap = "tap"
    case longPress = "longPress"
    case drag = "drag"
    case hover = "hover"
    case none = "none"
}

/// Represents responsive behavior for cards
public struct ResponsiveBehavior {
    public let type: ResponsiveType
    public let breakpoints: [CGFloat]
    public let adaptive: Bool
    
    public init(
        type: ResponsiveType,
        breakpoints: [CGFloat] = [],
        adaptive: Bool = false
    ) {
        self.type = type
        self.breakpoints = breakpoints
        self.adaptive = adaptive
    }
}

/// Represents responsive type options
public enum ResponsiveType: String, CaseIterable {
    case fixed = "fixed"
    case adaptive = "adaptive"
    case fluid = "fluid"
    case breakpoint = "breakpoint"
    case dynamic = "dynamic"
}

// MARK: - Cross-Platform Image Types

/// Cross-platform image type for consistent image handling
public struct PlatformSize: @unchecked Sendable {
    #if os(iOS)
    public let cgSize: CGSize
    #elseif os(macOS)
    public let nsSize: NSSize
    #endif
    
    public init(width: Double, height: Double) {
        #if os(iOS)
        self.cgSize = CGSize(width: width, height: height)
        #elseif os(macOS)
        self.nsSize = NSSize(width: width, height: height)
        #endif
    }
    
    public init(_ cgSize: CGSize) {
        #if os(iOS)
        self.cgSize = cgSize
        #elseif os(macOS)
        self.nsSize = NSSize(width: cgSize.width, height: cgSize.height)
        #endif
    }
    
    public var width: Double {
        #if os(iOS)
        return Double(cgSize.width)
        #elseif os(macOS)
        return Double(nsSize.width)
        #endif
    }
    
    public var height: Double {
        #if os(iOS)
        return Double(cgSize.height)
        #elseif os(macOS)
        return Double(nsSize.height)
        #endif
    }
    
    /// Output conversion to platform-specific types
    /// Note: Prefer using width and height properties for cross-platform code
    #if os(iOS)
    public var asCGSize: CGSize {
        return self.cgSize
    }
    #elseif os(macOS)
    public var asNSSize: NSSize {
        return self.nsSize
    }
    #endif
}

public struct PlatformImage: @unchecked Sendable {
    #if os(iOS)
    private let _uiImage: UIImage
    #elseif os(macOS)
    private let _nsImage: NSImage
    #endif
    
    public init?(data: Data) {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        self._uiImage = uiImage
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        self._nsImage = nsImage
        #endif
    }
    
    public init() {
        #if os(iOS)
        self._uiImage = UIImage()
        #elseif os(macOS)
        self._nsImage = NSImage()
        #endif
    }
    
    #if os(iOS)
    public init(uiImage: UIImage) {
        self._uiImage = uiImage
    }
    
    /// Implicit conversion from UIImage to PlatformImage (iOS only)
    /// This enables the currency exchange model: UIImage → PlatformImage at system boundary
    public init(_ image: UIImage) {
        self.init(uiImage: image)
    }
    
    /// Initialize from CGImage (iOS)
    /// Implements Issue #23: Add PlatformImage initializer from CGImage
    /// This eliminates the need for platform-specific code when working with Core Image/Graphics
    public init(cgImage: CGImage) {
        self.init(uiImage: UIImage(cgImage: cgImage))
    }
    #elseif os(macOS)
    public init(nsImage: NSImage) {
        self._nsImage = nsImage
    }
    
    /// Implicit conversion from NSImage to PlatformImage (macOS only)
    /// This enables the currency exchange model: NSImage → PlatformImage at system boundary
    public init(_ image: NSImage) {
        self.init(nsImage: image)
    }
    
    /// Initialize from CGImage (macOS)
    /// Implements Issue #23: Add PlatformImage initializer from CGImage
    /// This eliminates the need for platform-specific code when working with Core Image/Graphics
    /// - Parameters:
    ///   - cgImage: The CGImage to convert
    ///   - size: The size for the NSImage. Defaults to .zero if not specified.
    public init(cgImage: CGImage, size: CGSize = .zero) {
        self.init(nsImage: NSImage(cgImage: cgImage, size: size))
    }
    #endif
    
    #if os(iOS)
    public var uiImage: UIImage { return _uiImage }
    #elseif os(macOS)
    public var nsImage: NSImage { return _nsImage }
    #endif
    
    /// Check if the image is empty
    public var isEmpty: Bool {
        #if os(iOS)
        return uiImage.size == .zero
        #elseif os(macOS)
        return nsImage.size == .zero
        #endif
    }
    
    /// Get the size of the image
    public var size: CGSize {
        #if os(iOS)
        return uiImage.size
        #elseif os(macOS)
        return nsImage.size
        #endif
    }
    
    /// Create a placeholder image for testing/stub purposes
    public static func createPlaceholder() -> PlatformImage {
        #if os(iOS)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return PlatformImage(uiImage: uiImage)
        #elseif os(macOS)
        let size = NSSize(width: 100, height: 100)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        nsImage.unlockFocus()
        return PlatformImage(nsImage: nsImage)
        #else
        return PlatformImage()
        #endif
    }
}

// MARK: - Content Analysis Types

/// Represents content analysis results for layout decisions
public struct ContentAnalysis {
    public let recommendedApproach: LayoutApproach
    public let optimalSpacing: CGFloat
    public let performanceConsiderations: [String]
    
    public init(
        recommendedApproach: LayoutApproach,
        optimalSpacing: CGFloat,
        performanceConsiderations: [String] = []
    ) {
        self.recommendedApproach = recommendedApproach
        self.optimalSpacing = optimalSpacing
        self.performanceConsiderations = performanceConsiderations
    }
}

/// Represents layout approach strategies
public enum LayoutApproach: String, CaseIterable {
    case compact = "compact"
    case adaptive = "adaptive"
    case spacious = "spacious"
    case custom = "custom"
    case grid = "grid"
    case uniform = "uniform"
    case responsive = "responsive"
    case dynamic = "dynamic"
    case masonry = "masonry"
    case list = "list"
}

// MARK: - Presentation Hints

/// Data type hints for presentation
public enum DataTypeHint: String, CaseIterable, Sendable {
    case generic = "generic"
    case text = "text"
    case number = "number"
    case date = "date"
    case image = "image"
    case boolean = "boolean"
    case collection = "collection"
    case numeric = "numeric"
    case hierarchical = "hierarchical"
    case temporal = "temporal"
    case media = "media"
    case form = "form"
    case list = "list"
    case grid = "grid"
    case chart = "chart"
    case custom = "custom"
    case user = "user"
    case transaction = "transaction"
    case action = "action"
    case product = "product"
    case communication = "communication"
    case location = "location"
    case navigation = "navigation"
    case card = "card"
    case detail = "detail"
    case modal = "modal"
    case sheet = "sheet"
}

/// Presentation preference levels
public indirect enum PresentationPreference: Sendable, Equatable {
    case automatic
    case minimal
    case moderate
    case rich
    case custom
    case detail
    case modal
    case navigation
    case list
    case masonry
    case standard
    case form
    case card
    case cards
    case compact
    case grid
    case chart
    case coverFlow
    case countBased(lowCount: PresentationPreference, highCount: PresentationPreference, threshold: Int)
}

extension PresentationPreference {
    public static func == (lhs: PresentationPreference, rhs: PresentationPreference) -> Bool {
        switch (lhs, rhs) {
        case (.automatic, .automatic),
             (.minimal, .minimal),
             (.moderate, .moderate),
             (.rich, .rich),
             (.custom, .custom),
             (.detail, .detail),
             (.modal, .modal),
             (.navigation, .navigation),
             (.list, .list),
             (.masonry, .masonry),
             (.standard, .standard),
             (.form, .form),
             (.card, .card),
             (.cards, .cards),
             (.compact, .compact),
             (.grid, .grid),
             (.chart, .chart),
             (.coverFlow, .coverFlow):
            return true
        case (.countBased(let lhsLow, let lhsHigh, let lhsThreshold),
              .countBased(let rhsLow, let rhsHigh, let rhsThreshold)):
            return lhsLow == rhsLow && lhsHigh == rhsHigh && lhsThreshold == rhsThreshold
        default:
            return false
        }
    }
}

/// Presentation context types
public enum PresentationContext: String, CaseIterable, Sendable {
    case dashboard = "dashboard"
    case browse = "browse"
    case detail = "detail"
    case edit = "edit"
    case create = "create"
    case search = "search"
    case settings = "settings"
    case profile = "profile"
    case summary = "summary"
    case list = "list"
    case standard = "standard"
    case form = "form"
    case modal = "modal"
    case navigation = "navigation"
    case gallery = "gallery"
}

/// Content complexity levels
public enum ContentComplexity: String, CaseIterable, Sendable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case veryComplex = "veryComplex"
    case advanced = "advanced"
}

/// Value range for numeric field validation
public struct ValueRange: Sendable {
    public let min: Double
    public let max: Double
    
    public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
    
    /// Check if a value is within this range
    public func contains(_ value: Double) -> Bool {
        return value >= min && value <= max
    }
}

/// Picker option for enum fields with value and label
public struct PickerOption: Sendable, Equatable, Hashable {
    /// The raw value to store in the model (e.g., "story_points", "hours")
    public let value: String
    
    /// Human-readable label for display (e.g., "Story Points", "Hours")
    public let label: String
    
    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }
}

/// Field-level display hints for individual form fields
public struct FieldDisplayHints: Sendable {
    // MARK: - Type Information (New - for fully declarative hints)
    
    /// Field type: "string", "number", "boolean", "date", "url", "uuid", "document", "image", "custom"
    /// When provided, makes hints fully declarative (can generate forms without Mirror introspection)
    public let fieldType: String?
    
    /// Whether the field is optional (can be nil)
    /// When provided with fieldType, makes hints fully declarative
    public let isOptional: Bool?
    
    /// Whether the field is an array/collection type
    /// When provided with fieldType, makes hints fully declarative
    public let isArray: Bool?
    
    /// Default value for the field (type-dependent: String, Int, Bool, etc.)
    /// When provided, indicates the field has a default value
    /// Uses `any Sendable` to ensure Sendable conformance while supporting multiple types
    public let defaultValue: (any Sendable)?
    
    // MARK: - Display Properties (Existing)
    
    /// Expected maximum length of the field (for display sizing)
    public let expectedLength: Int?
    
    /// Display width hint: "narrow", "medium", "wide", or a specific value
    public let displayWidth: String?
    
    /// Whether to show a character counter
    public let showCharacterCounter: Bool
    
    /// Maximum allowed length (for validation)
    public let maxLength: Int?
    
    /// Minimum allowed length (for validation)
    public let minLength: Int?
    
    /// Expected value range for numeric fields (for OCR validation)
    /// When specified, OCR-extracted numeric values outside this range will be flagged or rejected
    public let expectedRange: ValueRange?
    
    /// Additional field-specific metadata
    public let metadata: [String: String]
    
    /// OCR hints for field identification (language-specific, resolved from hints file)
    public let ocrHints: [String]?
    
    /// Calculation groups for computing field values
    public let calculationGroups: [CalculationGroup]?
    
    /// Input type for the field: "picker", "text", etc.
    /// When "picker" is specified, the field will be rendered as a Picker instead of TextField
    public let inputType: String?
    
    /// Picker options for enum fields (only used when inputType is "picker")
    /// Each option contains a value (stored in model) and label (displayed in UI)
    public let pickerOptions: [PickerOption]?
    
    /// Whether this field should be hidden from forms and UI
    /// When true, the field is excluded from form generation and display
    /// Useful for internal fields like cloud sync IDs, internal metadata, etc.
    public let isHidden: Bool
    
    /// Whether this field is editable in forms
    /// When false, the field is displayed but read-only (non-editable)
    /// Useful for computed/calculated fields that should be visible but not editable
    /// Defaults to true for backward compatibility
    public let isEditable: Bool
    
    public init(
        // Type information (new - optional for backward compatibility)
        fieldType: String? = nil,
        isOptional: Bool? = nil,
        isArray: Bool? = nil,
        defaultValue: (any Sendable)? = nil,
        // Display properties (existing)
        expectedLength: Int? = nil,
        displayWidth: String? = nil,
        showCharacterCounter: Bool = false,
        maxLength: Int? = nil,
        minLength: Int? = nil,
        expectedRange: ValueRange? = nil,
        metadata: [String: String] = [:],
        ocrHints: [String]? = nil,
        calculationGroups: [CalculationGroup]? = nil,
        inputType: String? = nil,
        pickerOptions: [PickerOption]? = nil,
        isHidden: Bool = false,
        isEditable: Bool = true
    ) {
        self.fieldType = fieldType
        self.isOptional = isOptional
        self.isArray = isArray
        self.defaultValue = defaultValue
        self.expectedLength = expectedLength
        self.displayWidth = displayWidth
        self.showCharacterCounter = showCharacterCounter
        self.maxLength = maxLength
        self.minLength = minLength
        self.expectedRange = expectedRange
        self.metadata = metadata
        self.ocrHints = ocrHints
        self.calculationGroups = calculationGroups
        self.inputType = inputType
        self.pickerOptions = pickerOptions
        self.isHidden = isHidden
        self.isEditable = isEditable
    }
    
    /// Get display width as CGFloat if a specific numeric value is provided
    public func displayWidthValue() -> CGFloat? {
        guard let widthString = displayWidth else { return nil }
        
        // Try to parse as numeric value
        if let width = Double(widthString) {
            return CGFloat(width)
        }
        
        // Return nil for named widths (handled by UI layer)
        return nil
    }
    
    /// Determine if display width is narrow
    public var isNarrow: Bool {
        return displayWidth?.lowercased() == "narrow"
    }
    
    /// Determine if display width is medium
    public var isMedium: Bool {
        return displayWidth?.lowercased() == "medium" || displayWidth == nil
    }
    
    /// Determine if display width is wide
    public var isWide: Bool {
        return displayWidth?.lowercased() == "wide"
    }
    
    // MARK: - Declarative Hints Support
    
    /// Whether this hint is fully declarative (has enough type information to generate forms without Mirror)
    /// A hint is fully declarative if it has both fieldType and isOptional specified
    public var isFullyDeclarative: Bool {
        return fieldType != nil && isOptional != nil
    }
    
    /// Whether this hint provides partial type information (has fieldType but missing isOptional)
    public var hasPartialTypeInfo: Bool {
        return fieldType != nil && isOptional == nil
    }
}

/// Simple presentation hints for basic usage
public struct PresentationHints: Sendable {
    public let dataType: DataTypeHint
    public let presentationPreference: PresentationPreference
    public let complexity: ContentComplexity
    public let context: PresentationContext
    public var customPreferences: [String: String]
    
    /// Field-level display hints keyed by field ID
    public let fieldHints: [String: FieldDisplayHints]
    
    /// Color mapping by type (e.g., [ObjectIdentifier(Vehicle.self): .blue])
    /// Allows configuring colors for all items of a specific type
    /// Uses ObjectIdentifier to make types Hashable for dictionary keys
    public let colorMapping: [ObjectIdentifier: Color]?
    
    /// Per-item color provider (more flexible than type-based mapping)
    /// Allows configuring colors based on individual item properties
    public let itemColorProvider: (@Sendable (any CardDisplayable) -> Color?)?
    
    /// Default color when no mapping or provider returns a color
    public let defaultColor: Color?
    
    public init(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:],
        fieldHints: [String: FieldDisplayHints] = [:],
        colorMapping: [ObjectIdentifier: Color]? = nil,
        itemColorProvider: (@Sendable (any CardDisplayable) -> Color?)? = nil,
        defaultColor: Color? = nil
    ) {
        self.dataType = dataType
        self.presentationPreference = presentationPreference
        self.complexity = complexity
        self.context = context
        self.customPreferences = customPreferences
        self.fieldHints = fieldHints
        self.colorMapping = colorMapping
        self.itemColorProvider = itemColorProvider
        self.defaultColor = defaultColor
    }
    
    /// Get field-level hints for a specific field
    public func hints(forFieldId fieldId: String) -> FieldDisplayHints? {
        return fieldHints[fieldId]
    }
    
    /// Check if hints exist for a specific field
    public func hasHints(forFieldId fieldId: String) -> Bool {
        return fieldHints[fieldId] != nil
    }
}

