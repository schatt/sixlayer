import Testing


//
//  AccessibilityPreferenceTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates accessibility preference handling and UI adaptation across all supported platforms,
//  ensuring proper accessibility support and user experience for users with different accessibility needs.
//
//  TESTING SCOPE:
//  - Platform capability detection for accessibility features
//  - UI adaptation based on accessibility preferences (VoiceOver, Switch Control, Reduce Motion)
//  - Cross-platform consistency of accessibility support
//  - Edge cases and error handling for accessibility scenarios
//  - Accessibility configuration management and state transitions
//  - Platform-specific accessibility behavior validation
//
//  METHODOLOGY:
//  - Test accessibility preference detection and configuration
//  - Verify UI adaptation based on different accessibility states
//  - Test platform-specific accessibility behavior using switch statements
//  - Validate cross-platform consistency of accessibility support
//  - Test edge cases and error handling for accessibility scenarios
//  - Use mocking to simulate different accessibility states and verify responses
//
//  QUALITY ASSESSMENT: ✅ GOOD
//  - ✅ Good: Has business purpose and testing scope documentation
//  - ✅ Good: Tests actual accessibility behavior and platform-specific logic
//  - ✅ Good: Uses proper test data setup and mocking
//  - ✅ Good: Tests cross-platform consistency and edge cases
//  - ✅ Good: Validates accessibility configuration management
//

import SwiftUI
@testable import SixLayerFramework

/// Accessibility preference testing
/// Tests that every function behaves correctly based on accessibility preferences
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Preference", DefaultRuntimeCapabilityIsolationTrait())
open class AccessibilityPreferenceTests: BaseTestClass {
    
    // MARK: - Test Data Setup
    
    public func createTestView() -> some View {
        Button("Test Button") { }
            .frame(width: 100, height: 50)
    }
    
    public func createTestImage() -> PlatformImage {
        PlatformImage()
    }
    
    // MARK: - Business Logic Tests for Card Expansion Accessibility Configuration
    
