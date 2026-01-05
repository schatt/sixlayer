//
//  CrossPlatformOptimizationLayer6.swift
//  SixLayerFramework
//
//  Created for Phase 4 Week 13: Cross-Platform Optimization
//
//  This layer provides platform-specific optimizations and UI patterns
//  while maintaining cross-platform compatibility and performance.
//

import SwiftUI
import Foundation

// MARK: - Cross-Platform Optimization Manager

/// Manages cross-platform optimizations and platform-specific features
@MainActor
public class CrossPlatformOptimizationManager: ObservableObject {
    
    /// Current platform being optimized for
    public let currentPlatform: SixLayerPlatform
    
    /// Platform-specific optimization settings
    public var optimizationSettings: PlatformOptimizationSettings
    
    /// Performance metrics for cross-platform operations
    public var performanceMetrics: CrossPlatformPerformanceMetrics
    
    /// Platform-specific UI patterns
    public var uiPatterns: PlatformUIPatterns
    
    public init(platform: SixLayerPlatform = .current) {
        self.currentPlatform = platform
        self.optimizationSettings = PlatformOptimizationSettings(for: platform)
        self.performanceMetrics = CrossPlatformPerformanceMetrics()
        self.uiPatterns = PlatformUIPatterns(for: platform)
    }
    
    /// Apply platform-specific optimizations to a view
        func optimizeView<Content: View>(_ content: Content) -> some View {
        return content
            .platformSpecificOptimizations(for: currentPlatform)
            .performanceOptimizations(using: optimizationSettings)
            .uiPatternOptimizations(using: uiPatterns)
    }
    
}

// MARK: - Platform Types

/// Platform-specific optimization extensions
@MainActor
// Platform capability properties moved to PlatformStrategy to reduce code duplication (Issue #140)
// Use platform.supportsHapticFeedback and platform.supportsKeyboardNavigation from PlatformStrategy
// supportsTouchGestures remains here as it uses runtime detection
public extension SixLayerPlatform {
    var supportsTouchGestures: Bool {
        // Use runtime detection instead of hardcoded platform assumptions
        return RuntimeCapabilityDetection.supportsTouchWithOverride
    }
}

// MARK: - Platform Optimization Settings

/// Platform-specific optimization settings
public struct PlatformOptimizationSettings {
    
    /// Performance optimization level
    public var performanceLevel: PerformanceLevel
    
    /// Memory management strategy
    public var memoryStrategy: MemoryStrategy
    
    /// Rendering optimization settings
    public var renderingOptimizations: RenderingOptimizations
    
    /// Platform-specific feature flags
    public var featureFlags: [String: Bool]
    
    public init(for platform: SixLayerPlatform) {
        self.performanceLevel = .balanced
        self.memoryStrategy = .adaptive
        self.renderingOptimizations = RenderingOptimizations(for: platform)
        self.featureFlags = Self.defaultFeatureFlags(for: platform)
    }
    
    private static func defaultFeatureFlags(for platform: SixLayerPlatform) -> [String: Bool] {
        switch platform {
        case .iOS:
            return [
                "hapticFeedback": true,
                "touchGestures": true,
                "keyboardAvoidance": true,
                "safeAreaOptimization": true
            ]
        case .macOS:
            return [
                "keyboardNavigation": true,
                "mouseOptimization": true,
                "windowManagement": true,
                "menuBarIntegration": true
            ]
        case .watchOS:
            return [
                "hapticFeedback": true,
                "digitalCrown": true,
                "complications": true,
                "workoutOptimization": true
            ]
        case .tvOS:
            return [
                "remoteControl": true,
                "focusEngine": true,
                "tvInterface": true,
                "siriRemote": true
            ]
        case .visionOS:
            return [
                "spatialUI": true,
                "handTracking": true,
                "eyeTracking": true,
                "immersiveExperience": true
            ]
        }
    }
}

// MARK: - Performance Levels

public enum PerformanceLevel: String, CaseIterable, Sendable {
    case low = "low"
    case balanced = "balanced"
    case high = "high"
    case maximum = "maximum"
    
    public var optimizationMultiplier: Double {
        switch self {
        case .low: return 0.5
        case .balanced: return 1.0
        case .high: return 1.5
        case .maximum: return 2.0
        }
    }
}

// MARK: - Memory Strategies

public enum MemoryStrategy: String, CaseIterable, Sendable {
    case conservative = "conservative"
    case adaptive = "adaptive"
    case aggressive = "aggressive"
    
