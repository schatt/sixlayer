//
//  L6PlatformSystemTests.swift
//  SixLayerFramework
//
//  Layer 6 Testing: Platform System Functions
//  Tests L6 functions that are direct platform system calls and native implementations
//

import Testing
import SwiftUI
@testable import SixLayerFramework

class L6PlatformSystemTests: BaseTestClass {
    
    // MARK: - Test Data Helpers (test isolation - each test creates fresh data)
    
    private func createSamplePlatform() -> Platform {
        return L6TestDataFactory.createSamplePlatform()
    }
    
    private func createSamplePlatformOptimizationSettings() -> PlatformOptimizationSettings {
        return L6TestDataFactory.createSamplePlatformOptimizationSettings()
    }
    
    private func createSampleCrossPlatformPerformanceMetrics() -> CrossPlatformPerformanceMetrics {
        return L6TestDataFactory.createSampleCrossPlatformPerformanceMetrics()
    }
    
    private func createSamplePlatformUIPatterns() -> PlatformUIPatterns {
        return L6TestDataFactory.createSamplePlatformUIPatterns()
    }
    
    private func createSamplePerformanceLevel() -> PerformanceLevel {
        return L6TestDataFactory.createSamplePerformanceLevel()
    }
    
    private func createSampleMemoryStrategy() -> MemoryStrategy {
        return L6TestDataFactory.createSampleMemoryStrategy()
    }
    
    private func createSampleRenderingOptimizations() -> RenderingOptimizations {
        return L6TestDataFactory.createSampleRenderingOptimizations()
    }
    
    private func createSampleNavigationPatterns() -> NavigationPatterns {
        return L6TestDataFactory.createSampleNavigationPatterns()
    }
    
    private func createSampleInteractionPatterns() -> InteractionPatterns {
        return L6TestDataFactory.createSampleInteractionPatterns()
    }
    
    private func createSampleLayoutPatterns() -> LayoutPatterns {
        return L6TestDataFactory.createSampleLayoutPatterns()
    }
    
    deinit {
        Task { [weak self] in
            await self?.cleanupTestEnvironment()
        }
    }
    
    // MARK: - Cross-Platform Optimization Manager Tests
    
    @Test func testCrossPlatformOptimizationManager() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let manager = CrossPlatformOptimizationManager(platform: platform)
        