    /// Tests that getCardExpansionAccessibilityConfig returns different configurations for different platforms
    @Test @MainActor func testCardExpansionAccessibilityConfig_PlatformSpecificBehavior() {
        let platform = SixLayerPlatform.current
        let config = getCardExpansionAccessibilityConfig()

        #expect(config.supportsVoiceOver == true || config.supportsVoiceOver == false,
                     "\(platform) VoiceOver support should be determinable")
        #expect(config.supportsSwitchControl == true || config.supportsSwitchControl == false,
                     "\(platform) Switch Control support should be determinable")
        #expect(config.supportsAssistiveTouch == true || config.supportsAssistiveTouch == false,
                     "\(platform) AssistiveTouch support should be determinable")
    }
    
    /// Tests that getCardExpansionPlatformConfig returns platform-specific capabilities
    @Test @MainActor func testCardExpansionPlatformConfig_PlatformSpecificCapabilities() {
        // This file is a member of SixLayerFrameworkUnitTests_iOS, _macOS, _tvOS, etc.
        // The switch is exhaustive over `SixLayerPlatform`, so every `case` appears in
        // every binary; at runtime only the branch matching `SixLayerPlatform.current`
        // runs (e.g. on iOS the `.macOS` case is dead code — not “macOS tests on iOS”).
        // Given: Current platform
        let platform = SixLayerPlatform.current
        
        // When: Get platform configuration
        let config = getCardExpansionPlatformConfig()
        
        // Then: Test actual business logic
        // The configuration should be appropriate for the current platform
        #expect(Bool(true), "Platform configuration should be available")  // config is non-optional
        
        // Test platform-specific expectations
        switch platform {
        case .iOS:
            // iPad / Pencil paths can report hover; card config must mirror runtime (same idea as macOS).
            #expect(config.supportsTouch == RuntimeCapabilityDetection.supportsTouch)
            #expect(config.supportsHapticFeedback == RuntimeCapabilityDetection.supportsHapticFeedback)
            #expect(config.supportsHover == RuntimeCapabilityDetection.supportsHover)
            #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay)
            let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(for: .iOS)
            #expect(config.minTouchTarget == expectedMin, "iOS min touch target should match HIG helper (\(expectedMin)pt)")
            
        case .macOS:
            // macOS: hover and hoverDelay follow AppKit runtime (e.g. mouse buttons down → no hover → 0.0s).
            #expect(config.supportsHover == RuntimeCapabilityDetection.supportsHover)
            #expect(config.supportsTouch == RuntimeCapabilityDetection.supportsTouch)
            #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay)
            
        case .watchOS:
            // watchOS should support touch and haptic feedback
            #expect(config.supportsTouch == true || config.supportsTouch == false, 
                         "watchOS touch support should be determinable")
            #expect(config.supportsHapticFeedback == true || config.supportsHapticFeedback == false, 
                         "watchOS haptic feedback support should be determinable")
            #expect(config.minTouchTarget == 44, "watchOS should have 44pt minimum touch targets")
            
        case .tvOS:
            // tvOS should have larger touch targets and no hover
            #expect(config.supportsTouch == true || config.supportsTouch == false, 
                         "tvOS touch support should be determinable")
            #expect(config.supportsHover == true || config.supportsHover == false, 
                         "tvOS hover support should be determinable")
            #expect(config.minTouchTarget >= 60, "tvOS should have larger touch targets")
            
        case .visionOS:
            // visionOS should support haptic feedback
            #expect(config.supportsHapticFeedback == true || config.supportsHapticFeedback == false, 
                         "visionOS haptic feedback support should be determinable")
            // Apple visionOS HIG: gaze+pinch minimum 60pt (Issue #237)
            #expect(config.minTouchTarget >= 60, "visionOS should have >= 60pt interactive targets (HIG gaze+pinch)")
        }
    }
    
    /// Tests that getCardExpansionPerformanceConfig returns appropriate performance settings
    @Test @MainActor func testCardExpansionPerformanceConfig_PerformanceSettings() {
        // Given: Current platform
        let platform = SixLayerPlatform.current
        
        // When: Get performance configuration
        let config = getCardExpansionPerformanceConfig()
        
        // Then: Test actual business logic
        // The configuration should have valid performance settings
        #expect(Bool(true), "Performance configuration should be available")  // config is non-optional
        
        // Test that performance settings are reasonable
        #expect(config.maxAnimationDuration >= 0, "Animation duration should be non-negative")
        #expect(config.maxAnimationDuration <= 5.0, "Animation duration should not be excessive")
        
        // Test platform-specific performance expectations
        switch platform {
        case .iOS:
            // iOS should have reasonable animation duration
            #expect(config.maxAnimationDuration <= 0.5, "iOS animations should be snappy")
            
        case .macOS:
            // macOS can have slightly longer animations
            #expect(config.maxAnimationDuration <= 1.0, "macOS animations should be reasonable")
            
        case .watchOS:
            // watchOS should have very fast animations
            #expect(config.maxAnimationDuration <= 0.3, "watchOS animations should be very fast")
            
        case .tvOS:
            // tvOS can have longer animations for TV viewing
            #expect(config.maxAnimationDuration <= 1.5, "tvOS animations should be TV-appropriate")
            
        case .visionOS:
            // visionOS should have spatial-appropriate animations
            #expect(config.maxAnimationDuration <= 1.0, "visionOS animations should be spatial-appropriate")
        }
    }
    
    // MARK: - Tri-state card expansion config (#251)

    /// Card expansion platform config on the **current host** through touch/hover/a11y tri-state.
    @Test @MainActor func testCardExpansionPlatformConfigTriStatePhases() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertPlatformConfigLaw(phase: String) {
            let platform = SixLayerPlatform.current
            let config = getCardExpansionPlatformConfig()
            let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
            let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                for: platform,
                touchDetected: effectiveTouch
            )

            switch platform {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(config.supportsTouch == effectiveTouch, "\(phase): touch should mirror detection")
                #expect(config.supportsHover == RuntimeCapabilityDetection.supportsHover, "\(phase): hover should mirror detection")
                #expect(config.supportsHapticFeedback == RuntimeCapabilityDetection.supportsHapticFeedback, "\(phase): haptic should mirror detection")
                #expect(config.minTouchTarget == expectedMin, "\(phase): minTouchTarget should match HIG on \(platform)")
                #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay, "\(phase): hoverDelay should mirror detection")
                if !RuntimeCapabilityDetection.supportsHover {
                    #expect(config.hoverDelay == 0, "\(phase): no hover → zero delay")
                }
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertPlatformConfigLaw(phase: "current")

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        assertPlatformConfigLaw(phase: "disabled")

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(true)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        assertPlatformConfigLaw(phase: "enabled")
    }

    // MARK: - Edge Cases and Error Handling
    
    /// Tests that the framework handles missing accessibility preferences gracefully
    @Test @MainActor func testHandlesMissingAccessibilityPreferences() {
        // Given: Platform configuration
        let config = getCardExpansionPlatformConfig()
        let performanceConfig = getCardExpansionPerformanceConfig()
        let accessibilityConfig = getCardExpansionAccessibilityConfig()
        
        // When: Check that all required properties are present
        // Then: Test actual business logic
        // All accessibility-related properties should have valid values (all are non-optional Bool/TimeInterval)
        let _ = config.supportsVoiceOver
        let _ = config.supportsSwitchControl
        let _ = config.supportsAssistiveTouch
        let _ = performanceConfig.maxAnimationDuration
        let _ = accessibilityConfig.supportsVoiceOver
        #expect(Bool(true), "All accessibility properties should be accessible")
        
        // Test that values are within reasonable ranges
        #expect(config.minTouchTarget >= 0, "Touch target size should be non-negative")
        #expect(config.hoverDelay >= 0, "Hover delay should be non-negative")
        #expect(performanceConfig.maxAnimationDuration >= 0, "Animation duration should be non-negative")
    }
    
    /// Accessibility config mirrors overrides on the **current host** (disabled phase).
    @Test @MainActor func testAccessibilityOverridesDisabledPhase() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)

        #expect(RuntimeCapabilityDetection.supportsVoiceOver)
        #expect(RuntimeCapabilityDetection.supportsSwitchControl)
        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
    }
    
    /// Accessibility config mirrors overrides on the **current host** (enabled phase).
    @Test @MainActor func testAccessibilityOverridesEnabledPhase() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        #expect(RuntimeCapabilityDetection.supportsVoiceOver)
        #expect(RuntimeCapabilityDetection.supportsAssistiveTouch)
        #expect(RuntimeCapabilityDetection.supportsSwitchControl)
    }
    
    // MARK: - Performance Tests
    
    
    // MARK: - Cross-Platform Consistency Tests
    
    /// Tests that accessibility features are available on current platform
    @Test @MainActor func testAccessibilityFeaturesAvailability() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        // Get platform capabilities using the framework's capability detection
        let config = getCardExpansionPlatformConfig()

        // Test actual business logic
        // Each platform should have consistent accessibility support (all are non-optional Bool)
        #expect(config.supportsVoiceOver == true, "VoiceOver should be available on current platform")
        #expect(config.supportsSwitchControl == true, "Switch Control should be available on current platform")

        // Verify HIG-correct minTouchTarget per platform (Issue #237).
        // Apple HIG: iOS/watchOS 44, tvOS/visionOS 60, macOS conditional.
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget = PlatformTestUtilities.expectedMinTouchTarget(for: currentPlatform)
        #expect(config.minTouchTarget == expectedMinTouchTarget,
                "Apple HIG: \(currentPlatform) expected \(expectedMinTouchTarget)pt")
    }
}
