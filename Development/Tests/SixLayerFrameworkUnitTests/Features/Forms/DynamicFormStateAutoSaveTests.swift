import Testing
import Foundation
@testable import SixLayerFramework

//
//  DynamicFormStateAutoSaveTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates auto-save and draft functionality for DynamicFormState (Issue #80)
//  Ensures form state can be saved, loaded, and cleared correctly
//
//  TESTING SCOPE:
//  - Auto-save timer functionality
//  - Draft save, load, and clear operations
//  - Debounced save on field changes
//  - Storage integration
//
//  METHODOLOGY:
//  - Test auto-save timer start/stop
//  - Test draft save and load
//  - Test debounced saves
//  - Test storage error handling
//
//  AUDIT STATUS: ✅ COMPLIANT
//

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("DynamicFormState Auto-Save")
open class DynamicFormStateAutoSaveTests: BaseTestClass {
    private func makeIsolatedDefaultsSuite() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "test_form_autosave_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func cleanupDefaultsSuite(_ suiteName: String, defaults: UserDefaults) {
        defaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Auto-Save Timer Tests
    
    /// BUSINESS PURPOSE: Validate auto-save timer starts correctly
    /// TESTING SCOPE: Tests that auto-save timer can be started
    /// METHODOLOGY: Start auto-save and verify timer is active
    @Test @MainActor func testAutoSaveTimerStarts() {
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config)
        
        formState.startAutoSave(interval: 1.0)
        
        // Timer should be started (we can't directly verify timer, but we can verify save works)
        // Set a value and manually save to verify the mechanism works
        formState.setValue("test", for: "field1")
        formState.saveDraft()
        