    public var memoryThreshold: Double {
        switch self {
        case .conservative: return 0.3
        case .adaptive: return 0.5
        case .aggressive: return 0.7
        }
    }
}

// MARK: - Rendering Optimizations

public struct RenderingOptimizations {
    
    /// Enable hardware acceleration
    public var hardwareAcceleration: Bool
    
    /// Use Metal rendering when available
    public var metalRendering: Bool
    
    /// Optimize for specific display types
    public var displayOptimization: DisplayOptimization
    
    /// Frame rate optimization
    public var frameRateOptimization: FrameRateOptimization
    
    public init(for platform: SixLayerPlatform) {
        self.hardwareAcceleration = true
        self.metalRendering = platform == .macOS || platform == .iOS
        self.displayOptimization = DisplayOptimization(for: platform)
        self.frameRateOptimization = FrameRateOptimization(for: platform)
    }
}

public enum DisplayOptimization: String, CaseIterable {
    case standard = "standard"
    case highDPI = "highDPI"
    case retina = "retina"
    case spatial = "spatial"
    
    public init(for platform: SixLayerPlatform) {
        switch platform {
        case .iOS, .macOS:
            self = .retina
        case .watchOS:
            self = .highDPI
        case .tvOS:
            self = .standard
        case .visionOS:
            self = .spatial
        }
    }
}

public enum FrameRateOptimization: String, CaseIterable {
    case adaptive = "adaptive"
    case fixed60 = "fixed60"
    case fixed120 = "fixed120"
    case variable = "variable"
    
    public init(for platform: SixLayerPlatform) {
        switch platform {
        case .iOS:
            self = .adaptive
        case .macOS:
            self = .fixed60
        case .watchOS:
            self = .adaptive
        case .tvOS:
            self = .fixed60
        case .visionOS:
            self = .variable
        }
    }
}

// MARK: - Cross-Platform Performance Metrics

/// Tracks performance metrics across platforms
public class CrossPlatformPerformanceMetrics: ObservableObject {
    
    /// Rendering performance metrics
    @Published public var renderingMetrics: RenderingMetrics
    
    /// Memory usage metrics
    @Published public var memoryMetrics: MemoryMetrics
    
    /// Platform-specific metrics
    @Published public var platformMetrics: [SixLayerPlatform: PlatformSpecificMetrics]
    
    public init() {
        self.renderingMetrics = RenderingMetrics()
        self.memoryMetrics = MemoryMetrics()
        self.platformMetrics = [:]
        
        // Initialize metrics for all platforms
        for platform in SixLayerPlatform.allCases {
            self.platformMetrics[platform] = PlatformSpecificMetrics(for: platform)
        }
    }
    
    /// Record a performance measurement
        func recordMeasurement(_ measurement: PerformanceMeasurement) {
        switch measurement.type {
        case .rendering:
            renderingMetrics.record(measurement)
        case .memory:
            memoryMetrics.record(measurement)
        case .platform:
            if let platform = measurement.platform {
                platformMetrics[platform]?.record(measurement)
            }
        }
    }
    
    /// Get performance summary for current platform
        func getCurrentPlatformSummary() -> PerformanceSummary {
        let currentPlatform = SixLayerPlatform.current
        let platformMetrics = self.platformMetrics[currentPlatform] ?? PlatformSpecificMetrics(for: currentPlatform)
        
        return PerformanceSummary(
            platform: currentPlatform,
            rendering: renderingMetrics,
            memory: memoryMetrics,
            platformSpecific: platformMetrics
        )
    }
}

// MARK: - Performance Metrics Types

public struct RenderingMetrics {
    public var frameRate: Double = 0.0
    public var renderTime: TimeInterval = 0.0
    public var drawCalls: Int = 0
    public var textureMemory: Int64 = 0
    
    public mutating func record(_ measurement: PerformanceMeasurement) {
        // Update rendering metrics based on measurement
        switch measurement.metric {
        case .frameRate:
            frameRate = measurement.value
        case .renderTime:
            renderTime = measurement.value
        case .drawCalls:
            drawCalls = Int(measurement.value)
        case .textureMemory:
            textureMemory = Int64(measurement.value)
        default:
            break
        }
    }
}

public struct MemoryMetrics {
    public var usedMemory: Int64 = 0
    public var peakMemory: Int64 = 0
    public var memoryPressure: MemoryPressureLevel = .normal
    
