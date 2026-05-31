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

@Suite("HIG Compliance - Touch Target Sizing", DefaultRuntimeCapabilityIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceTouchTargetTests: BaseTestClass {
    
    // MARK: - Runtime Detection Based Tests
    
    // MARK: - Tri-state touch capability (#251)

    /// Button + `.automaticCompliance()` on the **current host** through touch tri-state.
    @Test @MainActor func testButtonTouchTargetComplianceTriStatePhases() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let button = Button("Touch Tri-State Button") { }
                .automaticCompliance()

            @MainActor func assertTouchTargetComplianceLaw(phase: String) {
                let platform = SixLayerPlatform.current
                let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
                let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                    for: platform,
                    touchDetected: effectiveTouch
                )
                let runtimeMin = RuntimeCapabilityDetection.minTouchTarget

                #expect(
                    runtimeMin == expectedMin,
                    "\(phase) on \(platform): minTouchTarget should match HIG floor (touch=\(effectiveTouch), expected=\(expectedMin))"
                )

                let passed = testComponentComplianceSinglePlatform(
                    button,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "ButtonTouch-\(phase)-\(platform)"
                )

                switch platform {
                case .iOS, .watchOS:
                    #expect(passed, "\(phase) on \(platform): compliant button with touch-first HIG floor")
                    #expect(expectedMin >= 44.0, "\(phase) on \(platform): touch-first platforms use 44pt floor")
                case .macOS:
                    #expect(passed, "\(phase) on \(platform): compliant button (touch=\(effectiveTouch))")
                case .tvOS, .visionOS:
                    #expect(passed, "\(phase) on \(platform): compliant button with focus/gaze HIG floor")
                    #expect(expectedMin == 60.0, "\(phase) on \(platform): tvOS/visionOS use 60pt floor")
                }
            }

            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            assertTouchTargetComplianceLaw(phase: "current")

            RuntimeCapabilityDetection.setTestTouchSupport(false)
            assertTouchTargetComplianceLaw(phase: "disabled")

            RuntimeCapabilityDetection.setTestTouchSupport(true)
            assertTouchTargetComplianceLaw(phase: "enabled")
        }
    }

    @Test @MainActor func testButtonRespectsRuntimeTouchTargetDetection() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let platform = SixLayerPlatform.current
            let button = Button("Test Button") { }
                .automaticCompliance()

            let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
            let requiresTouchTarget = expectedMinTouchTarget > 0

            let passed = testComponentComplianceSinglePlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                platform: platform,
                componentName: "Button-\(platform)"
            )

            if requiresTouchTarget {
                #expect(passed, "Button should have minimum \(expectedMinTouchTarget)pt touch target on \(platform)")
            } else {
                #expect(passed, "Button should have HIG compliance on \(platform) (minTouchTarget=\(expectedMinTouchTarget))")
            }
        }
    }
    
    @Test @MainActor func testLinkRespectsRuntimeTouchTargetDetection() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let platform = SixLayerPlatform.current
            guard platform == .iOS || platform == .watchOS else { return }

            let link = Link("Test Link", destination: URL(string: "https://example.com")!)
                .automaticCompliance()
            let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget

            let passed = testComponentComplianceSinglePlatform(
                link,
                expectedPattern: "SixLayer.*ui",
                platform: platform,
                componentName: "Link-\(platform)"
            )
            #expect(passed, "Link should have minimum \(expectedMinTouchTarget)pt touch target on \(platform)")
        }
    }
    
    @Test @MainActor func testInteractiveViewRespectsRuntimeTouchTargetDetection() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let platform = SixLayerPlatform.current
            guard platform == .iOS || platform == .watchOS else { return }

            let interactiveView = Text("Tap Me")
                .onTapGesture { }
                .automaticCompliance()
            let expectedMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget

            let passed = testComponentComplianceSinglePlatform(
                interactiveView,
                expectedPattern: "SixLayer.*ui",
                platform: platform,
                componentName: "InteractiveView-\(platform)"
            )
            #expect(passed, "Interactive view should have minimum \(expectedMinTouchTarget)pt touch target on \(platform)")
        }
    }
    
    @Test @MainActor func testNonTouchFirstPlatformsReportHIGFloor() async {
        // Apple HIG per platform (Issue #237). Prior test asserted
        // `minTouchTarget == 0.0` on macOS/tvOS/visionOS under the premise
        // that these are "non-touch platforms that don't require touch
        // targets". That's incorrect for tvOS and visionOS:
        //
        //   macOS:    0pt when runtime touch not detected (pointer-driven)
        //   tvOS:     60pt (focus engine at 10-foot distance, HIG mandatory)
        //   visionOS: 60pt (gaze+pinch target, HIG mandatory)
        //
        // The correct invariant is: non-touch-first platforms report the
        // HIG floor appropriate to their primary input modality. macOS
        // alone drops to 0 when no touch is detected.
        initializeTestConfig()
        runWithTaskLocalConfig {
            let button = Button("Test Button") { }
                .automaticCompliance()

            let nonTouchFirstPlatforms: [SixLayerPlatform] = [.macOS, .tvOS, .visionOS]
            let currentPlatform = RuntimeCapabilityDetection.currentPlatform
            guard nonTouchFirstPlatforms.contains(currentPlatform) else {
                // Running on iOS/watchOS — skip; this test exercises non-touch-first platforms
                return
            }

            let runtimeMinTouchTarget = RuntimeCapabilityDetection.minTouchTarget
            let expectedMinTouchTarget = PlatformTestUtilities.expectedMinTouchTarget(
                for: currentPlatform
            )

            #expect(runtimeMinTouchTarget == expectedMinTouchTarget,
                    "Apple HIG: \(currentPlatform) expected \(expectedMinTouchTarget)pt (not 0pt — tvOS/visionOS have platform-intrinsic HIG floors)")

            // HIG compliance modifier should still apply correctly regardless
            // of the platform's specific minimum.
            let passed = testComponentComplianceSinglePlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                platform: currentPlatform,
                componentName: "Button-\(currentPlatform)"
            )
            #expect(passed,
                    "Button should have HIG compliance on \(currentPlatform) (runtime minTouchTarget=\(runtimeMinTouchTarget))")

            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
    }
}

