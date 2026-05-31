import Testing

//
//  HIGComplianceHoverTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that automatic HIG compliance ensures proper hover states and
//  interactions on platforms that support hover (macOS, visionOS, iPad with Apple Pencil).
//
//  TESTING SCOPE:
//  - Hover state visual feedback
//  - Hover text readability (macOS Hover Text feature)
//  - Pointer interactions
//  - Platform-specific hover behavior
//
//  METHODOLOGY:
//  - TDD RED phase: Tests fail until hover support is implemented
//  - Test views with automatic compliance on hover-capable platforms
//  - Verify hover states provide appropriate feedback
//  - Test hover text readability
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Hover Support", DefaultRuntimeCapabilityIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceHoverTests: BaseTestClass {
    
    // MARK: - Hover State Tests
    
    @Test @MainActor func testButtonHasHoverState() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A button with automatic compliance
            let button = Button("Hover Button") { }
                .automaticCompliance()
            
            // WHEN: View is created on a hover-capable platform
            // THEN: Button should have appropriate hover state feedback
            // RED PHASE: This will fail until hover state support is implemented
            let passed = testComponentComplianceCrossPlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                componentName: "ButtonWithHover"
            )
            #expect(passed, "Button should have appropriate hover state feedback on hover-capable platforms")
        }
    }
    
    @Test @MainActor func testLinkHasHoverState() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: A link with automatic compliance
            let link = Link("Hover Link", destination: URL(string: "https://example.com")!)
                .automaticCompliance()
            
            // WHEN: View is created on a hover-capable platform
            // THEN: Link should have appropriate hover state feedback
            // RED PHASE: This will fail until hover state support is implemented
            let passed = testComponentComplianceCrossPlatform(
                link,
                expectedPattern: "SixLayer.*ui",
                componentName: "LinkWithHover"
            )
            #expect(passed, "Link should have appropriate hover state feedback on hover-capable platforms")
        }
    }
    
    // MARK: - Hover Text Tests (macOS)
    
    @Test @MainActor func testTextReadableWithHoverText() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text with automatic compliance
            let view = Text("Hover Text Test")
                .automaticCompliance()
            
            // WHEN: View is created on macOS with Hover Text enabled
            // THEN: Text should be readable when Hover Text is shown
            // RED PHASE: This will fail until hover text support is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "TextWithHoverText"
            )
            #expect(passed, "Text should be readable with Hover Text on macOS")
        }
    }
    
    // MARK: - Pointer Interaction Tests
    
    @Test @MainActor func testPointerInteractionsWorkCorrectly() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Interactive view with automatic compliance
            let view = Text("Pointer Interaction Test")
                .onHover { _ in }
                .automaticCompliance()
            
            // WHEN: View is created on a hover-capable platform
            // THEN: Pointer interactions should work correctly
            // RED PHASE: This will fail until pointer interaction support is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "ViewWithPointerInteractions"
            )
            #expect(passed, "Pointer interactions should work correctly on hover-capable platforms")
        }
    }
    
    // MARK: - Tri-state hover capability (#251)

    /// Button + `.automaticCompliance()` on the **current host** through hover tri-state.
    @Test @MainActor func testButtonHoverComplianceTriStatePhases() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let button = Button("Hover Tri-State Button") { }
                .automaticCompliance()

            @MainActor func assertHoverComplianceLaw(phase: String) {
                let platform = SixLayerPlatform.current
                let effectiveHover = RuntimeCapabilityDetection.supportsHover
                let passed = testComponentComplianceSinglePlatform(
                    button,
                    expectedPattern: "SixLayer.*ui",
                    platform: platform,
                    componentName: "ButtonHover-\(phase)-\(platform)"
                )

                switch platform {
                case .iOS:
                    #expect(passed, "\(phase) on iOS: compliant button (hover=\(effectiveHover))")
                case .macOS, .visionOS:
                    #expect(passed, "\(phase) on \(platform): compliant button on hover-capable host (hover=\(effectiveHover))")
                case .watchOS, .tvOS:
                    #expect(passed, "\(phase) on \(platform): compliant button without hover (hover=\(effectiveHover))")
                    #expect(!effectiveHover, "\(phase) on \(platform): host should not report hover")
                }
            }

            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            assertHoverComplianceLaw(phase: "current")

            RuntimeCapabilityDetection.setTestHover(false)
            assertHoverComplianceLaw(phase: "disabled")

            RuntimeCapabilityDetection.setTestHover(true)
            assertHoverComplianceLaw(phase: "enabled")
        }
    }

    // MARK: - Cross-Platform Tests
    
    @Test @MainActor func testHoverSupportOnHoverCapablePlatforms() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        runWithTaskLocalConfig {
            let platform = SixLayerPlatform.current
            guard platform == .macOS || platform == .visionOS else { return }

            let button = Button("Hover Test Button") { }
                .automaticCompliance()

            let supportsHover = RuntimeCapabilityDetection.supportsHover
            #expect(supportsHover, "\(platform) host should report hover support")

            let passed = testComponentComplianceSinglePlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                platform: platform,
                componentName: "ButtonWithHover-\(platform)"
            )
            #expect(passed, "Hover support should work on \(platform)")
        }
    }
}