    public mutating func record(_ measurement: PerformanceMeasurement) {
        switch measurement.metric {
        case .usedMemory:
            usedMemory = Int64(measurement.value)
        case .peakMemory:
            peakMemory = Int64(measurement.value)
        case .memoryPressure:
            memoryPressure = MemoryPressureLevel(rawValue: Int(measurement.value)) ?? .normal
        default:
            break
        }
    }
}

public struct PlatformSpecificMetrics {
    public let platform: SixLayerPlatform
    public var customMetrics: [String: Double]
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        self.customMetrics = [:]
    }
    
    public mutating func record(_ measurement: PerformanceMeasurement) {
        customMetrics[measurement.metric.rawValue] = measurement.value
    }
}

// MARK: - Performance Measurement

public struct PerformanceMeasurement {
    public let type: MeasurementType
    public let metric: PerformanceMetric
    public let value: Double
    public let platform: SixLayerPlatform?
    public let timestamp: Date
    
    public init(type: MeasurementType, metric: PerformanceMetric, value: Double, platform: SixLayerPlatform? = nil) {
        self.type = type
        self.metric = metric
        self.value = value
        self.platform = platform
        self.timestamp = Date()
    }
}

public enum MeasurementType: String, CaseIterable {
    case rendering = "rendering"
    case memory = "memory"
    case platform = "platform"
}

public enum PerformanceMetric: String, CaseIterable {
    case frameRate = "frameRate"
    case renderTime = "renderTime"
    case drawCalls = "drawCalls"
    case textureMemory = "textureMemory"
    case usedMemory = "usedMemory"
    case peakMemory = "peakMemory"
    case memoryPressure = "memoryPressure"
}

public enum MemoryPressureLevel: Int, CaseIterable {
    case normal = 0
    case warning = 1
    case critical = 2
}

// MARK: - Performance Summary

public struct PerformanceSummary {
    public let platform: SixLayerPlatform
    public let rendering: RenderingMetrics
    public let memory: MemoryMetrics
    public let platformSpecific: PlatformSpecificMetrics
    
    public var overallScore: Double {
        let renderingScore = calculateRenderingScore()
        let memoryScore = calculateMemoryScore()
        let platformScore = calculatePlatformScore()
        
        return (renderingScore + memoryScore + platformScore) / 3.0
    }
    
    private func calculateRenderingScore() -> Double {
        let frameRateScore = min(rendering.frameRate / 60.0, 1.0)
        let renderTimeScore = max(0, 1.0 - (rendering.renderTime / 16.67)) // 16.67ms = 60fps
        return (frameRateScore + renderTimeScore) / 2.0
    }
    
    private func calculateMemoryScore() -> Double {
        let memoryUsageScore = max(0, 1.0 - (Double(memory.usedMemory) / 1_000_000_000)) // 1GB threshold
        let pressureScore = 1.0 - (Double(memory.memoryPressure.rawValue) / 2.0)
        return (memoryUsageScore + pressureScore) / 2.0
    }
    
    private func calculatePlatformScore() -> Double {
        // Platform-specific scoring logic
        return 0.8 // Placeholder
    }
}

// MARK: - Platform UI Patterns

/// Platform-specific UI patterns and optimizations
public struct PlatformUIPatterns {
    
    /// Current platform
    public let platform: SixLayerPlatform
    
    /// Platform-specific navigation patterns
    public var navigationPatterns: NavigationPatterns
    
    /// Platform-specific interaction patterns
    public var interactionPatterns: InteractionPatterns
    
    /// Platform-specific layout patterns
    public var layoutPatterns: LayoutPatterns
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        self.navigationPatterns = NavigationPatterns(for: platform)
        self.interactionPatterns = InteractionPatterns(for: platform)
        self.layoutPatterns = LayoutPatterns(for: platform)
    }
}

public struct NavigationPatterns: Sendable {
    public let platform: SixLayerPlatform
    public var primaryNavigation: NavigationType
    public var secondaryNavigation: NavigationType
    public var modalPresentation: ModalType
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        
        switch platform {
        case .iOS:
            self.primaryNavigation = .tabBar
            self.secondaryNavigation = .navigationStack
            self.modalPresentation = .sheet
        case .macOS:
            self.primaryNavigation = .sidebar
            self.secondaryNavigation = .navigationSplit
            self.modalPresentation = .window
        case .watchOS:
            self.primaryNavigation = .crown
            self.secondaryNavigation = .swipe
            self.modalPresentation = .sheet
        case .tvOS:
            self.primaryNavigation = .tabBar
            self.secondaryNavigation = .focus
            self.modalPresentation = .modal
        case .visionOS:
            self.primaryNavigation = .spatial
            self.secondaryNavigation = .handTracking
            self.modalPresentation = .immersive
        }
    }
}

