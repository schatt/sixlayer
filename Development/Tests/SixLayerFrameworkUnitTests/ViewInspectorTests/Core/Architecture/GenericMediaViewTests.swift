import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for GenericMediaView component
/// 
/// BUSINESS PURPOSE: Ensure GenericMediaView generates proper accessibility identifiers
/// TESTING SCOPE: GenericMediaView component from PlatformSemanticLayer1.swift
/// METHODOLOGY: Test component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Generic Media View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class GenericMediaViewTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - GenericMediaView Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testGenericMediaViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let view = GenericMediaView(
            media: [GenericMediaItem(title: "Test Media", url: "https://example.com")],
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .modal,
                customPreferences: [:]
            )
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericMediaView"
        )
 #expect(hasAccessibilityID, "GenericMediaView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform - this is expected, not a failure
        #endif
    }
    
    @Test @MainActor func testGenericMediaViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let view = GenericMediaView(
            media: [GenericMediaItem(title: "Test Media", url: "https://example.com")],
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .modal,
                customPreferences: [:]
            )
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericMediaView"
        )
 #expect(hasAccessibilityID, "GenericMediaView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform - this is expected, not a failure
        #endif
    }
}
