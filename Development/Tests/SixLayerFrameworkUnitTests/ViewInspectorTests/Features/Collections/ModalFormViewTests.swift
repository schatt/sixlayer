import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for ModalFormView component
/// 
/// BUSINESS PURPOSE: Ensure ModalFormView generates proper accessibility identifiers
/// TESTING SCOPE: ModalFormView component from PlatformSemanticLayer1.swift
/// METHODOLOGY: Test component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Modal Form View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class ModalFormViewTests: BaseTestClass {
    
    @Test @MainActor func testModalFormViewGeneratesAccessibilityIdentifiersOnIOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

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
        
            let view = ModalFormView(
                fields: testFields,
                formType: .generic,
                context: .modal,
                hints: PresentationHints(
                    dataType: .generic,
                    presentationPreference: .automatic,
                    complexity: .moderate,
                    context: .modal,
                    customPreferences: [:]
                )
            )
        
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "ModalFormView"
            )
            #expect(hasAccessibilityID, "ModalFormView should generate accessibility identifiers on iOS ")
        }
    }

    
    @Test @MainActor func testModalFormViewGeneratesAccessibilityIdentifiersOnMacOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

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
        
            let view = ModalFormView(
                fields: testFields,
                formType: .generic,
                context: .modal,
                hints: PresentationHints(
                    dataType: .generic,
                    presentationPreference: .automatic,
                    complexity: .moderate,
                    context: .modal,
                    customPreferences: [:]
                )
            )
        
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.macOS,
                componentName: "ModalFormView"
            )
            #expect(hasAccessibilityID, "ModalFormView should generate accessibility identifiers on macOS ")
        }
    }

}
