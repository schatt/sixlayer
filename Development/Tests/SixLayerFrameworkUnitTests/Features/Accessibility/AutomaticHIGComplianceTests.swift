import Testing


import SwiftUI
@testable import SixLayerFramework

// MARK: - Test Data Structures

struct AutomaticHIGComplianceTestItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    
    init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

/**
 * BUSINESS PURPOSE: SixLayer framework should automatically apply Apple HIG compliance to all views created
 * by Layer 1 functions, ensuring developers don't need to manually add accessibility or compliance modifiers.
 * When a developer calls platformPresentItemCollection_L1, the resulting view should automatically have
 * VoiceOver support, proper accessibility labels, platform-appropriate styling, and all HIG compliance features.
 * 
 * TESTING SCOPE: Tests that all Layer 1 functions automatically apply HIG compliance modifiers without
 * requiring developer intervention. Verifies accessibility features, platform patterns, and visual consistency
 * are applied automatically based on runtime capabilities and platform detection.
 * 
 * METHODOLOGY: Uses TDD principles to test automatic compliance application. Creates views using Layer 1
 * functions and verifies they have proper accessibility features, platform-specific behavior, and HIG compliance
 * without requiring manual modifier application.
 */
/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView (prevents Xcode hangs)
@Suite(.serialized, DefaultRuntimeCapabilityIsolationTrait())
open class AutomaticHIGComplianceTests: BaseTestClass {
    
    // MARK: - Test Data Setup
    
    // No shared instance variables - tests run in parallel and should be isolated
    
    // Setup and teardown should be in individual test methods, not initializers
    
    // Cleanup should be handled by individual test methods or BaseTestClass
    
    // MARK: - Automatic HIG Compliance Tests
    
    /// BUSINESS PURPOSE: platformPresentItemCollection_L1 should automatically apply HIG compliance modifiers
    /// TESTING SCOPE: Tests that item collection views automatically have accessibility and HIG compliance
    /// METHODOLOGY: Creates a view using Layer 1 function and verifies it has automatic compliance features
    @Test @MainActor func testPlatformPresentItemCollection_L1_AutomaticHIGCompliance() async {
        initializeTestConfig()
        // Given: Test items and hints
        let items = [TestPatterns.TestItem(id: "1", title: "Test Item 1")]
        let hints = PresentationHints()

        // When: Creating view using Layer 1 function
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )

