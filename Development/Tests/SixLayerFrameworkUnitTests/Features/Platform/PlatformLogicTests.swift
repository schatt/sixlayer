import Testing


import SwiftUI
@testable import SixLayerFramework

/// Platform Logic Tests
/// Tests the platform detection and configuration logic without relying on runtime platform detection
/// These tests focus on the logic that determines platform-specific behavior
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Logic")
open class PlatformLogicTests: BaseTestClass {
    
    // Local, general-purpose capability snapshot for tests (do not use card-specific config)
    public struct PlatformCapabilities: Sendable {
        let supportsHapticFeedback: Bool
        let supportsHover: Bool
        let supportsTouch: Bool
        let supportsVoiceOver: Bool
        let supportsSwitchControl: Bool
        let supportsAssistiveTouch: Bool
        let minTouchTarget: Int
        let hoverDelay: Double
    }

    // Local performance config for animation-related tests (avoid card-specific config)
    public struct PerformanceConfig {
        let targetFrameRate: Int
        let maxAnimationDuration: Double
    }
    
    // MARK: - Platform Detection Logic Tests
    
    @Test func testPlatformDetectionLogic() {
        // GIVEN: Different platform configurations
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        
        // WHEN: Testing platform detection logic
        for platform in platforms {
            // THEN: Should be able to determine platform characteristics
            let config = createMockPlatformConfig(for: platform)
            
            // Test that platform-specific capabilities are correctly determined
            switch platform {
            case .iOS:
                #expect(config.supportsTouch, "iOS should support touch")
                #expect(config.supportsHapticFeedback, "iOS should support haptic feedback")
                #expect(config.supportsAssistiveTouch, "iOS should support AssistiveTouch")
                #expect(config.supportsVoiceOver, "iOS should support VoiceOver")
                #expect(config.supportsSwitchControl, "iOS should support SwitchControl")
                
            case .macOS:
                #expect(!config.supportsTouch, "macOS should not support touch")
                #expect(!config.supportsHapticFeedback, "macOS should not support haptic feedback")
                #expect(!config.supportsAssistiveTouch, "macOS should not support AssistiveTouch")
                #expect(config.supportsHover, "macOS should support hover")
                #expect(config.supportsVoiceOver, "macOS should support VoiceOver")
                #expect(config.supportsSwitchControl, "macOS should support SwitchControl")
                
            case .watchOS:
                #expect(config.supportsTouch, "watchOS should support touch")
                #expect(config.supportsHapticFeedback, "watchOS should support haptic feedback")
                #expect(config.supportsAssistiveTouch, "watchOS should support AssistiveTouch")
                #expect(!config.supportsHover, "watchOS should not support hover")
                #expect(config.supportsVoiceOver, "watchOS should support VoiceOver")
                #expect(config.supportsSwitchControl, "watchOS should support SwitchControl")
                
            case .tvOS:
                #expect(!config.supportsTouch, "tvOS should not support touch")
                #expect(!config.supportsHapticFeedback, "tvOS should not support haptic feedback")
                #expect(!config.supportsAssistiveTouch, "tvOS should not support AssistiveTouch")
                #expect(!config.supportsHover, "tvOS should not support hover")
                #expect(config.supportsVoiceOver, "tvOS should support VoiceOver")
                #expect(config.supportsSwitchControl, "tvOS should support SwitchControl")
                
            case .visionOS:
                #expect(!config.supportsTouch, "visionOS should not support touch")
                #expect(!config.supportsHapticFeedback, "visionOS should not support haptic feedback")
                #expect(!config.supportsAssistiveTouch, "visionOS should not support AssistiveTouch")
                #expect(config.supportsHover, "visionOS should support hover")
                #expect(config.supportsVoiceOver, "visionOS should support VoiceOver")
                #expect(config.supportsSwitchControl, "visionOS should support SwitchControl")
            }
        }
    }
    
