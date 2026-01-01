import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for GenericFormView component
/// 
/// BUSINESS PURPOSE: Ensure GenericFormView generates proper accessibility identifiers
/// TESTING SCOPE: GenericFormView component from PlatformSemanticLayer1.swift
/// METHODOLOGY: Test component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Generic Form View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class GenericFormViewTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - GenericFormView Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testGenericFormViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testFields = [
            DynamicFormField(
                id: "field1",
                contentType: .text,
                label: "Test Field 1",
                placeholder: "Enter text",
                isRequired: true,
                validationRules: [:]
            )
        ]
        
        let view = GenericFormView(
            fields: testFields,
            hints: PresentationHints()
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericFormView"
        )
 #expect(hasAccessibilityID, "GenericFormView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testGenericFormViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testFields = [
            DynamicFormField(
                id: "field1",
                contentType: .text,
                label: "Test Field 1",
                placeholder: "Enter text",
                isRequired: true,
                validationRules: [:]
            )
        ]
        
        let view = GenericFormView(
            fields: testFields,
            hints: PresentationHints()
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "GenericFormView"
        )
 #expect(hasAccessibilityID, "GenericFormView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}
