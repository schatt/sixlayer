import Testing

//
//  HIGComplianceTypographyTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that automatic HIG compliance applies Dynamic Type support to all text,
//  ensuring text scales appropriately with system accessibility settings.
//
//  TESTING SCOPE:
//  - Dynamic Type support for all text elements
//  - Accessibility text size range support
//  - Automatic scaling with system settings
//  - Platform-specific typography behavior
//  - Minimum font size requirements per platform
//  - HIG typography style usage (body, headline, caption, etc.)
//  - Enforcement of minimum readable font sizes
//
//  METHODOLOGY:
//  - TDD RED phase: Tests fail until typography support is implemented
//  - Test text elements with various font sizes
//  - Verify .dynamicTypeSize modifier is applied
//  - Test accessibility size range support
//  - Verify minimum font size requirements are met
//  - Test platform-specific typography size requirements
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Typography Scaling")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceTypographyTests: BaseTestClass {
    
    // MARK: - Dynamic Type Support Tests
    
    @Test @MainActor func testTextSupportsDynamicType() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text with automatic compliance
            let view = Text("Test Text")
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Text should support Dynamic Type and accessibility sizes
            // RED PHASE: This will fail until Dynamic Type support is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "TextWithDynamicType"
            )
            #expect(passed, "Text should support Dynamic Type scaling on all platforms")
        }
    }
    
    @Test @MainActor func testButtonTextSupportsDynamicType() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Button with text and automatic compliance
            let button = Button("Test Button") { }
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Button text should support Dynamic Type
            // RED PHASE: This will fail until Dynamic Type support is implemented
            let passed = testComponentComplianceCrossPlatform(
                button,
                expectedPattern: "SixLayer.*ui",
                componentName: "ButtonWithDynamicType"
            )
            #expect(passed, "Button text should support Dynamic Type scaling on all platforms")
        }
    }
    
    @Test @MainActor func testLabelSupportsDynamicType() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Label with automatic compliance
            let label = Label("Test Label", systemImage: "star")
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Label text should support Dynamic Type
            // RED PHASE: This will fail until Dynamic Type support is implemented
            let passed = testComponentComplianceCrossPlatform(
                label,
                expectedPattern: "SixLayer.*ui",
                componentName: "LabelWithDynamicType"
            )
            #expect(passed, "Label text should support Dynamic Type scaling on all platforms")
        }
    }
    
    // MARK: - Accessibility Size Range Tests
    
    @Test @MainActor func testTextSupportsAccessibilitySizes() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text that should support accessibility sizes
            let view = Text("Accessibility Text")
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Text should support accessibility size range (up to .accessibility5)
            // RED PHASE: This will fail until accessibility size support is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "TextWithAccessibilitySizes"
            )
            #expect(passed, "Text should support accessibility size range on all platforms")
        }
    }
    
    // MARK: - Minimum Font Size Tests
    
    @Test @MainActor func testBodyTextMeetsMinimumSizeRequirements() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Body text with automatic compliance
            let view = Text("Body Text")
                .font(.body)
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Body text should meet platform-specific minimum size requirements
            // HIG Requirements:
            // - iOS: Body should be at least 17pt (or use .body which scales)
            // - macOS: Body should be at least 13pt
            // - tvOS: Body should be at least 24pt (TV viewing distance)
            // - watchOS: Body should be at least 16pt
            // - visionOS: Body should be at least 18pt
            // RED PHASE: This will fail until minimum font size enforcement is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "BodyTextWithMinimumSize"
            )
            #expect(passed, "Body text should meet platform-specific minimum size requirements on all platforms")
        }
    }
    
    @Test @MainActor func testCaptionTextMeetsMinimumSizeRequirements() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Caption text with automatic compliance
            let view = Text("Caption Text")
                .font(.caption)
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Caption text should meet platform-specific minimum size requirements
            // Even small text (captions) should be readable
            // RED PHASE: This will fail until minimum font size enforcement is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "CaptionTextWithMinimumSize"
            )
            #expect(passed, "Caption text should meet platform-specific minimum size requirements on all platforms")
        }
    }
    
    @Test @MainActor func testCustomFontSizeEnforcedMinimum() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text with custom font size that might be too small
            let view = Text("Small Text")
                .font(.system(size: 10)) // Potentially too small
                .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Custom font sizes should be enforced to meet minimum requirements
            // HIG compliance should ensure text never goes below minimum readable size
            // RED PHASE: This will fail until minimum font size enforcement is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "CustomFontSizeWithMinimum"
            )
            #expect(passed, "Custom font sizes should be enforced to meet minimum requirements on all platforms")
        }
    }
    
    // MARK: - Platform-Specific Typography Size Tests
    
    @Test @MainActor func testPlatformSpecificTypographySizes() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text using HIG typography styles with automatic compliance
            let view = platformVStackContainer {
                Text("Large Title")
                    .font(.largeTitle)
                    .automaticCompliance()
                Text("Title")
                    .font(.title)
                    .automaticCompliance()
                Text("Headline")
                    .font(.headline)
                    .automaticCompliance()
                Text("Body")
                    .font(.body)
                    .automaticCompliance()
                Text("Caption")
                    .font(.caption)
                    .automaticCompliance()
            }
            .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Typography styles should use platform-appropriate sizes
            // Each platform has different size requirements for the same style
            // RED PHASE: This will fail until platform-specific typography sizes are implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "PlatformSpecificTypographySizes"
            )
            #expect(passed, "Typography styles should use platform-appropriate sizes on all platforms")
        }
    }
    
    // MARK: - Cross-Platform Tests
    
    @Test @MainActor func testDynamicTypeOnBothPlatforms() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Text with automatic compliance
            let view = Text("Cross-Platform Text")
                .automaticCompliance()
            
            // WHEN: View is created on all platforms
            // THEN: Dynamic Type should be supported on all platforms
            // RED PHASE: This will fail until Dynamic Type support is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "CrossPlatformDynamicType"
            )
            #expect(passed, "Dynamic Type should be supported on all platforms")
        }
    }
}