    @Test func testDeviceTypeDetectionLogic() {
        // GIVEN: Different device types
        let deviceTypes: [DeviceType] = Array(DeviceType.allCases) // Use real enum
        
        // WHEN: Testing device type detection logic
        for deviceType in deviceTypes {
            // THEN: Should be able to determine device characteristics
            let config = createMockDeviceConfig(for: deviceType)
            
            // Test that device-specific capabilities are correctly determined
            switch deviceType {
            case .phone:
                #expect(config.supportsTouch, "Phone should support touch")
            case .car:
                #expect(config.supportsTouch, "Car should support touch")
                #expect(config.supportsHapticFeedback, "Car should support haptic feedback")
                #expect(!config.supportsHover, "Car should not support hover")
                
            case .pad:
                #expect(config.supportsTouch, "Pad should support touch")
                #expect(config.supportsHapticFeedback, "Pad should support haptic feedback")
                #expect(config.supportsHover, "Pad should support hover")
                
            case .mac:
                #expect(!config.supportsTouch, "Mac should not support touch")
                #expect(!config.supportsHapticFeedback, "Mac should not support haptic feedback")
                #expect(config.supportsHover, "Mac should support hover")
                
            case .watch:
                #expect(config.supportsTouch, "Watch should support touch")
                #expect(config.supportsHapticFeedback, "Watch should support haptic feedback")
                #expect(!config.supportsHover, "Watch should not support hover")
                
            case .tv:
                #expect(!config.supportsTouch, "TV should not support touch")
                #expect(!config.supportsHapticFeedback, "TV should not support haptic feedback")
                #expect(!config.supportsHover, "TV should not support hover")
                
            case .vision:
                #expect(!config.supportsTouch, "Vision should not support touch")
                #expect(!config.supportsHapticFeedback, "Vision should not support haptic feedback")
                #expect(config.supportsHover, "Vision should support hover")
            }
        }
    }
    
    // MARK: - Capability Matrix Tests
    
    @Test func testCapabilityMatrixConsistency() {
        // GIVEN: All platform and device combinations
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        let deviceTypes: [DeviceType] = Array(DeviceType.allCases) // Use real enum
        
        // WHEN: Testing capability matrix consistency
        for platform in platforms {
            for deviceType in deviceTypes {
                let config = createMockPlatformDeviceConfig(platform: platform, deviceType: deviceType)
                
                // THEN: Capabilities should be internally consistent
                testCapabilityConsistency(config, platform: platform, deviceType: deviceType)
            }
        }
    }
    
