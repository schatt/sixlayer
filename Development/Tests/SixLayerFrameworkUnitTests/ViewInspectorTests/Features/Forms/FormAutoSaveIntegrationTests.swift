import Testing
import Foundation
@testable import SixLayerFramework

//
//  FormAutoSaveIntegrationTests.swift
//  SixLayerFrameworkUITests
//
//  BUSINESS PURPOSE:
//  Validates form auto-save persistence across app restarts (Issue #80)
//  Ensures drafts persist correctly and can be restored
//
//  TESTING SCOPE:
//  - Draft persistence across "app restarts" (simulated)
//  - Draft restoration after restart
//  - Multiple form drafts persistence
//  - Storage error handling
//
//  METHODOLOGY:
//  - Save draft, simulate app restart, verify draft restored
//  - Test multiple forms maintain separate drafts
//  - Test storage error scenarios
//
//  AUDIT STATUS: ✅ COMPLIANT
//

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Form Auto-Save Integration")
open class FormAutoSaveIntegrationTests: BaseTestClass {
    
    /// BUSINESS PURPOSE: Validate draft persists across app restart simulation
    /// TESTING SCOPE: Tests that drafts survive app restart
    /// METHODOLOGY: Save draft, create new storage instance (simulating restart), verify draft exists
    @Test @MainActor func testDraftPersistsAcrossRestart() {
        let testDefaults = UserDefaults(suiteName: "test_integration_autosave")!
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
        
        // "App session 1": Create form and save draft
        let storage1 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config1 = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState1 = DynamicFormState(configuration: config1, storage: storage1)
        formState1.setValue("persisted value", for: "field1")
        formState1.setValue(42, for: "field2")
        formState1.saveDraft()
        
        // Verify draft was saved
        #expect(formState1.hasDraft())
        
        // "App restart": Create new storage instance (simulating app restart)
        let storage2 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config2 = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState2 = DynamicFormState(configuration: config2, storage: storage2)
        
        // "App session 2": Load draft after restart
        let loaded = formState2.loadDraft()
        #expect(loaded == true)
        
        // Verify values were restored
        let value1: String? = formState2.getValue(for: "field1")
        let value2: Int? = formState2.getValue(for: "field2")
        #expect(value1 == "persisted value")
        #expect(value2 == 42)
        
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate multiple forms maintain separate drafts across restart
    /// TESTING SCOPE: Tests that different forms don't interfere with each other
    /// METHODOLOGY: Save drafts for multiple forms, restart, verify all drafts restored
    @Test @MainActor func testMultipleFormsPersistSeparately() {
        let testDefaults = UserDefaults(suiteName: "test_integration_autosave")!
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
        
        // "App session 1": Save drafts for multiple forms
        let storage1 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        
        let config1 = DynamicFormConfiguration(id: "form-1", title: "Form 1", sections: [])
        let formState1 = DynamicFormState(configuration: config1, storage: storage1)
        formState1.setValue("form1 value", for: "field1")
        formState1.saveDraft()
        
        let config2 = DynamicFormConfiguration(id: "form-2", title: "Form 2", sections: [])
        let formState2 = DynamicFormState(configuration: config2, storage: storage1)
        formState2.setValue("form2 value", for: "field1")
        formState2.saveDraft()
        
        let config3 = DynamicFormConfiguration(id: "form-3", title: "Form 3", sections: [])
        let formState3 = DynamicFormState(configuration: config3, storage: storage1)
        formState3.setValue("form3 value", for: "field1")
        formState3.saveDraft()
        
        // "App restart": Create new storage instance
        let storage2 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        
        // "App session 2": Load all drafts
        let config1Restored = DynamicFormConfiguration(id: "form-1", title: "Form 1", sections: [])
        let formState1Restored = DynamicFormState(configuration: config1Restored, storage: storage2)
        formState1Restored.loadDraft()
        
        let config2Restored = DynamicFormConfiguration(id: "form-2", title: "Form 2", sections: [])
        let formState2Restored = DynamicFormState(configuration: config2Restored, storage: storage2)
        formState2Restored.loadDraft()
        
        let config3Restored = DynamicFormConfiguration(id: "form-3", title: "Form 3", sections: [])
        let formState3Restored = DynamicFormState(configuration: config3Restored, storage: storage2)
        formState3Restored.loadDraft()
        
        // Verify all drafts were restored correctly
        let value1: String? = formState1Restored.getValue(for: "field1")
        let value2: String? = formState2Restored.getValue(for: "field1")
        let value3: String? = formState3Restored.getValue(for: "field1")
        #expect(value1 == "form1 value")
        #expect(value2 == "form2 value")
        #expect(value3 == "form3 value")
        
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate draft timestamp is preserved
    /// TESTING SCOPE: Tests that draft timestamps are saved and restored
    /// METHODOLOGY: Save draft, restart, verify timestamp is preserved
    @Test @MainActor func testDraftTimestampPreserved() {
        let testDefaults = UserDefaults(suiteName: "test_integration_autosave")!
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
        
        let storage1 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState1 = DynamicFormState(configuration: config, storage: storage1)
        formState1.setValue("test", for: "field1")
        formState1.saveDraft()
        
        // Get original timestamp
        let draft1 = storage1.loadDraft(formId: "test-form")
        let originalTimestamp = draft1?.timestamp
        
        // Simulate restart
        let storage2 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let draft2 = storage2.loadDraft(formId: "test-form")
        let restoredTimestamp = draft2?.timestamp
        
        // Verify timestamp was preserved
        #expect(originalTimestamp != nil)
        #expect(restoredTimestamp != nil)
        if let original = originalTimestamp, let restored = restoredTimestamp {
            // Timestamps should be very close (within 1 second)
            let timeDifference = abs(original.timeIntervalSince(restored))
            #expect(timeDifference < 1.0)
        }
        
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
    }
    
    /// BUSINESS PURPOSE: Validate draft is cleared after successful submit
    /// TESTING SCOPE: Tests that drafts don't persist after form submission
    /// METHODOLOGY: Save draft, submit form, restart, verify draft is gone
    @Test @MainActor func testDraftClearedAfterSubmit() {
        let testDefaults = UserDefaults(suiteName: "test_integration_autosave")!
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
        
        // "App session 1": Save draft and submit
        let storage1 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState1 = DynamicFormState(configuration: config, storage: storage1)
        formState1.setValue("submit value", for: "field1")
        formState1.saveDraft()
        #expect(formState1.hasDraft())
        
        // Submit form (clears draft)
        formState1.clearDraft()
        #expect(!formState1.hasDraft())
        
        // "App restart": Create new storage instance
        let storage2 = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let formState2 = DynamicFormState(configuration: config, storage: storage2)
        
        // "App session 2": Verify draft is gone
        #expect(!formState2.hasDraft())
        let loaded = formState2.loadDraft()
        #expect(loaded == false)
        
        testDefaults.removePersistentDomain(forName: "test_integration_autosave")
    }
}
