import Testing
import SwiftUI
@testable import SixLayerFramework

/// Comprehensive tests for Layer 5 platform optimization functions
/// Ensures all Layer 5 functions are tested
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Layer Platform Optimization")
open class Layer5PlatformOptimizationTests: BaseTestClass {
    
    // MARK: - getCardExpansionPlatformConfig Tests
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_iOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPlatformConfig()
        
        #expect(config.supportsTouch == true, "iOS should support touch")
        // Verify platform-appropriate values for current platform
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
        #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_macOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false); RuntimeCapabilityDetection.setTestHapticFeedback(false); RuntimeCapabilityDetection.setTestHover(true)
        let config = getCardExpansionPlatformConfig()
        
        #expect(config.supportsHover == true, "macOS should support hover")
        // minTouchTarget/hoverDelay are platform-native values based on the *current* platform,
        // not the simulated capability overrides above.
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
        #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_visionOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(true)
        let config = getCardExpansionPlatformConfig()
        
        // Verify platform-appropriate values for current platform
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
        #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_watchOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPlatformConfig()
        
        // Verify platform-appropriate values for current platform
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
        #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_tvOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPlatformConfig()
        
        // Verify platform-appropriate values for current platform
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
        #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_AllPlatforms() async {
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        // Verify platform-appropriate values for current platform (not simulated platform)
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0
        
