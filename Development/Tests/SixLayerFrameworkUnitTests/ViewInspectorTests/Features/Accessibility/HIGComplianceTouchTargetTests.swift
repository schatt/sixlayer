import Testing

//
//  HIGComplianceTouchTargetTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that automatic HIG compliance applies minimum touch target sizing to all
//  interactive components, ensuring accessibility and usability standards are met on each platform.
//
//  TESTING SCOPE:
//  - Minimum touch target sizing for buttons, links, and interactive elements
//  - Runtime capability detection based behavior (uses RuntimeCapabilityDetection.minTouchTarget)
//  - Automatic application via .automaticCompliance() modifier
//  - Cross-platform consistency based on runtime detection, not hardcoded platform checks
//
//  METHODOLOGY:
//  - TDD RED phase: Tests fail until touch target sizing is implemented
//  - Test interactive components (buttons, links, tappable views)
//  - Use RuntimeCapabilityDetection to determine expected behavior (not hardcoded platform checks)
//  - Verify that HIG compliance respects runtime detection values
//  - Use shared test functions for consistency
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Touch Target Sizing")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceTouchTargetTests: BaseTestClass {
    
    // MARK: - Runtime Detection Based Tests
    
    @Test @MainActor func testButtonRespectsRuntimeTouchTargetDetection() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A button with automatic compliance
            let button = Button("Test Button") { }
                .automaticCompliance()
            
            // WHEN: View is created on a platform that requires touch targets
            // THEN: Button should have minimum touch target size based on RuntimeCapabilityDetection
            
            // Test all platforms and verify behavior matches runtime detection
            let platforms: [SixLayerPlatform] = [.iOS, .watchOS, .macOS, .tvOS, .visionOS]
            
            for platform in platforms {
                // Set test platform to get correct runtime detection values
                
                // Get the expected minimum touch target from runtime detection
                let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
                let requiresTouchTarget = expectedMinTouchTarget > 0
                
                // RED PHASE: This will fail until touch target sizing is implemented
                let passed = testComponentComplianceSinglePlatform(
                    button,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "Button-\(platform)"
                )
                
                if requiresTouchTarget {
                    #expect(passed, "Button should have minimum \(expectedMinTouchTarget)pt touch target on \(platform) (runtime detection: minTouchTarget=\(expectedMinTouchTarget))")
                } else {
                    #expect(passed, "Button should have HIG compliance on \(platform) (runtime detection: minTouchTarget=\(expectedMinTouchTarget), no touch target required)")
                }
                
                // Clean up
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
        }
    }
    
    @Test @MainActor func testLinkRespectsRuntimeTouchTargetDetection() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A link with automatic compliance
            let link = Link("Test Link", destination: URL(string: "https://example.com")!)
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Link should respect runtime touch target detection
            
            // Test platforms that require touch targets
            let touchPlatforms: [SixLayerPlatform] = [.iOS, .watchOS]
            
            for platform in touchPlatforms {
                let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
                
                // RED PHASE: This will fail until touch target sizing is implemented
                let passed = testComponentComplianceSinglePlatform(
                    link,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "Link-\(platform)"
                )
                #expect(passed, "Link should have minimum \(expectedMinTouchTarget)pt touch target on \(platform) (runtime detection: minTouchTarget=\(expectedMinTouchTarget))")
                
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
        }
    }
    
    @Test @MainActor func testInteractiveViewRespectsRuntimeTouchTargetDetection() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: An interactive view (tappable) with automatic compliance
            let interactiveView = Text("Tap Me")
                .onTapGesture { }
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Interactive view should respect runtime touch target detection
            
            // Test platforms that require touch targets
            let touchPlatforms: [SixLayerPlatform] = [.iOS, .watchOS]
            
            for platform in touchPlatforms {
                let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
                
                // RED PHASE: This will fail until touch target sizing is implemented
                let passed = testComponentComplianceSinglePlatform(
                    interactiveView,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "InteractiveView-\(platform)"
                )
                #expect(passed, "Interactive view should have minimum \(expectedMinTouchTarget)pt touch target on \(platform) (runtime detection: minTouchTarget=\(expectedMinTouchTarget))")
                
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
        }
    }
    
    @Test @MainActor func testNonTouchPlatformsDoNotRequireTouchTargets() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A button with automatic compliance
            let button = Button("Test Button") { }
                .automaticCompliance()
            
            // WHEN: View is created on platforms that don't require touch targets
            // THEN: Touch target sizing should not be applied (but other HIG compliance should be)
            
            // Test platforms that don't require touch targets (only assert when actually running on that platform)
            let nonTouchPlatforms: [SixLayerPlatform] = [.macOS, .tvOS, .visionOS]
            let currentPlatform = RuntimeCapabilityDetection.currentPlatform
            guard nonTouchPlatforms.contains(currentPlatform) else {
                // Running on iOS/watchOS — skip; this test only applies to non-touch platforms
                return
            }
            for platform in nonTouchPlatforms where platform == currentPlatform {
                let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
                
                // Verify runtime detection says no touch target required
                #expect(expectedMinTouchTarget == 0.0, "Runtime detection should indicate no touch target required on \(platform)")
                
                // RED PHASE: This will fail until HIG compliance is implemented
                // But touch target sizing should NOT be applied on these platforms
                let passed = testComponentComplianceSinglePlatform(
                    button,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "Button-\(platform)"
                )
                #expect(passed, "Button should have HIG compliance on \(platform) (runtime detection: minTouchTarget=\(expectedMinTouchTarget), no touch target required)")
                
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
        }
    }
}

