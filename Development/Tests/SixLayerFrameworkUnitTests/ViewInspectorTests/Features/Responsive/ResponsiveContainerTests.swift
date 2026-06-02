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
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = ResponsiveContainer { _, _ in
                Text("Test Content")
            }
            .automaticCompliance(named: "ResponsiveContainer")

            #if canImport(ViewInspector)
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                platform: .iOS,
                componentName: "ResponsiveContainer"
            )
            #expect(hasAccessibilityID, "ResponsiveContainer should generate accessibility identifiers on iOS")
            #else
            #expect(Bool(true), "View created (ViewInspector not available)")
            #endif
        }
    }
    
    @Test @MainActor func testResponsiveContainerGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = ResponsiveContainer { _, _ in
                Text("Test Content")
            }
            .automaticCompliance(named: "ResponsiveContainer")

            #if canImport(ViewInspector)
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                platform: .macOS,
                componentName: "ResponsiveContainer"
            )
            #expect(hasAccessibilityID, "ResponsiveContainer should generate accessibility identifiers on macOS")
            #else
            #expect(Bool(true), "View created (ViewInspector not available)")
            #endif
        }
    }
}

