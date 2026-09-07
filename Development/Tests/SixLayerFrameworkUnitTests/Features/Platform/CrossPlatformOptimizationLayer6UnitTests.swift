import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * Unit-lane coverage for CrossPlatformOptimizationLayer6 (#458).
 * VI suite under ViewInspectorTests/ is excluded from SLF-*-UnitTests.
 */

@Suite("CrossPlatform Optimization Layer6 Unit", DefaultRuntimeCapabilityIsolationTrait())
struct CrossPlatformOptimizationLayer6UnitTests {

    // MARK: - Enums (deliberate red: wrong PerformanceLevel count)

    @Test func testPerformanceLevelCasesAndMultipliers() {
        // Deliberate red for #458 until locked to production (4).
        #expect(PerformanceLevel.allCases.count == 99)
        #expect(PerformanceLevel.low.optimizationMultiplier == 0.5)
        #expect(PerformanceLevel.balanced.optimizationMultiplier == 1.0)
        #expect(PerformanceLevel.high.optimizationMultiplier == 1.5)
        #expect(PerformanceLevel.maximum.optimizationMultiplier == 2.0)
        #expect(PerformanceLevel.low.optimizationMultiplier < PerformanceLevel.balanced.optimizationMultiplier)
        #expect(PerformanceLevel.balanced.optimizationMultiplier < PerformanceLevel.high.optimizationMultiplier)
        #expect(PerformanceLevel.high.optimizationMultiplier < PerformanceLevel.maximum.optimizationMultiplier)
    }

    @Test func testMemoryStrategyCasesAndThresholds() {
        #expect(MemoryStrategy.allCases.count == 3)
        #expect(MemoryStrategy.conservative.memoryThreshold == 0.3)
        #expect(MemoryStrategy.adaptive.memoryThreshold == 0.5)
        #expect(MemoryStrategy.aggressive.memoryThreshold == 0.7)
        #expect(MemoryStrategy.conservative.memoryThreshold < MemoryStrategy.adaptive.memoryThreshold)
        #expect(MemoryStrategy.adaptive.memoryThreshold < MemoryStrategy.aggressive.memoryThreshold)
    }

    // MARK: - PlatformOptimizationSettings

    @Test @MainActor
    func testPlatformOptimizationSettingsFeatureFlagsPerPlatform() {
        let ios = PlatformOptimizationSettings(for: .iOS)
        #expect(ios.performanceLevel == .balanced)
        #expect(ios.memoryStrategy == .adaptive)
        #expect(ios.featureFlags["hapticFeedback"] == true)
        #expect(ios.featureFlags["touchGestures"] == true)
        #expect(ios.featureFlags["keyboardAvoidance"] == true)
        #expect(ios.featureFlags["safeAreaOptimization"] == true)

        let mac = PlatformOptimizationSettings(for: .macOS)
        #expect(mac.featureFlags["keyboardNavigation"] == true)
        #expect(mac.featureFlags["mouseOptimization"] == true)
        #expect(mac.featureFlags["windowManagement"] == true)
        #expect(mac.featureFlags["menuBarIntegration"] == true)

        let watch = PlatformOptimizationSettings(for: .watchOS)
        #expect(watch.featureFlags["digitalCrown"] == true)
        #expect(watch.featureFlags["complications"] == true)

        let tv = PlatformOptimizationSettings(for: .tvOS)
        #expect(tv.featureFlags["focusEngine"] == true)
        #expect(tv.featureFlags["siriRemote"] == true)

        let vision = PlatformOptimizationSettings(for: .visionOS)
        #expect(vision.featureFlags["spatialUI"] == true)
        #expect(vision.featureFlags["handTracking"] == true)
        #expect(vision.featureFlags["eyeTracking"] == true)
    }

    @Test @MainActor
    func testRenderingOptimizationsMetalOnAppleDesktopMobile() {
        let ios = RenderingOptimizations(for: .iOS)
        #expect(ios.hardwareAcceleration)
        #expect(ios.metalRendering)

        let mac = RenderingOptimizations(for: .macOS)
        #expect(mac.metalRendering)

        let watch = RenderingOptimizations(for: .watchOS)
        #expect(!watch.metalRendering)
    }

    // MARK: - Manager

    @Test @MainActor
    func testCrossPlatformOptimizationManagerInitForEachPlatform() {
        for platform in SixLayerPlatform.allCases {
            let manager = CrossPlatformOptimizationManager(platform: platform)
            #expect(manager.currentPlatform == platform)
            #expect(manager.optimizationSettings.performanceLevel == .balanced)
            #expect(manager.uiPatterns.navigationPatterns.platform == platform)
        }
    }

    @Test @MainActor
    func testCrossPlatformOptimizationManagerOptimizeViewReturnsView() {
        let manager = CrossPlatformOptimizationManager(platform: .iOS)
        let optimized = manager.optimizeView(Text("optimize-root"))
        BaseTestClass.expectViewSubjectTypeContains(optimized, rootViewName: "Text")
    }

    @Test @MainActor
    func testPlatformUIPatternsConstructForCurrentPlatform() {
        let patterns = PlatformUIPatterns(for: SixLayerPlatform.current)
        #expect(patterns.platform == SixLayerPlatform.current)
        #expect(patterns.navigationPatterns.platform == SixLayerPlatform.current)
    }
}
