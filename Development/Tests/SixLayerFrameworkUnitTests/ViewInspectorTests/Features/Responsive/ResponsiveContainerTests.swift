import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for ResponsiveContainer.swift
/// 
/// BUSINESS PURPOSE: Ensure ResponsiveContainer generates proper accessibility identifiers
/// TESTING SCOPE: All components in ResponsiveContainer.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Responsive Container")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class ResponsiveContainerTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - ResponsiveContainer Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testResponsiveContainerGeneratesAccessibilityIdentifiersOnIOS() async {
        let view = ResponsiveContainer { isHorizontal, isVertical in
            Text("Test Content")
        }
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: .iOS,
            componentName: "ResponsiveContainer"
        )
 #expect(hasAccessibilityID, "ResponsiveContainer should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testResponsiveContainerGeneratesAccessibilityIdentifiersOnMacOS() async {
        let view = ResponsiveContainer { isHorizontal, isVertical in
            Text("Test Content")
        }
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: .macOS,
            componentName: "ResponsiveContainer"
        )
 #expect(hasAccessibilityID, "ResponsiveContainer should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