public enum NavigationType: String, CaseIterable, Sendable {
    case tabBar = "tabBar"
    case navigationStack = "navigationStack"
    case sidebar = "sidebar"
    case navigationSplit = "navigationSplit"
    case spatial = "spatial"
    case floating = "floating"
    case crown = "crown"
    case swipe = "swipe"
    case focus = "focus"
    case handTracking = "handTracking"
}

public enum ModalType: String, CaseIterable, Sendable {
    case sheet = "sheet"
    case window = "window"
    case immersive = "immersive"
    case modal = "modal"
}

public struct InteractionPatterns: Sendable {
    public let platform: SixLayerPlatform
    public var primaryInput: InputType
    public var secondaryInput: InputType
    public var gestureSupport: [GestureType]
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        
        switch platform {
        case .iOS:
            self.primaryInput = .touch
            self.secondaryInput = .voice
            self.gestureSupport = [.tap, .swipe, .pinch, .rotate, .longPress]
        case .macOS:
            self.primaryInput = .mouse
            self.secondaryInput = .keyboard
            self.gestureSupport = [.click, .drag, .scroll, .rightClick]
        case .watchOS:
            self.primaryInput = .digitalCrown
            self.secondaryInput = .touch
            self.gestureSupport = [.tap, .swipe, .longPress]
        case .tvOS:
            self.primaryInput = .remote
            self.secondaryInput = .voice
            self.gestureSupport = [.click, .swipe, .longPress]
        case .visionOS:
            self.primaryInput = .handTracking
            self.secondaryInput = .voice
            self.gestureSupport = [.tap, .pinch, .rotate, .longPress]
        }
    }
}

public enum InputType: String, CaseIterable, Sendable {
    case touch = "touch"
    case mouse = "mouse"
    case keyboard = "keyboard"
    case voice = "voice"
    case gesture = "gesture"
    case digitalCrown = "digitalCrown"
    case remote = "remote"
    case handTracking = "handTracking"
}

public enum GestureType: String, CaseIterable, Sendable {
    case tap = "tap"
    case swipe = "swipe"
    case pinch = "pinch"
    case rotate = "rotate"
    case longPress = "longPress"
    case click = "click"
    case drag = "drag"
    case scroll = "scroll"
    case rightClick = "rightClick"
    case spatial = "spatial"
    case eyeTracking = "eyeTracking"
}

public struct LayoutPatterns: Sendable {
    public let platform: SixLayerPlatform
    public var primaryLayout: LayoutType
    public var secondaryLayout: LayoutType
    public var responsiveBreakpoints: [CGFloat]
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
        
        switch platform {
        case .iOS:
            self.primaryLayout = .adaptive
            self.secondaryLayout = .stack
            self.responsiveBreakpoints = [320, 375, 414, 428, 768, 834, 1024]
        case .macOS:
            self.primaryLayout = .grid
            self.secondaryLayout = .split
            self.responsiveBreakpoints = [800, 1024, 1280, 1440, 1920, 2560, 3840]
        case .watchOS:
            self.primaryLayout = .compact
            self.secondaryLayout = .stack
            self.responsiveBreakpoints = [136, 162, 180, 198, 205, 224]
        case .tvOS:
            self.primaryLayout = .grid
            self.secondaryLayout = .stack
            self.responsiveBreakpoints = [1920, 2560, 3840, 4096]
        case .visionOS:
            self.primaryLayout = .spatial
            self.secondaryLayout = .immersive
            self.responsiveBreakpoints = [1000, 1500, 2000, 3000]
        }
    }
}

public enum LayoutType: String, CaseIterable, Sendable {
    case adaptive = "adaptive"
    case stack = "stack"
    case grid = "grid"
    case split = "split"
    case spatial = "spatial"
    case floating = "floating"
    case compact = "compact"
    case immersive = "immersive"
}


// MARK: - View Extensions

public extension View {
    
    /// Apply platform-specific optimizations
    func platformSpecificOptimizations(for platform: SixLayerPlatform) -> some View {
        return self
            .modifier(PlatformOptimizationModifier(platform: platform))
    }
    
    /// Apply performance optimizations
    func performanceOptimizations(using settings: PlatformOptimizationSettings) -> some View {
        return self
            .modifier(PerformanceOptimizationModifier(settings: settings))
    }
    
