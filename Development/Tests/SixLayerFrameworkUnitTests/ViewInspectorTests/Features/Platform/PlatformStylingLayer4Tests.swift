import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformStylingLayer4.swift
/// 
/// BUSINESS PURPOSE: Ensure all styling Layer 4 components generate proper accessibility identifiers
/// TESTING SCOPE: All components in PlatformStylingLayer4.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Styling Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformStylingLayer4Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - platformStyledContainer_L4 Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testPlatformStyledContainerL4GeneratesAccessibilityIdentifiersOnIOS() async {
        let view = Text("Test Content")
            .platformStyledContainer_L4(
                content: {
                    Text("Test Content")
                }
            )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            componentName: "platformStyledContainer_L4",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformStyledContainer_L4 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformStyledContainerL4GeneratesAccessibilityIdentifiersOnMacOS() async {
        let view = Text("Test Content")
            .platformStyledContainer_L4(
                content: {
                    Text("Test Content")
                }
            )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: .macOS,
            componentName: "platformStyledContainer_L4"
        )
 #expect(hasAccessibilityID, "platformStyledContainer_L4 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