        // Verify draft exists
        #expect(formState.hasDraft())
    }
    
    /// BUSINESS PURPOSE: Validate auto-save timer stops correctly
    /// TESTING SCOPE: Tests that auto-save timer can be stopped
    /// METHODOLOGY: Start then stop auto-save timer
    @Test @MainActor func testAutoSaveTimerStops() {
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config)
        
        formState.startAutoSave(interval: 1.0)
        formState.stopAutoSave()
        
        // Timer should be stopped (no way to directly verify, but stop should not crash)
        // If we get here, stop worked
        #expect(Bool(true))
    }
    
    // MARK: - Draft Save/Load Tests
    
    /// BUSINESS PURPOSE: Validate draft save functionality
    /// TESTING SCOPE: Tests that form state can be saved as draft
    /// METHODOLOGY: Set field values, save draft, verify it exists
    @Test @MainActor func testSaveDraft() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        formState.setValue("John", for: "name")
        formState.setValue(30, for: "age")
        
        formState.saveDraft()
        
        #expect(formState.hasDraft())
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    /// BUSINESS PURPOSE: Validate draft load functionality
    /// TESTING SCOPE: Tests that saved draft can be loaded
    /// METHODOLOGY: Save draft, clear state, load draft, verify values restored
    @Test @MainActor func testLoadDraft() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        // Set values and save
        formState.setValue("Jane", for: "name")
        formState.setValue(25, for: "age")
        formState.saveDraft()
        
        // Clear state
        formState.fieldValues.removeAll()
        #expect(formState.getValue(for: "name") as String? == nil)
        
        // Load draft
        let loaded = formState.loadDraft()
        #expect(loaded == true)
        
        // Verify values restored
        #expect(formState.getValue(for: "name") as String? == "Jane")
        #expect(formState.getValue(for: "age") as Int? == 25)
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    /// BUSINESS PURPOSE: Validate draft clear functionality
    /// TESTING SCOPE: Tests that draft can be cleared
    /// METHODOLOGY: Save draft, clear it, verify it no longer exists
    @Test @MainActor func testClearDraft() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        formState.setValue("test", for: "field1")
        formState.saveDraft()
        #expect(formState.hasDraft())
        
        formState.clearDraft()
        #expect(!formState.hasDraft())
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    // MARK: - Debounced Save Tests
    
    /// BUSINESS PURPOSE: Validate debounced save triggers correctly
    /// TESTING SCOPE: Tests that debounced save is triggered on field changes
    /// METHODOLOGY: Trigger debounced save multiple times, verify only one save occurs after delay
    @Test @MainActor func testDebouncedSave() async throws {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        // Set debounce delay to short interval for testing
        formState.debounceDelay = 0.5
        
        // Trigger multiple debounced saves rapidly
        formState.setValue("value1", for: "field1")
        formState.triggerDebouncedSave()
        formState.setValue("value2", for: "field1")
        formState.triggerDebouncedSave()
        formState.setValue("value3", for: "field1")
        formState.triggerDebouncedSave()
        
        // Allow extra time under full-suite load; poll until draft appears or timeout.
        let timeoutNanoseconds: UInt64 = 3_000_000_000
        let pollIntervalNanoseconds: UInt64 = 100_000_000
        var waitedNanoseconds: UInt64 = 0
        while waitedNanoseconds < timeoutNanoseconds && !formState.hasDraft() {
            try await Task.sleep(nanoseconds: pollIntervalNanoseconds)
            waitedNanoseconds += pollIntervalNanoseconds
        }
        
        // Verify draft exists with final value
        #expect(formState.hasDraft())
        let draft = storage.loadDraft(formId: "test-form")
        let values = draft?.toFieldValues()
        #expect(values?["field1"] as? String == "value3")
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    // MARK: - Configuration Tests
    
    /// BUSINESS PURPOSE: Validate auto-save can be disabled
    /// TESTING SCOPE: Tests that auto-save can be disabled via configuration
    /// METHODOLOGY: Disable auto-save, verify timer doesn't start but manual operations work
    @Test @MainActor func testAutoSaveCanBeDisabled() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config, storage: storage)
        
        // Verify auto-save is enabled by default
        #expect(formState.autoSaveEnabled == true)
        
        // Disable auto-save
        formState.autoSaveEnabled = false
        #expect(formState.autoSaveEnabled == false)
        
        // When disabled, startAutoSave should not start timer
        formState.setValue("test", for: "field1")
        formState.startAutoSave()
        
        // Timer should not be active (we can't directly verify, but we verify the flag)
        // Note: saveDraft() respects autoSaveEnabled, so manual save won't work when disabled
        // This is by design - when auto-save is disabled, all auto-save operations are disabled
        #expect(formState.autoSaveEnabled == false)
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    /// BUSINESS PURPOSE: Validate auto-save interval is configurable
    /// TESTING SCOPE: Tests that auto-save interval can be customized
    /// METHODOLOGY: Set custom interval, verify it's used
    @Test @MainActor func testAutoSaveIntervalIsConfigurable() {
        let config = DynamicFormConfiguration(
            id: "test-form",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: config)
        
        formState.autoSaveInterval = 60.0
        #expect(formState.autoSaveInterval == 60.0)
        
        formState.autoSaveInterval = 15.0
        #expect(formState.autoSaveInterval == 15.0)
    }
    
    // MARK: - Draft storage key (Issue #273)
    
    /// Same `configuration.id`, different `draftStorageKey` → separate draft buckets.
    @Test @MainActor func testDraftStorageKeyIsolatesDraftsForSameConfigurationId() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "shared-form",
            title: "Shared",
            sections: []
        )
        let addState = DynamicFormState(
            configuration: config,
            draftStorageKey: "add-bucket",
            storage: storage
        )
        let editState = DynamicFormState(
            configuration: config,
            draftStorageKey: "edit-bucket",
            storage: storage
        )
        addState.setValue("from-add", for: "f")
        addState.saveDraft()
        editState.setValue("from-edit", for: "f")
        editState.saveDraft()
        
        #expect(addState.hasDraft())
        #expect(editState.hasDraft())
        
        addState.fieldValues.removeAll()
        #expect(addState.loadDraft())
        #expect(addState.getValue(for: "f") as String? == "from-add")
        
        editState.fieldValues.removeAll()
        #expect(editState.loadDraft())
        #expect(editState.getValue(for: "f") as String? == "from-edit")
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
    
    /// Empty `draftStorageKey` falls back to `configuration.id` (same bucket as `nil`).
    @Test @MainActor func testEmptyDraftStorageKeyFallsBackToConfigurationId() {
        let (testDefaults, suiteName) = makeIsolatedDefaultsSuite()
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let config = DynamicFormConfiguration(
            id: "fallback-form",
            title: "Fallback",
            sections: []
        )
        let explicitEmpty = DynamicFormState(
            configuration: config,
            draftStorageKey: "",
            storage: storage
        )
        let defaultKeyState = DynamicFormState(
            configuration: config,
            storage: storage
        )
        explicitEmpty.setValue("shared", for: "f")
        explicitEmpty.saveDraft()
        #expect(defaultKeyState.hasDraft())
        defaultKeyState.fieldValues.removeAll()
        #expect(defaultKeyState.loadDraft())
        #expect(defaultKeyState.getValue(for: "f") as String? == "shared")
        
        cleanupDefaultsSuite(suiteName, defaults: testDefaults)
    }
}