        // Then
        #expect(manager.currentPlatform == platform, "Should have correct platform")
        #expect(manager.optimizationSettings != nil, "Should have optimization settings")
        #expect(manager.performanceMetrics != nil, "Should have performance metrics")
        #expect(manager.uiPatterns != nil, "Should have UI patterns")
    }
    
    @Test func testCrossPlatformOptimizationManagerOptimizeView() {
        // Given
        let manager = CrossPlatformOptimizationManager(platform: createSamplePlatform())
        let testView = Text("Test View")
        
        // When
        let optimizedView = manager.optimizeView(testView)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "CrossPlatformOptimizationManager.optimizeView")
    }
    
    // NOTE: PlatformRecommendationEngine tests moved to possible-features/PlatformRecommendationEngineTests.swift
    /*
    @Test func testCrossPlatformOptimizationManagerGetPlatformRecommendations() {
        // Given
        let manager = CrossPlatformOptimizationManager(platform: createSamplePlatform())
        
        // When
        let recommendations = manager.getPlatformRecommendations()
        
        // Then
        #expect(recommendations is [PlatformRecommendation], "Should return array of recommendations")
    }
    */
    
    // MARK: - Platform Optimization Settings Tests
    
    @Test func testPlatformOptimizationSettings() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let settings = PlatformOptimizationSettings(for: platform)
        
        // Then
        #expect(settings.performanceLevel == .balanced, "Should have balanced performance level")
        #expect(settings.memoryStrategy == .adaptive, "Should have adaptive memory strategy")
        #expect(settings.renderingOptimizations != nil, "Should have rendering optimizations")
        #expect(settings.featureFlags != nil, "Should have feature flags")
    }
    
    @Test func testPlatformOptimizationSettingsFeatureFlags() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let settings = PlatformOptimizationSettings(for: platform)
        let featureFlags = settings.featureFlags
        
        // Then
        #expect(!featureFlags.isEmpty, "Should have feature flags")
        // iOS should have specific feature flags
        if platform == .iOS {
            #expect(featureFlags["hapticFeedback"] == true, "iOS should have haptic feedback enabled")
            #expect(featureFlags["touchGestures"] == true, "iOS should have touch gestures enabled")
        }
    }
    
    // MARK: - Platform Recommendation Tests
    
    // NOTE: PlatformRecommendation tests moved to possible-features/PlatformRecommendationEngineTests.swift
    /*
    @Test func testPlatformRecommendation() {
        // Given
        let recommendation = samplePlatformRecommendation
        
        // When
        let title = recommendation.title
        let description = recommendation.description
        let category = recommendation.category
        let priority = recommendation.priority
        let platform = recommendation.platform
        let timestamp = recommendation.timestamp
        
        // Then
        #expect(title == "Test Recommendation", "Should have correct title")
        #expect(description == "Test Description", "Should have correct description")
        #expect(category == .performance, "Should have correct category")
        #expect(priority == .medium, "Should have correct priority")
        #expect(platform == .iOS, "Should have correct platform")
    }
    
    @Test func testRecommendationCategory() {
        // Given
        let category = sampleRecommendationCategory
        
        // When
        let rawValue = category.rawValue
        
        // Then
        #expect(rawValue == "performance", "Should have correct raw value")
        #expect(RecommendationCategory.allCases.contains(category), "Should be valid case")
    }
    
    @Test func testRecommendationCategoryAllCases() {
        // Given
        let allCategories = RecommendationCategory.allCases
        
        // When & Then
        for category in allCategories {
            #expect(!category.rawValue.isEmpty, "Category should have non-empty raw value")
            #expect(RecommendationCategory.allCases.contains(category), "Category should be valid")
        }
    }
    */
    
    // MARK: - Performance Level Tests
    
    @Test func testPerformanceLevel() {
        // Given
        let level = samplePerformanceLevel
        
        // When
        let rawValue = level.rawValue
        
        // Then
        #expect(rawValue == "balanced", "Should have correct raw value")
        #expect(PerformanceLevel.allCases.contains(level), "Should be valid case")
    }
    
    @Test func testPerformanceLevelAllCases() {
        // Given
        let allLevels = PerformanceLevel.allCases
        
        // When & Then
        for level in allLevels {
            #expect(!level.rawValue.isEmpty, "Level should have non-empty raw value")
            #expect(PerformanceLevel.allCases.contains(level), "Level should be valid")
        }
    }
    
    // MARK: - Memory Strategy Tests
    
    @Test func testMemoryStrategy() {
        // Given
        let strategy = sampleMemoryStrategy
        
        // When
        let rawValue = strategy.rawValue
        
        // Then
        #expect(rawValue == "adaptive", "Should have correct raw value")
        #expect(MemoryStrategy.allCases.contains(strategy), "Should be valid case")
    }
    
    @Test func testMemoryStrategyAllCases() {
        // Given
        let allStrategies = MemoryStrategy.allCases
        
        // When & Then
        for strategy in allStrategies {
            #expect(!strategy.rawValue.isEmpty, "Strategy should have non-empty raw value")
            #expect(MemoryStrategy.allCases.contains(strategy), "Strategy should be valid")
        }
    }
    
    // MARK: - Rendering Optimizations Tests
    
    @Test func testRenderingOptimizations() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let optimizations = RenderingOptimizations(for: platform)
        
        // Then
        #expect(optimizations.hardwareAcceleration, "Rendering optimizations enable hardware acceleration")
        #expect(optimizations.metalRendering == (platform == .macOS || platform == .iOS), "Metal rendering follows iOS/macOS")
    }
    
    // MARK: - Platform UI Patterns Tests
    
    @Test func testPlatformUIPatterns() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let patterns = PlatformUIPatterns(for: platform)
        
        // Then
        #expect(patterns.platform == platform, "UI patterns should match the requested platform")
    }
    
    // MARK: - Navigation Patterns Tests
    
    @Test func testNavigationPatterns() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let patterns = NavigationPatterns(for: platform)
        
        // Then
        #expect(patterns.platform == platform, "Navigation patterns should match the requested platform")
    }
    
    // MARK: - Interaction Patterns Tests
    
    @Test func testInteractionPatterns() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let patterns = InteractionPatterns(for: platform)
        
        // Then
        #expect(patterns.platform == platform, "Interaction patterns should match the requested platform")
    }
    
    // MARK: - Layout Patterns Tests
    
    @Test func testLayoutPatterns() {
        // Given
        let platform = createSamplePlatform()
        
        // When
        let patterns = LayoutPatterns(for: platform)
        
        // Then
        #expect(patterns.platform == platform, "Layout patterns should match the requested platform")
    }
    
    // MARK: - Cross-Platform Performance Metrics Tests
    
    @Test func testCrossPlatformPerformanceMetrics() {
        // Given
        let metrics = createSampleCrossPlatformPerformanceMetrics()
        #expect(metrics.platformMetrics.count == SixLayerPlatform.allCases.count, "Metrics should include every platform")
    }
    
    // MARK: - View Extension Tests
    
    @Test func testPlatformSpecificOptimizations() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        
        // When
        let optimizedView = testView.platformSpecificOptimizations(for: platform)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "platformSpecificOptimizations")
    }
    
    @Test func testPerformanceOptimizations() {
        // Given
        let testView = Text("Test View")
        let settings = samplePlatformOptimizationSettings
        
        // When
        let optimizedView = testView.performanceOptimizations(using: settings)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "performanceOptimizations")
    }
    
    @Test func testUIPatternOptimizations() {
        // Given
        let testView = Text("Test View")
        let patterns = samplePlatformUIPatterns
        
        // When
        let optimizedView = testView.uiPatternOptimizations(using: patterns)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "uiPatternOptimizations")
    }
    
    // MARK: - Platform System Integration Tests
    
    @Test func testPlatformSystemIntegration() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        let settings = samplePlatformOptimizationSettings
        let patterns = samplePlatformUIPatterns
        
        // When
        let fullyOptimizedView = testView
            .platformSpecificOptimizations(for: platform)
            .performanceOptimizations(using: settings)
            .uiPatternOptimizations(using: patterns)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(fullyOptimizedView, testName: "Platform system integration")
    }
    
    @Test func testPlatformSystemConsistency() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        
        // When
        let view1 = testView.platformSpecificOptimizations(for: platform)
        let view2 = testView.platformSpecificOptimizations(for: platform)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(view1, testName: "Platform system consistency test 1")
        LayeredTestUtilities.verifyViewCreation(view2, testName: "Platform system consistency test 2")
        // Both optimizations should be applied consistently
    }
    
    @Test func testPlatformSystemPerformance() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        
        // When
        let optimizedView = testView.platformSpecificOptimizations(for: platform)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "Platform system performance test")
    }
    
    // MARK: - Edge Case Testing
    
    @Test func testPlatformSystemWithEmptyView() {
        // Given
        let emptyView = EmptyView()
        let platform = createSamplePlatform()
        
        // When
        let optimizedView = emptyView.platformSpecificOptimizations(for: platform)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "Empty view platform system optimization")
        // Should handle empty views gracefully
    }
    
    @Test func testPlatformSystemWithComplexView() {
        // Given
        let complexView = platformVStackContainer {
            Text("Title")
            platformHStackContainer {
                Text("Left")
                Text("Right")
            }
            LazyplatformVStackContainer {
                ForEach(0..<10) { index in
                    Text("Item \(index)")
                }
            }
        }
        let platform = createSamplePlatform()
        
        // When
        let optimizedView = complexView.platformSpecificOptimizations(for: platform)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(optimizedView, testName: "Complex view platform system optimization")
        // Should handle complex views gracefully
    }
    
    // MARK: - Platform-Specific System Testing
    
    @Test func testPlatformSpecificSystemBehavior() {
        // Given
        let testView = Text("Test View")
        
        // When
        let iOSView = testView.platformSpecificOptimizations(for: .iOS)
        let macOSView = testView.platformSpecificOptimizations(for: .macOS)
        let watchOSView = testView.platformSpecificOptimizations(for: .watchOS)
        let tvOSView = testView.platformSpecificOptimizations(for: .tvOS)
        let visionOSView = testView.platformSpecificOptimizations(for: .visionOS)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(iOSView, testName: "iOS platform system")
        LayeredTestUtilities.verifyViewCreation(macOSView, testName: "macOS platform system")
        LayeredTestUtilities.verifyViewCreation(watchOSView, testName: "watchOS platform system")
        LayeredTestUtilities.verifyViewCreation(tvOSView, testName: "tvOS platform system")
        LayeredTestUtilities.verifyViewCreation(visionOSView, testName: "visionOS platform system")
    }
    
    @Test func testPlatformSystemFeatureFlags() {
        // Given
        let iOSSettings = PlatformOptimizationSettings(for: .iOS)
        let macOSSettings = PlatformOptimizationSettings(for: .macOS)
        let watchOSSettings = PlatformOptimizationSettings(for: .watchOS)
        let tvOSSettings = PlatformOptimizationSettings(for: .tvOS)
        let visionOSSettings = PlatformOptimizationSettings(for: .visionOS)
        
        // When & Then
        // iOS should have touch and haptic features
        #expect(iOSSettings.featureFlags["touchGestures"] == true, "iOS should support touch gestures")
        #expect(iOSSettings.featureFlags["hapticFeedback"] == true, "iOS should support haptic feedback")
        
        // macOS should have keyboard and mouse features
        #expect(macOSSettings.featureFlags["keyboardNavigation"] == true, "macOS should support keyboard navigation")
        #expect(macOSSettings.featureFlags["mouseOptimization"] == true, "macOS should support mouse optimization")
        
        // watchOS should have Digital Crown and complications
        #expect(watchOSSettings.featureFlags["digitalCrown"] == true, "watchOS should support Digital Crown")
        #expect(watchOSSettings.featureFlags["complications"] == true, "watchOS should support complications")
        
        // tvOS should have remote control and focus engine
        #expect(tvOSSettings.featureFlags["remoteControl"] == true, "tvOS should support remote control")
        #expect(tvOSSettings.featureFlags["focusEngine"] == true, "tvOS should support focus engine")
        
        // visionOS should have spatial UI and hand tracking
        #expect(visionOSSettings.featureFlags["spatialUI"] == true, "visionOS should support spatial UI")
        #expect(visionOSSettings.featureFlags["handTracking"] == true, "visionOS should support hand tracking")
    }
    
    // MARK: - System Integration Testing
    
    @Test func testSystemIntegrationWithAllLayers() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        let settings = samplePlatformOptimizationSettings
        let patterns = samplePlatformUIPatterns
        
        // When
        let fullyIntegratedView = testView
            .platformSpecificOptimizations(for: platform)
            .performanceOptimizations(using: settings)
            .uiPatternOptimizations(using: patterns)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(fullyIntegratedView, testName: "Full system integration test")
        // Should integrate all L6 system components successfully
    }
    
    @Test func testSystemIntegrationPerformance() {
        // Given
        let testView = Text("Test View")
        let platform = createSamplePlatform()
        let settings = samplePlatformOptimizationSettings
        let patterns = samplePlatformUIPatterns
        
        // When
        let fullyIntegratedView = testView
            .platformSpecificOptimizations(for: platform)
            .performanceOptimizations(using: settings)
            .uiPatternOptimizations(using: patterns)
        
        // Then
        LayeredTestUtilities.verifyViewCreation(fullyIntegratedView, testName: "System integration performance test")
    }
}









