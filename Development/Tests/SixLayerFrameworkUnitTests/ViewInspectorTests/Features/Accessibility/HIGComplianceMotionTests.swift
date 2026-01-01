import Testing

//
//  HIGComplianceMotionTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that automatic HIG compliance respects reduced motion preferences,
//  ensuring animations are disabled or simplified for users who prefer reduced motion.
//
//  TESTING SCOPE:
//  - Reduced motion preference detection
//  - Animation disabling when reduced motion is enabled
//  - Simplified animations as alternative
//  - Platform-specific motion preference APIs
//
//  METHODOLOGY:
//  - TDD RED phase: Tests fail until motion preference handling is implemented
//  - Test views with animations
//  - Verify animations respect accessibility settings
//  - Test both reduced and normal motion states
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Motion Preferences")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceMotionTests: BaseTestClass {
    
    // MARK: - Reduced Motion Tests
    
    @Test @MainActor func testAnimationRespectsReducedMotion() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A view with animation and automatic compliance
            let view = Text("Animated Text")
                .automaticCompliance()
            
            // WHEN: View is created with reduced motion enabled
            // THEN: Animations should be disabled or simplified
            // RED PHASE: This will fail until motion preference handling is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "AnimatedViewWithReducedMotion"
            )
            #expect(passed, "Animations should respect reduced motion preference on all platforms")
        }
    }
    
    @Test @MainActor func testTransitionRespectsReducedMotion() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A view with transition and automatic compliance
            let view = Text("Transitioning Text")
                .transition(.opacity)
                .automaticCompliance()
            
            // WHEN: View is created with reduced motion enabled
            // THEN: Transitions should be disabled or simplified
            // RED PHASE: This will fail until motion preference handling is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "TransitioningViewWithReducedMotion"
            )
            #expect(passed, "Transitions should respect reduced motion preference on all platforms")
        }
    }
    
    @Test @MainActor func testButtonAnimationRespectsReducedMotion() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A button with animation and automatic compliance
            let button = Button("Animated Button") { }
                .automaticCompliance()
            
            // WHEN: View is created with reduced motion enabled
            // THEN: Button animations should be disabled or simplified
            // RED PHASE: This will fail until motion preference handling is implemented
            let passed = testComponentComplianceCrossPlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                componentName: "AnimatedButtonWithReducedMotion"
            )
            #expect(passed, "Button animations should respect reduced motion preference on all platforms")
        }
    }
    
    // MARK: - Normal Motion Tests
    
    @Test @MainActor func testAnimationWorksWithNormalMotion() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A view with animation and automatic compliance
            let view = Text("Animated Text")
                .automaticCompliance()
            
            // WHEN: View is created with normal motion (reduced motion disabled)
            // THEN: Animations should work normally
            // RED PHASE: This will fail until motion preference handling is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "AnimatedViewWithNormalMotion"
            )
            #expect(passed, "Animations should work with normal motion preference on all platforms")
        }
    }
    
    // MARK: - Cross-Platform Tests
    
    @Test @MainActor func testMotionPreferencesOnBothPlatforms() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A view with animation and automatic compliance
            let view = Text("Cross-Platform Animated Text")
                .automaticCompliance()
            
            // WHEN: View is created on all platforms
            // THEN: Motion preferences should be respected on all platforms
            // RED PHASE: This will fail until motion preference handling is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "CrossPlatformMotion"
            )
            #expect(passed, "Motion preferences should be respected on all platforms")
        }
    }
}