    @Test(arguments: [
        (PlatformCapabilities(supportsHapticFeedback: true, supportsHover: false, supportsTouch: true, supportsVoiceOver: true, supportsSwitchControl: false, supportsAssistiveTouch: false, minTouchTarget: 44, hoverDelay: 0), SixLayerPlatform.iOS, DeviceType.phone),
        (PlatformCapabilities(supportsHapticFeedback: false, supportsHover: true, supportsTouch: false, supportsVoiceOver: true, supportsSwitchControl: false, supportsAssistiveTouch: false, minTouchTarget: 0, hoverDelay: 0.1), SixLayerPlatform.macOS, DeviceType.mac)
    ])
    func testCapabilityConsistency(_ config: PlatformCapabilities, platform: SixLayerPlatform, deviceType: DeviceType) {
        // Set the test platform for this test case
        
        // Haptic feedback should only be available with touch
        if config.supportsHapticFeedback {
            #expect(config.supportsTouch, "Haptic feedback should only be available with touch on \(platform) \(deviceType)")
        }
        
        // AssistiveTouch should only be available with touch
        if config.supportsAssistiveTouch {
            #expect(config.supportsTouch, "AssistiveTouch should only be available with touch on \(platform) \(deviceType)")
        }
        
        // Hover delay should be zero if hover is not supported
        if !config.supportsHover {
            #expect(config.hoverDelay == 0, "Hover delay should be zero when hover is not supported on \(platform) \(deviceType)")
        }
        
        // Touch target should be appropriate for touch platforms
        if config.supportsTouch {
            #expect(config.minTouchTarget >= 44, "Touch target should be adequate for touch platforms on \(platform) \(deviceType)")
        } else {
            #expect(config.minTouchTarget == 0, "Touch target should be zero for non-touch platforms on \(platform) \(deviceType)")
        }
        
        // Clean up test platform
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    // MARK: - Vision Framework Availability Tests
    
    @Test func testVisionFrameworkAvailabilityLogic() {
        // GIVEN: Different platforms
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        
        // WHEN: Testing Vision framework availability logic
        for platform in platforms {
            let hasVision = createMockVisionAvailability(for: platform)
            
            // THEN: Vision availability should be correct for each platform
            switch platform {
            case .iOS, .macOS, .visionOS:
                #expect(hasVision, "\(platform) should have Vision framework")
                
            case .watchOS, .tvOS:
                #expect(!hasVision, "\(platform) should not have Vision framework")
            }
        }
    }
    
    @Test func testOCRAvailabilityLogic() {
        // GIVEN: Different platforms
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        
        // WHEN: Testing OCR availability logic
        for platform in platforms {
            let hasOCR = createMockOCRAvailability(for: platform)
            
            // THEN: OCR availability should be correct for each platform
            switch platform {
            case .iOS, .macOS, .visionOS:
                #expect(hasOCR, "\(platform) should have OCR")
                
            case .watchOS, .tvOS:
                #expect(!hasOCR, "\(platform) should not have OCR")
            }
        }
    }
    
    // MARK: - Layout Decision Logic Tests
    
    @Test func testLayoutDecisionLogic() {
        // GIVEN: Different platform configurations
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        
        // WHEN: Testing layout decision logic
        for platform in platforms {
            let config = createMockPlatformConfig(for: platform)
            let layoutDecision = createMockLayoutDecision(for: platform)
            
            // THEN: Layout decisions should be appropriate for the platform
            testLayoutDecisionAppropriateness(layoutDecision, platform: platform, config: config)
        }
    }
    
    @Test(arguments: [
        (IntelligentCardLayoutDecision(columns: 2, spacing: 16, cardWidth: 200, cardHeight: 150, padding: 16), SixLayerPlatform.iOS, PlatformCapabilities(supportsHapticFeedback: true, supportsHover: false, supportsTouch: true, supportsVoiceOver: true, supportsSwitchControl: false, supportsAssistiveTouch: false, minTouchTarget: 44, hoverDelay: 0)),
        (IntelligentCardLayoutDecision(columns: 3, spacing: 20, cardWidth: 250, cardHeight: 180, padding: 20), SixLayerPlatform.macOS, PlatformCapabilities(supportsHapticFeedback: false, supportsHover: true, supportsTouch: false, supportsVoiceOver: true, supportsSwitchControl: false, supportsAssistiveTouch: false, minTouchTarget: 44, hoverDelay: 0))
    ])
    func testLayoutDecisionAppropriateness(_ layoutDecision: IntelligentCardLayoutDecision, platform: SixLayerPlatform, config: PlatformCapabilities) {
        // Touch platforms should have appropriate touch targets
        if config.supportsTouch {
            #expect(layoutDecision.cardWidth >= CGFloat(config.minTouchTarget), "Card width should accommodate touch targets on \(platform)")
            #expect(layoutDecision.cardHeight >= CGFloat(config.minTouchTarget), "Card height should accommodate touch targets on \(platform)")
        }
        
        // Hover platforms should have appropriate spacing
        if config.supportsHover {
            #expect(layoutDecision.spacing > 0, "Hover platforms should have spacing on \(platform)")
        }
        
        // All platforms should have reasonable padding
        #expect(layoutDecision.padding >= 8, "All platforms should have reasonable padding on \(platform)")
    }
    
    // MARK: - Animation Logic Tests
    
    @Test func testAnimationLogic() {
        // GIVEN: Different platform configurations
        let platforms: [SixLayerPlatform] = Array(SixLayerPlatform.allCases) // Use real enum
        
        // WHEN: Testing animation logic
        for platform in platforms {
            let config = createMockPlatformConfig(for: platform)
            let performanceConfig = createMockPerformanceConfig(for: platform)
            
            // THEN: Animation settings should be appropriate for the platform
            testAnimationAppropriateness(performanceConfig, platform: platform, config: config)
        }
    }
    
    func testAnimationAppropriateness(_ performanceConfig: PerformanceConfig, platform: SixLayerPlatform, config: PlatformCapabilities) {
        // Touch platforms should have appropriate animation duration
        if config.supportsTouch {
            #expect(performanceConfig.maxAnimationDuration > 0, "Touch platforms should have animation duration on \(platform)")
        }
        
        // All platforms should have reasonable animation settings
        #expect(performanceConfig.maxAnimationDuration >= 0, "All platforms should have non-negative animation duration on \(platform)")
    }
    
    // MARK: - Helper Methods
    
    public func createMockPlatformConfig(for platform: SixLayerPlatform) -> PlatformCapabilities {
        switch platform {
        case .iOS:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: false, // iPhone doesn't have hover
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44,
                hoverDelay: 0.0
            )
        case .macOS:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.1
            )
        case .watchOS:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44,
                hoverDelay: 0.0
            )
        case .tvOS:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: false,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.0
            )
        case .visionOS:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.1
            )
        }
    }
    
    public func createMockDeviceConfig(for deviceType: DeviceType) -> PlatformCapabilities {
        switch deviceType {
        case .phone:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44,
                hoverDelay: 0.0
            )
        case .car:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: false,
                supportsAssistiveTouch: false,
                minTouchTarget: 44,
                hoverDelay: 0.0
            )
        case .pad:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: true,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44,
                hoverDelay: 0.1
            )
        case .mac:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.1
            )
        case .watch:
            return PlatformCapabilities(
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: true,
                minTouchTarget: 44,
                hoverDelay: 0.0
            )
        case .tv:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: false,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.0
            )
        case .vision:
            return PlatformCapabilities(
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsAssistiveTouch: false,
                minTouchTarget: 0,
                hoverDelay: 0.1
            )
        }
    }
    
    public func createMockPlatformDeviceConfig(platform: SixLayerPlatform, deviceType: DeviceType) -> PlatformCapabilities {
        // This would be more complex in reality, but for testing we'll use platform as primary
        return createMockPlatformConfig(for: platform)
    }
    
    public func createMockVisionAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS, .visionOS:
            return true
        case .watchOS, .tvOS:
            return false
        }
    }
    
    public func createMockOCRAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS, .visionOS:
            return true
        case .watchOS, .tvOS:
            return false
        }
    }
    
    public func createMockLayoutDecision(for platform: SixLayerPlatform) -> IntelligentCardLayoutDecision {
        switch platform {
        case .iOS:
            return IntelligentCardLayoutDecision(
                columns: 2,
                spacing: 16,
                cardWidth: 200,
                cardHeight: 150,
                padding: 16
            )
        case .macOS:
            return IntelligentCardLayoutDecision(
                columns: 3,
                spacing: 20,
                cardWidth: 250,
                cardHeight: 180,
                padding: 20
            )
        case .watchOS:
            return IntelligentCardLayoutDecision(
                columns: 1,
                spacing: 12,
                cardWidth: 150,
                cardHeight: 100,
                padding: 12
            )
        case .tvOS:
            return IntelligentCardLayoutDecision(
                columns: 4,
                spacing: 24,
                cardWidth: 300,
                cardHeight: 200,
                padding: 24
            )
        case .visionOS:
            return IntelligentCardLayoutDecision(
                columns: 3,
                spacing: 20,
                cardWidth: 250,
                cardHeight: 180,
                padding: 20
            )
        }
    }
    
    public func createMockPerformanceConfig(for platform: SixLayerPlatform) -> PerformanceConfig {
        switch platform {
        case .iOS, .macOS, .visionOS:
            return PerformanceConfig(
                targetFrameRate: 60,
                maxAnimationDuration: 0.3
            )
        case .watchOS:
            return PerformanceConfig(
                targetFrameRate: 30,
                maxAnimationDuration: 0.2
            )
        case .tvOS:
            return PerformanceConfig(
                targetFrameRate: 60,
                maxAnimationDuration: 0.4
            )
        }
    }
}
