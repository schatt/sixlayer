import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for CrossPlatformNavigation.swift
/// 
/// BUSINESS PURPOSE: Ensure CrossPlatformNavigation generates proper accessibility identifiers
/// TESTING SCOPE: All components in CrossPlatformNavigation.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Cross Platform Navigation")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class CrossPlatformNavigationTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - CrossPlatformNavigation Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testCrossPlatformNavigationGeneratesAccessibilityIdentifiersOnIOS() async {
        let view = Text("Test Navigation")
            .platformNavigation {
                Text("Content")
            }
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformNavigation"
        )
 #expect(hasAccessibilityID, "platformNavigation should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform - this is expected, not a failure
        #endif
    }
    
    @Test @MainActor func testCrossPlatformNavigationGeneratesAccessibilityIdentifiersOnMacOS() async {
        let view = Text("Test Navigation")
            .platformNavigation {
                Text("Content")
            }
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: .macOS,
            componentName: "platformNavigation"
        )
 #expect(hasAccessibilityID, "platformNavigation should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform - this is expected, not a failure
        #endif
    }
}