    /// Apply UI pattern optimizations
    func uiPatternOptimizations(using patterns: PlatformUIPatterns) -> some View {
        return self
            .modifier(UIPatternOptimizationModifier(patterns: patterns))
    }
}

// MARK: - Optimization Modifiers

/// Modifier for platform-specific optimizations
public struct PlatformOptimizationModifier: ViewModifier {
    public let platform: SixLayerPlatform
    
    public init(platform: SixLayerPlatform) {
        self.platform = platform
    }
    
        public func body(content: Content) -> some View {
        content
            .environment(\.platform, platform)
            .environment(\.supportsHapticFeedback, platform.supportsHapticFeedback)
            .environment(\.supportsTouchGestures, platform.supportsTouchGestures)
            .environment(\.supportsKeyboardNavigation, platform.supportsKeyboardNavigation)
            .automaticCompliance()
    }
}

/// Modifier for performance optimizations
public struct PerformanceOptimizationModifier: ViewModifier {
    public let settings: PlatformOptimizationSettings
    
    public init(settings: PlatformOptimizationSettings) {
        self.settings = settings
    }
    
        public func body(content: Content) -> some View {
        content
            .environment(\.performanceLevel, settings.performanceLevel)
            .environment(\.memoryStrategy, settings.memoryStrategy)
            .automaticCompliance()
    }
}

/// Modifier for UI pattern optimizations
public struct UIPatternOptimizationModifier: ViewModifier {
    public let patterns: PlatformUIPatterns
    
    public init(patterns: PlatformUIPatterns) {
        self.patterns = patterns
    }
    
        public func body(content: Content) -> some View {
        content
            .environment(\.navigationPatterns, patterns.navigationPatterns)
            .environment(\.interactionPatterns, patterns.interactionPatterns)
            .environment(\.layoutPatterns, patterns.layoutPatterns)
            .automaticCompliance()
    }
}

// MARK: - Environment Keys

/// Environment key for platform
public struct PlatformKey: EnvironmentKey {
    public typealias Value = SixLayerPlatform
    public static let defaultValue: SixLayerPlatform = .current
}

/// Environment key for haptic feedback support
public struct HapticFeedbackSupportKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

/// Environment key for touch gesture support
public struct TouchGestureSupportKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

/// Environment key for keyboard navigation support
public struct KeyboardNavigationSupportKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

/// Environment key for performance level
public struct PerformanceLevelKey: EnvironmentKey {
    public static let defaultValue: PerformanceLevel = .balanced
}

/// Environment key for memory strategy
public struct MemoryStrategyKey: EnvironmentKey {
    public static let defaultValue: MemoryStrategy = .adaptive
}

/// Environment key for navigation patterns
public struct NavigationPatternsKey: EnvironmentKey {
    public static let defaultValue: NavigationPatterns = NavigationPatterns(for: SixLayerPlatform.current)
}

/// Environment key for interaction patterns
public struct InteractionPatternsKey: EnvironmentKey {
    public static let defaultValue: InteractionPatterns = InteractionPatterns(for: SixLayerPlatform.current)
}

/// Environment key for layout patterns
public struct LayoutPatternsKey: EnvironmentKey {
    public static let defaultValue: LayoutPatterns = LayoutPatterns(for: SixLayerPlatform.current)
}

// MARK: - Environment Extensions

public extension EnvironmentValues {
    
    var platform: SixLayerPlatform {
        get { self[PlatformKey.self] }
        set { self[PlatformKey.self] = newValue }
    }
    
    var supportsHapticFeedback: Bool {
        get { self[HapticFeedbackSupportKey.self] }
        set { self[HapticFeedbackSupportKey.self] = newValue }
    }
    
    var supportsTouchGestures: Bool {
        get { self[TouchGestureSupportKey.self] }
        set { self[TouchGestureSupportKey.self] = newValue }
    }
    
    var supportsKeyboardNavigation: Bool {
        get { self[KeyboardNavigationSupportKey.self] }
        set { self[KeyboardNavigationSupportKey.self] = newValue }
    }
    
    var performanceLevel: PerformanceLevel {
        get { self[PerformanceLevelKey.self] }
        set { self[PerformanceLevelKey.self] = newValue }
    }
    
    var memoryStrategy: MemoryStrategy {
        get { self[MemoryStrategyKey.self] }
        set { self[MemoryStrategyKey.self] = newValue }
    }
    
    var navigationPatterns: NavigationPatterns {
        get { self[NavigationPatternsKey.self] }
        set { self[NavigationPatternsKey.self] = newValue }
    }
    
