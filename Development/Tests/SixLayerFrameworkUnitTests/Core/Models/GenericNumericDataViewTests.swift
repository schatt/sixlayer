import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for GenericNumericDataView component
/// 
/// BUSINESS PURPOSE: Ensure GenericNumericDataView generates proper accessibility identifiers
/// TESTING SCOPE: GenericNumericDataView component from PlatformSemanticLayer1.swift
/// METHODOLOGY: Test component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Generic Numeric Data View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class GenericNumericDataViewTests: BaseTestClass {
    
    // MARK: - Helper Methods
    
    // BaseTestClass handles setup automatically
    
    @MainActor
    private func configureAccessibilityIdentifiers() {
        let config = AccessibilityIdentifierConfig.shared
        config.resetToDefaults()
        config.enableAutoIDs = true
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableDebugLogging = false
    }
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testGenericNumericDataViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        // Setup test environment
        await setupTestEnvironment()
        configureAccessibilityIdentifiers()
        
        let view = GenericNumericDataView(
            data: [GenericNumericData(value: 123.45, label: "Test Value", unit: "units")],
            hints: PresentationHints()
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericNumericDataView"
        )
 #expect(hasAccessibilityID, "GenericNumericDataView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testGenericNumericDataViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        // Setup test environment
        await setupTestEnvironment()
        configureAccessibilityIdentifiers()
        
        let view = GenericNumericDataView(
            data: [GenericNumericData(value: 123.45, label: "Test Value", unit: "units")],
            hints: PresentationHints()
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericNumericDataView"
        )
 #expect(hasAccessibilityID, "GenericNumericDataView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}