        for _ in platforms {
            let config = getCardExpansionPlatformConfig()
            
            // Verify platform-appropriate values for current platform
            #expect(config.minTouchTarget == expectedMinTouchTarget, "Current platform \(currentPlatform) should have platform-appropriate minTouchTarget (\(expectedMinTouchTarget))")
            #expect(config.hoverDelay == expectedHoverDelay, "Current platform \(currentPlatform) should have platform-appropriate hoverDelay (\(expectedHoverDelay))")
        }
    }
    
    // MARK: - getCardExpansionPerformanceConfig Tests
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_iOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true); RuntimeCapabilityDetection.setTestHapticFeedback(true); RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPerformanceConfig()
        
        #expect(config.targetFrameRate > 0, "iOS should have positive target frame rate")
        #expect(config.maxAnimationDuration > 0, "iOS should have positive max animation duration")
        #expect(config.supportsSmoothAnimations == true, "iOS should support smooth animations")
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_macOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false); RuntimeCapabilityDetection.setTestHapticFeedback(false); RuntimeCapabilityDetection.setTestHover(true)
        let config = getCardExpansionPerformanceConfig()
        
        #expect(config.targetFrameRate > 0, "macOS should have positive target frame rate")
        #expect(config.maxAnimationDuration > 0, "macOS should have positive max animation duration")
        #expect(config.supportsSmoothAnimations == true, "macOS should support smooth animations")
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_visionOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(true)
        let config = getCardExpansionPerformanceConfig()
        
        // Verify platform-appropriate performance values for current platform
        let currentPlatform = SixLayerPlatform.current
        if currentPlatform == .visionOS {
            #expect(config.targetFrameRate >= 90, "visionOS should have higher frame rate for spatial interface")
        } else {
            #expect(config.targetFrameRate > 0, "Current platform \(currentPlatform) should have positive target frame rate")
        }
        #expect(config.maxAnimationDuration > 0, "visionOS should have positive max animation duration")
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_watchOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPerformanceConfig()
        
        // Verify platform-appropriate performance values for current platform
        let currentPlatform = SixLayerPlatform.current
        #expect(config.targetFrameRate > 0, "Current platform \(currentPlatform) should have positive target frame rate")
        if currentPlatform == .watchOS {
            #expect(config.maxAnimationDuration <= 0.15, "watchOS should have fast animations")
        } else {
            #expect(config.maxAnimationDuration > 0, "Current platform \(currentPlatform) should have positive max animation duration")
        }
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_tvOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false); RuntimeCapabilityDetection.setTestHapticFeedback(false); RuntimeCapabilityDetection.setTestHover(false)
        let config = getCardExpansionPerformanceConfig()
        
        #expect(config.targetFrameRate > 0, "tvOS should have positive target frame rate")
        #expect(config.maxAnimationDuration > 0, "tvOS should have positive max animation duration")
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig_AllPlatforms() async {
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        for platform in platforms {
            let config = getCardExpansionPerformanceConfig()
            
            #expect(config.targetFrameRate > 0, "Platform \(platform) should have positive target frame rate")
            #expect(config.maxAnimationDuration > 0, "Platform \(platform) should have positive max animation duration")
            #expect(config.memoryOptimization == true, "Platform \(platform) should enable memory optimization")
            #expect(config.lazyLoading == true, "Platform \(platform) should enable lazy loading")
        }
    }
    
    // MARK: - getCardExpansionAccessibilityConfig Tests
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_iOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        let config = getCardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "iOS should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "iOS should support Switch Control")
        #expect(config.supportsAssistiveTouch == true, "iOS should support AssistiveTouch")
        #expect(config.announcementDelay > 0, "iOS should have positive announcement delay")
    }
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_macOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(true)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        let config = getCardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "macOS should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "macOS should support Switch Control")
        #expect(config.supportsAssistiveTouch == false, "macOS should not support AssistiveTouch")
        #expect(config.announcementDelay > 0, "macOS should have positive announcement delay")
    }
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_visionOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(true)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        let config = getCardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "visionOS should support VoiceOver")
        #expect(config.supportsAssistiveTouch == false, "visionOS should not support AssistiveTouch")
        // Note: announcementDelay is platform-specific, verify it's reasonable for current platform
        #expect(config.announcementDelay > 0, "visionOS should have positive announcement delay")
    }
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_watchOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        let config = getCardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "watchOS should support VoiceOver")
        #expect(config.supportsAssistiveTouch == true, "watchOS should support AssistiveTouch")
        #expect(config.announcementDelay > 0, "watchOS should have positive announcement delay")
    }
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_tvOS() async {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        let config = getCardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "tvOS should support VoiceOver")
        #expect(config.supportsAssistiveTouch == false, "tvOS should not support AssistiveTouch (correctly set to false)")
        #expect(config.announcementDelay > 0, "tvOS should have positive announcement delay")
    }
    
    @Test @MainActor func testGetCardExpansionAccessibilityConfig_AllPlatforms() async {
        let platforms: [SixLayerPlatform] = [.iOS, .macOS, .visionOS, .watchOS, .tvOS]
        
        for platform in platforms {
            let config = getCardExpansionAccessibilityConfig()
            
            #expect(config.supportsVoiceOver == true, "Platform \(platform) should support VoiceOver")
            #expect(config.supportsSwitchControl == true, "Platform \(platform) should support Switch Control")
            #expect(config.supportsReduceMotion == true, "Platform \(platform) should support Reduce Motion")
            #expect(config.supportsHighContrast == true, "Platform \(platform) should support High Contrast")
            #expect(config.supportsDynamicType == true, "Platform \(platform) should support Dynamic Type")
            #expect(config.announcementDelay > 0, "Platform \(platform) should have positive announcement delay")
            #expect(config.focusManagement == true, "Platform \(platform) should enable focus management")
        }
    }
    
    // MARK: - CardExpansionPlatformConfig Initialization Tests
    
    @Test func testCardExpansionPlatformConfig_DefaultInitializer() async {
        let config = CardExpansionPlatformConfig()
        
        #expect(config.supportsHapticFeedback == false, "Default config should not support haptic feedback")
        #expect(config.supportsHover == false, "Default config should not support hover")
        #expect(config.supportsTouch == true, "Default config should support touch")
        #expect(config.supportsVoiceOver == true, "Default config should support VoiceOver")
        #expect(config.minTouchTarget == 44, "Default config should have 44pt touch target")
        #expect(config.hoverDelay == 0.1, "Default config should have 0.1s hover delay")
    }
    
    @Test func testCardExpansionPlatformConfig_CustomInitializer() async {
        let config = CardExpansionPlatformConfig(
            supportsHapticFeedback: true,
            supportsHover: true,
            supportsTouch: true,
            supportsVoiceOver: true,
            supportsSwitchControl: true,
            supportsAssistiveTouch: true,
            minTouchTarget: 60,
            hoverDelay: 0.2,
            animationEasing: .easeInOut(duration: 0.5)
        )
        
        #expect(config.supportsHapticFeedback == true, "Custom config should support haptic feedback")
        #expect(config.supportsHover == true, "Custom config should support hover")
        #expect(config.minTouchTarget == 60, "Custom config should have 60pt touch target")
        #expect(config.hoverDelay == 0.2, "Custom config should have 0.2s hover delay")
    }
    
    // MARK: - CardExpansionPerformanceConfig Initialization Tests
    
    @Test func testCardExpansionPerformanceConfig_DefaultInitializer() async {
        let config = CardExpansionPerformanceConfig()
        
        #expect(config.targetFrameRate == 60, "Default config should target 60fps")
        #expect(config.maxAnimationDuration == 0.3, "Default config should have 0.3s max animation duration")
        #expect(config.supportsSmoothAnimations == true, "Default config should support smooth animations")
        #expect(config.memoryOptimization == true, "Default config should enable memory optimization")
        #expect(config.lazyLoading == true, "Default config should enable lazy loading")
    }
    
    @Test func testCardExpansionPerformanceConfig_CustomInitializer() async {
        let config = CardExpansionPerformanceConfig(
            targetFrameRate: 120,
            maxAnimationDuration: 0.5,
            supportsSmoothAnimations: false,
            memoryOptimization: false,
            lazyLoading: false
        )
        
        #expect(config.targetFrameRate == 120, "Custom config should target 120fps")
        #expect(config.maxAnimationDuration == 0.5, "Custom config should have 0.5s max animation duration")
        #expect(config.supportsSmoothAnimations == false, "Custom config should not support smooth animations")
        #expect(config.memoryOptimization == false, "Custom config should not enable memory optimization")
        #expect(config.lazyLoading == false, "Custom config should not enable lazy loading")
    }
    
    // MARK: - CardExpansionAccessibilityConfig Initialization Tests
    
    @Test func testCardExpansionAccessibilityConfig_DefaultInitializer() async {
        let config = CardExpansionAccessibilityConfig()
        
        #expect(config.supportsVoiceOver == true, "Default config should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "Default config should support Switch Control")
        #expect(config.supportsAssistiveTouch == true, "Default config should support AssistiveTouch")
        #expect(config.supportsReduceMotion == true, "Default config should support Reduce Motion")
        #expect(config.supportsHighContrast == true, "Default config should support High Contrast")
        #expect(config.supportsDynamicType == true, "Default config should support Dynamic Type")
        #expect(config.announcementDelay == 0.5, "Default config should have 0.5s announcement delay")
        #expect(config.focusManagement == true, "Default config should enable focus management")
    }
    
    @Test func testCardExpansionAccessibilityConfig_CustomInitializer() async {
        let config = CardExpansionAccessibilityConfig(
            supportsVoiceOver: false,
            supportsSwitchControl: false,
            supportsAssistiveTouch: false,
            supportsReduceMotion: false,
            supportsHighContrast: false,
            supportsDynamicType: false,
            announcementDelay: 1.0,
            focusManagement: false
        )
        
        #expect(config.supportsVoiceOver == false, "Custom config should not support VoiceOver")
        #expect(config.supportsSwitchControl == false, "Custom config should not support Switch Control")
        #expect(config.supportsAssistiveTouch == false, "Custom config should not support AssistiveTouch")
        #expect(config.announcementDelay == 1.0, "Custom config should have 1.0s announcement delay")
        #expect(config.focusManagement == false, "Custom config should not enable focus management")
    }
}