    var interactionPatterns: InteractionPatterns {
        get { self[InteractionPatternsKey.self] }
        set { self[InteractionPatternsKey.self] = newValue }
    }
    
    var layoutPatterns: LayoutPatterns {
        get { self[LayoutPatternsKey.self] }
        set { self[LayoutPatternsKey.self] = newValue }
    }
}

// MARK: - Cross-Platform Testing

/// Cross-platform testing utilities
public struct CrossPlatformTesting {
    
    /// Test view across all platforms
        static func testViewAcrossPlatforms<Content: View>(
        _ content: Content,
        testName: String
    ) -> CrossPlatformTestResults {
        var results: [SixLayerPlatform: TestResult] = [:]
        
        for platform in SixLayerPlatform.allCases {
            let result = testViewOnPlatform(content, platform: platform, testName: testName)
            results[platform] = result
        }
        
        return CrossPlatformTestResults(
            testName: testName,
            results: results,
            timestamp: Date()
        )
    }
    
    /// Test view on specific platform
    private static func testViewOnPlatform<Content: View>(
        _ content: Content,
        platform: SixLayerPlatform,
        testName: String
    ) -> TestResult {
        // Simulate platform-specific testing
        let startTime = Date()
        
        // Mock platform-specific tests
        let compatibilityScore = calculateCompatibilityScore(for: platform)
        let performanceScore = calculatePerformanceScore(for: platform)
        let accessibilityScore = calculateAccessibilityScore(for: platform)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        return TestResult(
            platform: platform,
            compatibilityScore: compatibilityScore,
            performanceScore: performanceScore,
            accessibilityScore: accessibilityScore,
            duration: duration,
            passed: compatibilityScore > 0.8 && performanceScore > 0.7 && accessibilityScore > 0.8
        )
    }
    
    private static func calculateCompatibilityScore(for platform: SixLayerPlatform) -> Double {
        // Mock compatibility scoring
        switch platform {
        case .iOS: return 0.95
        case .macOS: return 0.92
        case .watchOS: return 0.88
        case .tvOS: return 0.90
        case .visionOS: return 0.85
        }
    }
    
    private static func calculatePerformanceScore(for platform: SixLayerPlatform) -> Double {
        // Mock performance scoring
        switch platform {
        case .iOS: return 0.88
        case .macOS: return 0.91
        case .watchOS: return 0.85
        case .tvOS: return 0.89
        case .visionOS: return 0.87
        }
    }
    
    private static func calculateAccessibilityScore(for platform: SixLayerPlatform) -> Double {
        // Mock accessibility scoring
        switch platform {
        case .iOS: return 0.90
        case .macOS: return 0.87
        case .watchOS: return 0.86
        case .tvOS: return 0.88
        case .visionOS: return 0.89
        }
    }
}

// MARK: - Test Results

public struct CrossPlatformTestResults {
    public let testName: String
    public let results: [SixLayerPlatform: TestResult]
    public let timestamp: Date
    
    public var overallPassRate: Double {
        let passedTests = results.values.filter { $0.passed }.count
        return Double(passedTests) / Double(results.count)
    }
    
    public var platformWithHighestScore: SixLayerPlatform? {
        return results.max { $0.value.overallScore < $1.value.overallScore }?.key
    }
    
    public var platformWithLowestScore: SixLayerPlatform? {
        return results.min { $0.value.overallScore < $1.value.overallScore }?.key
    }
}

public struct TestResult {
    public let platform: SixLayerPlatform
    public let compatibilityScore: Double
    public let performanceScore: Double
    public let accessibilityScore: Double
    public let duration: TimeInterval
    public let passed: Bool
    
    public var overallScore: Double {
        return (compatibilityScore + performanceScore + accessibilityScore) / 3.0
    }
}

#if ENABLE_PREVIEWS
#Preview {
    platformVStackContainer(spacing: 20) {
        Text("Cross-Platform Optimization Layer 6")
            .font(.title)
            .fontWeight(.bold)
        
        Text("This layer provides platform-specific optimizations and UI patterns while maintaining cross-platform compatibility.")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
        
        let manager = CrossPlatformOptimizationManager()
        
        platformVStackContainer(alignment: .leading, spacing: 10) {
            Text("Current Platform: \(manager.currentPlatform.rawValue)")
            Text("Performance Level: \(manager.optimizationSettings.performanceLevel.rawValue)")
            Text("Memory Strategy: \(manager.optimizationSettings.memoryStrategy.rawValue)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
    .environmentObject(CrossPlatformOptimizationManager())
}
#endif
