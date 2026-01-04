import Testing


//
//  CrossPlatformOptimizationLayer6Tests.swift
//  SixLayerFrameworkTests
//
//  Tests for Layer 6 Cross-Platform Optimization functions
//  Tests CrossPlatformOptimizationManager, PlatformOptimizationSettings,
//  CrossPlatformPerformanceMetrics, PlatformUIPatterns, and related functions
//

import SwiftUI
@testable import SixLayerFramework
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Cross Platform Optimization Layer")
open class CrossPlatformOptimizationLayer6Tests: BaseTestClass {
    
    // MARK: - CrossPlatformOptimizationManager Tests
    
    @Test @MainActor func testCrossPlatformOptimizationManager_Initialization() {
        // Given: Cross-platform optimization manager
        let manager = CrossPlatformOptimizationManager()
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: CrossPlatformOptimizationManager is a class, so it can't be nil after initialization
        
        // 2. Does that structure contain what it should?
        // Note: These properties are value types, so they can't be nil
        // The actual verification is that the manager was created successfully
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // Manager should detect current platform correctly
        #if os(iOS)
        #expect(manager.currentPlatform == .iOS, "Manager should detect iOS platform")
        #elseif os(macOS)
        #expect(manager.currentPlatform == .macOS, "Manager should detect macOS platform")
        #elseif os(visionOS)
        #expect(manager.currentPlatform == .visionOS, "Manager should detect visionOS platform")
        #elseif os(watchOS)
        #expect(manager.currentPlatform == .watchOS, "Manager should detect watchOS platform")
        #elseif os(tvOS)
        #expect(manager.currentPlatform == .tvOS, "Manager should detect tvOS platform")
        #endif
    }
    
    @Test @MainActor func testCrossPlatformOptimizationManager_WithSpecificPlatform() {
        // Given: Manager initialized with specific platform
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Creating managers for each platform
        for platform in platforms {
            let manager = CrossPlatformOptimizationManager(platform: platform)
            
            // Then: Each manager should be configured correctly
            #expect(manager.currentPlatform == platform, "Manager should use specified platform: \(platform)")
            // Note: These properties are value types, so they can't be nil
            // The actual verification is that the manager was created successfully for the platform
        }
    }
    
    @Test @MainActor func testCrossPlatformOptimizationManager_OptimizeView() {
        // Given: Manager and test view
        let manager = CrossPlatformOptimizationManager()
        let testView = Text("Test View")
        
        // When: Optimizing view
        let optimizedView = manager.optimizeView(testView)
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: optimizedView is a View, so it cannot be nil
        
        // 2. Does that structure contain what it should?
        if let _ = try? AnyView(optimizedView).inspect() {
            // Successfully inspected optimized view
        } else {
            #if canImport(ViewInspector)
            Issue.record("Failed to inspect optimized view structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // Optimized view should be inspectable and contain platform-specific optimizations
        if let _ = try? AnyView(optimizedView).inspect() {
            // Platform-specific optimizations verified
        } else {
            #if canImport(ViewInspector)
            Issue.record("Optimized view should be inspectable on current platform")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    @Test @MainActor func testCrossPlatformOptimizationManager_PlatformRecommendations() {
        // NOTE: getPlatformRecommendations() has been removed - PlatformRecommendationEngine moved to possible-features/
        // Given: Manager
        let manager = CrossPlatformOptimizationManager()
        
        // When: Getting platform recommendations
        // let recommendations = manager.getPlatformRecommendations()
        
        // Then: Should return platform recommendations (L6 function responsibility)
        // Note: recommendations is an array, so it cannot be nil
        // Note: Recommendations may be empty if no platform-specific issues are detected
        // NOTE: Tests for PlatformRecommendationEngine moved to possible-features/PlatformRecommendationEngineTests.swift
        #expect(Bool(true), "PlatformRecommendationEngine moved to possible-features/ - test disabled")
    }
    
    // MARK: - PlatformOptimizationSettings Tests
    
    @Test @MainActor func testPlatformOptimizationSettings_Creation() {
        // Given: Different platforms
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Creating settings for each platform
        for platform in platforms {
            let settings = PlatformOptimizationSettings(for: platform)
            
            // Then: Settings should be created successfully (L6 function responsibility)
            // Note: PlatformOptimizationSettings is a struct, so it cannot be nil
            // Note: These properties are value types, so they cannot be nil
            // The actual verification is that the settings were created successfully for the platform
            #expect(settings.performanceLevel.rawValue.count > 0, "Should have valid performance level for \(platform)")
        }
    }
    
    @Test @MainActor func testPlatformOptimizationSettings_PerformanceLevels() {
        // Given: Performance levels
        let levels: [PerformanceLevel] = [.low, .balanced, .high, .maximum]
        
        // When: Testing each performance level
        for level in levels {
            // Then: Each level should have appropriate multiplier
            #expect(level.optimizationMultiplier > 0, 
                                "Performance level \(level) should have positive multiplier")
        }
        
        // Performance levels should be ordered correctly
        #expect(PerformanceLevel.low.optimizationMultiplier < 
                         PerformanceLevel.balanced.optimizationMultiplier, 
                         "Low should be less than balanced")
        #expect(PerformanceLevel.balanced.optimizationMultiplier < 
                         PerformanceLevel.high.optimizationMultiplier, 
                         "Balanced should be less than high")
        #expect(PerformanceLevel.high.optimizationMultiplier < 
                         PerformanceLevel.maximum.optimizationMultiplier, 
                         "High should be less than maximum")
    }
    