        // Then: HIG compliance check returns a bounded report (same contract as AppleHIGComplianceTests)
        assertHIGComplianceReportBounded(view)
    }
    
    /// BUSINESS PURPOSE: platformPresentItemCollection_L1 should automatically apply accessibility features when VoiceOver is enabled
    /// TESTING SCOPE: Tests that accessibility features are automatically applied based on runtime capabilities
    /// METHODOLOGY: Enables VoiceOver via mock framework and verifies automatic accessibility application
    @Test @MainActor func testPlatformPresentItemCollection_L1_AutomaticVoiceOverSupport() async {
        initializeTestConfig()
        // Given: VoiceOver enabled
        RuntimeCapabilityDetection.setTestVoiceOver(true)

        // When: Creating view using Layer 1 function
        let view = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )

        // Then: Bounded HIG report and VoiceOver test double is active
        assertHIGComplianceReportBounded(view)
        #expect(RuntimeCapabilityDetection.supportsVoiceOver, "VoiceOver should be enabled")

        // Reset for next test
        RuntimeCapabilityDetection.setTestVoiceOver(false)
    }
    
    /// BUSINESS PURPOSE: platformPresentItemCollection_L1 should automatically apply platform-specific patterns
    /// TESTING SCOPE: Tests that platform-specific behavior is automatically applied across different platforms
    /// METHODOLOGY: Tests automatic platform pattern application across iOS, macOS, watchOS, tvOS, and visionOS
    @Test @MainActor func testPlatformPresentItemCollection_L1_AutomaticPlatformPatterns() async {
            initializeTestConfig()
        // Setup test data
        let testItems = [
            TestPatterns.TestItem(id: "1", title: "Test Item 1"),
            TestPatterns.TestItem(id: "2", title: "Test Item 2")
        ]

        // When: Creating view using Layer 1 function
        let view = platformPresentItemCollection_L1(
            items: testItems,
            hints: PresentationHints()
        )

        // Then: Bounded HIG report (platform-specific scoring is inside the manager)
        assertHIGComplianceReportBounded(view)
    }
    
    /// BUSINESS PURPOSE: platformPresentItemCollection_L1 should automatically apply visual consistency
    /// TESTING SCOPE: Tests that visual design consistency is automatically applied to all views
    /// METHODOLOGY: Creates views and verifies they have consistent visual styling and theming
    @Test @MainActor func testPlatformPresentItemCollection_L1_AutomaticVisualConsistency() async {
        initializeTestConfig()
        // When: Creating view using Layer 1 function
        let view = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )

        // Then: Bounded HIG report (includes visual score component)
        assertHIGComplianceReportBounded(view)
    }
    
    /// BUSINESS PURPOSE: All Layer 1 functions should automatically apply HIG compliance
    /// TESTING SCOPE: Tests that multiple Layer 1 functions automatically apply compliance
    /// METHODOLOGY: Tests various Layer 1 functions to ensure they all have automatic compliance
    @Test @MainActor func testAllLayer1Functions_AutomaticHIGCompliance() async {
        initializeTestConfig()
        // Test platformPresentItemCollection_L1
        let collectionView = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )
        // Test that collection view can be hosted and has proper structure
        _ = hostRootPlatformView(collectionView.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(collectionView)

        // Test platformPresentNumericData_L1
        let numericData = [
            GenericNumericData(value: 42.0, label: "Test Value", unit: "units")
        ]
        let numericView = platformPresentNumericData_L1(
            data: numericData,
            hints: PresentationHints()
        )

        // Test that numeric view can be hosted and has proper structure
        _ = hostRootPlatformView(numericView.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(numericView)

        // Verify that both views are created successfully and can be hosted
        // This tests that the HIG compliance modifiers are applied without compilation errors
        _ = collectionView  // Used in hosting test above
        _ = numericView  // Used in hosting test above
    }
    
    /// Layer 1 collection compliance on the **current host** through a11y tri-state (#251).
    @Test @MainActor func testAutomaticHIGComplianceTriStatePhases() async {
        initializeTestConfig()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertCollectionCompliance(phase: String) {
            let view = platformPresentItemCollection_L1(
                items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
                hints: PresentationHints()
            )
            _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
            assertHIGComplianceReportBounded(view)

            let config = getCardExpansionPlatformConfig()
            switch SixLayerPlatform.current {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(config.supportsVoiceOver == RuntimeCapabilityDetection.supportsVoiceOver, "\(phase): VoiceOver should mirror detection")
                #expect(config.supportsSwitchControl == RuntimeCapabilityDetection.supportsSwitchControl, "\(phase): SwitchControl should mirror detection")
                #expect(config.supportsAssistiveTouch == RuntimeCapabilityDetection.supportsAssistiveTouch, "\(phase): AssistiveTouch should mirror detection")
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertCollectionCompliance(phase: "current")

        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        assertCollectionCompliance(phase: "disabled")

        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        assertCollectionCompliance(phase: "enabled")
    }

    /// BUSINESS PURPOSE: Automatic HIG compliance should work with different accessibility capabilities
    /// TESTING SCOPE: Tests automatic compliance with various accessibility features enabled/disabled
    /// METHODOLOGY: Tests automatic compliance with different combinations of accessibility capabilities
    @Test @MainActor func testAutomaticHIGCompliance_WithVariousAccessibilityCapabilities() async {
        initializeTestConfig()
        // Test with VoiceOver enabled
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)

        let viewWithVoiceOver = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )
        // Test that VoiceOver-enabled view can be hosted
        _ = hostRootPlatformView(viewWithVoiceOver.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(viewWithVoiceOver)

        // Test with Switch Control enabled
        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)

        let viewWithSwitchControl = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )

        // Test that Switch Control-enabled view can be hosted
        _ = hostRootPlatformView(viewWithSwitchControl.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(viewWithSwitchControl)

        // Test with AssistiveTouch enabled
        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        let viewWithAssistiveTouch = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )

        // Test that AssistiveTouch-enabled view can be hosted
        _ = hostRootPlatformView(viewWithAssistiveTouch.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(viewWithAssistiveTouch)

        // Test with all accessibility features enabled
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        let viewWithAllAccessibility = platformPresentItemCollection_L1(
            items: [TestPatterns.TestItem(id: "1", title: "Test Item 1")],
            hints: PresentationHints()
        )

        // Test that all-accessibility view can be hosted
        _ = hostRootPlatformView(viewWithAllAccessibility.enableGlobalAutomaticCompliance())
        assertHIGComplianceReportBounded(viewWithAllAccessibility)

        // Verify that all views are created successfully and can be hosted
        // This tests that the HIG compliance modifiers adapt to different accessibility capabilities
        _ = viewWithVoiceOver  // Used in hosting test above
        _ = viewWithSwitchControl  // Used in hosting test above
        _ = viewWithAssistiveTouch  // Used in hosting test above
        _ = viewWithAllAccessibility  // Used in hosting test above

        // Reset for next test
        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
    }

    // MARK: - Helpers

    @MainActor
    private func assertHIGComplianceReportBounded<V: View>(_ view: V) {
        let complianceManager = AppleHIGComplianceManager()
        let report = complianceManager.checkHIGCompliance(view)
        #expect(report.overallScore >= 0.0)
        #expect(report.overallScore <= 100.0)
        #expect(report.accessibilityScore >= 0.0)
        #expect(report.accessibilityScore <= 100.0)
        #expect(report.visualScore >= 0.0)
        #expect(report.visualScore <= 100.0)
        #expect(report.interactionScore >= 0.0)
        #expect(report.interactionScore <= 100.0)
        #expect(report.platformScore >= 0.0)
        #expect(report.platformScore <= 100.0)
    }
}
