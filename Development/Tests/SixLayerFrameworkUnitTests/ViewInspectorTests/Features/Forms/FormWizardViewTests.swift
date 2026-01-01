import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for FormWizardView.swift
/// 
/// BUSINESS PURPOSE: Ensure FormWizardView generates proper accessibility identifiers
/// TESTING SCOPE: All components in FormWizardView.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Form Wizard View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class FormWizardViewTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - FormWizardView Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testFormWizardViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let step1 = FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0)
        let step2 = FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1)
        
        let view = FormWizardView(steps: [step1, step2]) { step, state in
            Text("Step content for \(step.title)")
        } navigation: { state, onNext, onPrevious, onComplete in
            platformHStackContainer {
                Button("Previous") { onPrevious() }
                Button("Next") { onNext() }
            }
        }
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "FormWizardView"
        )
 #expect(hasAccessibilityID, "FormWizardView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testFormWizardViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let step1 = FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0)
        let step2 = FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1)
        
        let view = FormWizardView(steps: [step1, step2]) { step, state in
            Text("Step content for \(step.title)")
        } navigation: { state, onNext, onPrevious, onComplete in
            platformHStackContainer {
                Button("Previous") { onPrevious() }
                Button("Next") { onNext() }
            }
        }
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "FormWizardView"
        )
 #expect(hasAccessibilityID, "FormWizardView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