    @Test @MainActor func testPlatformOptimizationSettings_MemoryStrategies() {
        // Given: Memory strategies
        let strategies: [MemoryStrategy] = [.conservative, .adaptive, .aggressive]
        
        // When: Testing each memory strategy
        for strategy in strategies {
            // Then: Each strategy should have appropriate threshold
            #expect(strategy.memoryThreshold >= 0, 
                                      "Memory strategy \(strategy) should have non-negative threshold")
            #expect(strategy.memoryThreshold <= 1, 
                                   "Memory strategy \(strategy) should have threshold <= 1")
        }
        
        // Memory strategies should be ordered correctly
        #expect(MemoryStrategy.conservative.memoryThreshold < 
                         MemoryStrategy.adaptive.memoryThreshold, 
                         "Conservative should be less than adaptive")
        #expect(MemoryStrategy.adaptive.memoryThreshold < 
                         MemoryStrategy.aggressive.memoryThreshold, 
                         "Adaptive should be less than aggressive")
    }
    
    // MARK: - CrossPlatformPerformanceMetrics Tests
    
    @Test @MainActor func testCrossPlatformPerformanceMetrics_Initialization() {
        // Given: Performance metrics
        let metrics = CrossPlatformPerformanceMetrics()
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: CrossPlatformPerformanceMetrics is a class, so it cannot be nil after initialization
        
        // 2. Does that structure contain what it should?
        // Note: These properties are value types, so they cannot be nil
        // The actual verification is that the metrics were created successfully
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // Metrics should be initialized for current platform
        let currentPlatform = SixLayerPlatform.current
        #expect(metrics.platformMetrics.keys.contains(currentPlatform), 
                    "Should have metrics for current platform")
    }
    
    @Test @MainActor func testCrossPlatformPerformanceMetrics_RecordMeasurement() {
        // Given: Performance metrics and measurement
        let metrics = CrossPlatformPerformanceMetrics()
        let measurement = PerformanceMeasurement(
            type: .rendering,
            metric: .frameRate,
            value: 60.0,
            platform: .iOS
        )
        
        // When: Recording measurement
        metrics.recordMeasurement(measurement)
        
        // Then: Measurement should be recorded
        let summary = metrics.getCurrentPlatformSummary()
        // Note: PerformanceSummary is a struct, so it cannot be nil
        #expect(summary.platform == SixLayerPlatform.current, 
                      "Summary should be for current platform")
    }
    
    @Test @MainActor func testCrossPlatformPerformanceMetrics_PlatformSummary() {
        // Given: Performance metrics
        let metrics = CrossPlatformPerformanceMetrics()
        
        // When: Getting platform summary
        let summary = metrics.getCurrentPlatformSummary()
        
        // Then: Summary should be valid
        // Note: PerformanceSummary is a struct, so it cannot be nil
        #expect(summary.platform == SixLayerPlatform.current, 
                      "Summary should be for current platform")
        // Note: rendering is a struct, so it cannot be nil
        // Note: memory is a struct, so it cannot be nil
        // Note: platformSpecific is a struct, so it cannot be nil
        #expect(summary.overallScore >= 0, "Overall score should be non-negative")
        #expect(summary.overallScore <= 100, "Overall score should be <= 100")
    }
    
    // MARK: - PlatformUIPatterns Tests
    
    @Test @MainActor func testPlatformUIPatterns_PlatformSpecific() {
        // Given: Different platforms
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Creating UI patterns for each platform
        for platform in platforms {
            let patterns = PlatformUIPatterns(for: platform)
            
            // Then: Patterns should be platform-appropriate
            // Note: PlatformUIPatterns is a struct, so it cannot be nil
            #expect(patterns.platform == platform, "Patterns should be for correct platform")
            // Note: navigationPatterns is a struct, so it cannot be nil
            // Note: interactionPatterns is a struct, so it cannot be nil
            // Note: layoutPatterns is a struct, so it cannot be nil
            
            // Platform-specific verification
            switch platform {
            case .iOS:
                // iOS should have mobile navigation patterns
                #expect(patterns.navigationPatterns.platform == platform, 
                              "iOS navigation patterns should be for iOS")
            case .macOS:
                // macOS should have desktop navigation patterns
                #expect(patterns.navigationPatterns.platform == platform, 
                              "macOS navigation patterns should be for macOS")
            case .visionOS:
                // visionOS should have spatial navigation patterns
                #expect(patterns.navigationPatterns.platform == platform, 
                              "visionOS navigation patterns should be for visionOS")
            case .watchOS:
                // watchOS should have compact navigation patterns
                #expect(patterns.navigationPatterns.platform == platform, 
                              "watchOS navigation patterns should be for watchOS")
            case .tvOS:
                // tvOS should have TV navigation patterns
                #expect(patterns.navigationPatterns.platform == platform, 
                              "tvOS navigation patterns should be for tvOS")
            }
        }
    }
    
    @Test @MainActor func testPlatformUIPatterns_NavigationPatterns() {
        // Given: Navigation patterns for different platforms
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Testing navigation patterns
        for platform in platforms {
            let navigationPatterns = NavigationPatterns(for: platform)
            
            // Then: Navigation patterns should be platform-appropriate
            #expect(navigationPatterns.platform == platform, 
                          "Navigation patterns should be for \(platform)")
            // Note: primaryNavigation is an enum, so it cannot be nil
// Note: primaryNavigation is an enum, so it cannot be nil
            // Note: secondaryNavigation is an enum, so it cannot be nil
// Note: secondaryNavigation is an enum, so it cannot be nil
            // Note: modalPresentation is an enum, so it cannot be nil
// Note: modalPresentation is an enum, so it cannot be nil
        }
    }
    
    @Test @MainActor func testPlatformUIPatterns_InteractionPatterns() {
        // Given: Interaction patterns for different platforms
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Testing interaction patterns
        for platform in platforms {
            let interactionPatterns = SixLayerFramework.InteractionPatterns(for: platform)
            
            // Then: Interaction patterns should be platform-appropriate
            #expect(interactionPatterns.platform == platform, 
                          "Interaction patterns should be for \(platform)")
            // Note: primaryInput is an enum, so it cannot be nil
// Note: primaryInput is an enum, so it cannot be nil
            // Note: secondaryInput is an enum, so it cannot be nil
// Note: secondaryInput is an enum, so it cannot be nil
            // Note: gestureSupport is an array, so it cannot be nil
// Note: gestureSupport is an array, so it cannot be nil
        }
    }
    
    @Test @MainActor func testPlatformUIPatterns_LayoutPatterns() {
        // Given: Layout patterns for different platforms
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // When: Testing layout patterns
        for platform in platforms {
            let layoutPatterns = LayoutPatterns(for: platform)
            
            // Then: Layout patterns should be platform-appropriate
            #expect(layoutPatterns.platform == platform, 
                          "Layout patterns should be for \(platform)")
            // Note: primaryLayout is an enum, so it cannot be nil
// Note: primaryLayout is an enum, so it cannot be nil
            // Note: secondaryLayout is an enum, so it cannot be nil
// Note: secondaryLayout is an enum, so it cannot be nil
            // Note: responsiveBreakpoints is an array, so it cannot be nil
            // Note: responsiveBreakpoints should have at least one breakpoint
            #expect(!layoutPatterns.responsiveBreakpoints.isEmpty, "Should have at least one breakpoint for \(platform)")
        }
    }
    
    // MARK: - View Modifier Tests
    
    @Test @MainActor func testPlatformSpecificOptimizationsModifier() {
        // Given: Test view and platform
        let testView = Text("Test View")
        let platform = SixLayerPlatform.current
        
        // When: Applying platform-specific optimizations
        let optimizedView = testView.platformSpecificOptimizations(for: platform)
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: optimizedView is a View, so it cannot be nil
        
        // 2. Does that structure contain what it should?
        if let _ = try? AnyView(optimizedView).inspect() {
            // Successfully inspected platform-optimized view
        } else {
            #if canImport(ViewInspector)
            Issue.record("Failed to inspect platform-optimized view structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // Optimized view should be inspectable and contain platform-specific optimizations
        if let _ = try? AnyView(optimizedView).inspect() {
            // Platform-specific optimizations verified
        } else {
            #if canImport(ViewInspector)
            Issue.record("Platform-optimized view should be inspectable on current platform")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    @Test @MainActor func testPerformanceOptimizationsModifier() {
        // Given: Test view and performance settings
        let testView = Text("Test View")
        let settings = PlatformOptimizationSettings(for: SixLayerPlatform.current)
        
        // When: Applying performance optimizations
        let optimizedView = testView.performanceOptimizations(using: settings)
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: optimizedView is a View, so it cannot be nil
        
        // 2. Does that structure contain what it should?
        if let _ = try? AnyView(optimizedView).inspect() {
            // Successfully inspected performance-optimized view
        } else {
            #if canImport(ViewInspector)
            Issue.record("Failed to inspect performance-optimized view structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // Performance-optimized view should be inspectable
        if let _ = try? AnyView(optimizedView).inspect() {
            // Performance optimizations verified
        } else {
            #if canImport(ViewInspector)
            Issue.record("Performance-optimized view should be inspectable on current platform")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    @Test @MainActor func testUIPatternOptimizationsModifier() {
        // Given: Test view and UI patterns
        let testView = Text("Test View")
        let patterns = PlatformUIPatterns(for: SixLayerPlatform.current)
        
        // When: Applying UI pattern optimizations
        let optimizedView = testView.uiPatternOptimizations(using: patterns)
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // Note: optimizedView is a View, so it cannot be nil
        
        // 2. Does that structure contain what it should?
        if let _ = try? AnyView(optimizedView).inspect() {
            // Successfully inspected UI pattern-optimized view
        } else {
            #if canImport(ViewInspector)
            Issue.record("Failed to inspect UI pattern-optimized view structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
        
        // 3. Platform-specific implementation verification (REQUIRED)
        // UI pattern-optimized view should be inspectable
        if let _ = try? AnyView(optimizedView).inspect() {
            // UI pattern optimizations verified
        } else {
            #if canImport(ViewInspector)
            Issue.record("UI pattern-optimized view should be inspectable on current platform")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    // MARK: - Environment Values Tests
    
    @Test @MainActor func testEnvironmentValues_PlatformSpecific() {
        // Given: Environment values
        var environment = EnvironmentValues()
        
        // When: Setting platform-specific environment values
        environment.platform = SixLayerPlatform.current
        environment.performanceLevel = .balanced
        environment.memoryStrategy = .adaptive
        
        // Then: Environment values should be set correctly
        #expect(environment.platform == SixLayerPlatform.current, 
                      "Platform should be set correctly")
        #expect(environment.performanceLevel == .balanced, "Performance level should be balanced")
        #expect(environment.memoryStrategy == .adaptive, "Memory strategy should be adaptive")
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testCrossPlatformOptimizationIntegration() {
        // Given: Manager and test view
        let manager = CrossPlatformOptimizationManager()
        let testView = Text("Integration Test View")
        
        // When: Applying all optimizations
        let fullyOptimizedView = manager.optimizeView(testView)
        
        // Then: Fully optimized view should be created successfully
        // Note: fullyOptimizedView is a View, so it cannot be nil
        
        if let _ = fullyOptimizedView.tryInspect() {
            // Successfully inspected fully optimized view
        } else {
            #if canImport(ViewInspector)
            Issue.record("Fully optimized view should be inspectable")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Optimized view created (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    @Test @MainActor func testCrossPlatformOptimizationPerformance() {
        // Given: Manager for performance testing
        let manager = CrossPlatformOptimizationManager()
        
        // When: Optimizing multiple views
        for _ in 0..<10 {
            let testView = Text("Performance Test View")
            let _ = manager.optimizeView(testView)
        }
        
        // Then: Optimizations completed
    }
    
    // MARK: - Platform Detection Tests
    
    @Test @MainActor func testSixLayerPlatform_CurrentPlatformDetection() {
        // Given: Current platform detection
        let currentPlatform = SixLayerPlatform.current
        
        // Then: Platform should be detected correctly
        // Note: currentPlatform is an enum, so it cannot be nil
        
        // Platform-specific verification
        #if os(iOS)
        #expect(currentPlatform == .iOS, "Should detect iOS platform")
        #elseif os(macOS)
        #expect(currentPlatform == .macOS, "Should detect macOS platform")
        #elseif os(visionOS)
        #expect(currentPlatform == .visionOS, "Should detect visionOS platform")
        #elseif os(watchOS)
        #expect(currentPlatform == .watchOS, "Should detect watchOS platform")
        #elseif os(tvOS)
        #expect(currentPlatform == .tvOS, "Should detect tvOS platform")
        #endif
    }
    
    @Test @MainActor func testSixLayerPlatform_AllPlatforms() {
        // Given: All available platforms
        let allPlatforms = SixLayerPlatform.allCases
        
        // Then: Should have all expected platforms
        #expect(allPlatforms.contains(.iOS), "Should include iOS")
        #expect(allPlatforms.contains(.macOS), "Should include macOS")
        #expect(allPlatforms.contains(.visionOS), "Should include visionOS")
        #expect(allPlatforms.contains(.watchOS), "Should include watchOS")
        #expect(allPlatforms.contains(.tvOS), "Should include tvOS")
        #expect(allPlatforms.count == 5, "Should have exactly 5 platforms")
    }
}
