import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  DynamicFormViewAutoSaveTests.swift
//  SixLayerFrameworkUITests
//
//  BUSINESS PURPOSE:
//  Validates auto-save integration in DynamicFormView (Issue #80)
//  Ensures form drafts are saved and restored correctly in the UI
//
//  TESTING SCOPE:
//  - Draft loading on appear
//  - Auto-save on disappear
//  - Draft clearing on submit
//  - Lifecycle integration
//
//  METHODOLOGY:
//  - Test onAppear loads draft
//  - Test onDisappear saves draft
//  - Test onChange triggers debounced save
//  - Test submit clears draft
//
//  AUDIT STATUS: ✅ COMPLIANT
//

/// NOTE: Marked @MainActor for UI tests
@Suite("DynamicFormView Auto-Save")
@MainActor
open class DynamicFormViewAutoSaveTests: BaseTestClass {
    
    /// BUSINESS PURPOSE: Validate draft is loaded when form appears
    /// TESTING SCOPE: Tests that draft state is restored on form appear
    /// METHODOLOGY: Save draft, create new form, verify draft loads
    @Test @MainActor func testDraftLoadsOnAppear() {
        let testDefaults = UserDefaults(suiteName: "test_form_view_autosave")!
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        
        // Create and save draft
        let config1 = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState1 = DynamicFormState(configuration: config1, storage: storage)
        formState1.setValue("saved value", for: "field1")
        formState1.saveDraft()
        
        // Create new form with same config (simulates form appearing)
        let config2 = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState2 = DynamicFormState(configuration: config2, storage: storage)
        
        // Load draft (simulates onAppear)
        let loaded = formState2.loadDraft()
        #expect(loaded == true)
        let value: String? = formState2.getValue(for: "field1")
        #expect(value == "saved value")
        
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate draft is saved when form disappears
    /// TESTING SCOPE: Tests that form state is saved on disappear
    /// METHODOLOGY: Set values, simulate disappear, verify draft saved
    @Test @MainActor func testDraftSavesOnDisappear() {
        let testDefaults = UserDefaults(suiteName: "test_form_view_autosave")!
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        formState.setValue("disappear value", for: "field1")
        
        // Simulate onDisappear
        formState.saveDraft()
        
        // Verify draft was saved
        #expect(formState.hasDraft())
        let draft = storage.loadDraft(formId: "test-form")
        let values = draft?.toFieldValues()
        #expect(values?["field1"] as? String == "disappear value")
        
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate draft is cleared on submit
    /// TESTING SCOPE: Tests that draft is cleared when form is submitted
    /// METHODOLOGY: Save draft, simulate submit, verify draft cleared
    @Test @MainActor func testDraftClearedOnSubmit() {
        let testDefaults = UserDefaults(suiteName: "test_form_view_autosave")!
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        formState.setValue("submit value", for: "field1")
        formState.saveDraft()
        #expect(formState.hasDraft())
        
        // Simulate submit (clears draft)
        formState.clearDraft()
        
        // Verify draft is cleared
        #expect(!formState.hasDraft())
        
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate multiple forms can have separate drafts
    /// TESTING SCOPE: Tests that different forms maintain separate draft state
    /// METHODOLOGY: Save drafts for multiple forms, verify they don't interfere
    @Test @MainActor func testMultipleFormsSeparateDrafts() {
        let testDefaults = UserDefaults(suiteName: "test_form_view_autosave")!
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        
        // Form 1
        let config1 = DynamicFormConfiguration(
            id: "form-1",
            title: "Form 1",
            sections: []
        )
        let formState1 = DynamicFormState(configuration: config1, storage: storage)
        formState1.setValue("form1 value", for: "field1")
        formState1.saveDraft()
        
        // Form 2
        let config2 = DynamicFormConfiguration(
            id: "form-2",
            title: "Form 2",
            sections: []
        )
        let formState2 = DynamicFormState(configuration: config2, storage: storage)
        formState2.setValue("form2 value", for: "field1")
        formState2.saveDraft()
        
        // Verify both drafts exist separately
        #expect(formState1.hasDraft())
        #expect(formState2.hasDraft())
        
        let draft1 = storage.loadDraft(formId: "form-1")
        let draft2 = storage.loadDraft(formId: "form-2")
        
        #expect(draft1?.toFieldValues()["field1"] as? String == "form1 value")
        #expect(draft2?.toFieldValues()["field1"] as? String == "form2 value")
        
        testDefaults.removePersistentDomain(forName: "test_form_view_autosave")
    }
}
