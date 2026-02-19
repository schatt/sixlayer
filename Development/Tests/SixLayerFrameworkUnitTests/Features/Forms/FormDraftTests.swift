import Testing
import Foundation

//
//  FormDraftTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates form draft and auto-save functionality (Issue #80)
//  Ensures form state can be saved, loaded, and cleared correctly
//
//  TESTING SCOPE:
//  - FormDraft model creation and encoding/decoding
//  - FormStateStorage protocol implementations
//  - Draft save, load, and clear operations
//  - AnyCodable type-erased wrapper functionality
//
//  METHODOLOGY:
//  - Test FormDraft creation with various field value types
//  - Test encoding/decoding of FormDraft
//  - Test storage operations (save, load, clear, hasDraft)
//  - Test AnyCodable with various value types
//
//  AUDIT STATUS: ✅ COMPLIANT
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Form Draft")
open class FormDraftTests: BaseTestClass {
    
    // MARK: - FormDraft Model Tests
    
    /// BUSINESS PURPOSE: Validate FormDraft creation functionality
    /// TESTING SCOPE: Tests FormDraft initialization with various field value types
    /// METHODOLOGY: Create FormDraft with different value types and verify all properties are set correctly
    @Test func testFormDraftCreation() {
        let fieldValues: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "active": true,
            "score": 95.5
        ]
        
        let draft = FormDraft(
            formId: "test-form",
            fieldValues: fieldValues,
            timestamp: Date(),
            metadata: ["source": "test"]
        )
        
        #expect(draft.formId == "test-form")
        #expect(draft.fieldValues.count == 4)
        #expect(draft.metadata?["source"] == "test")
        
        // Verify field values can be converted back
        let restoredValues = draft.toFieldValues()
        #expect(restoredValues["name"] as? String == "John Doe")
        #expect(restoredValues["age"] as? Int == 30)
        #expect(restoredValues["active"] as? Bool == true)
        #expect(restoredValues["score"] as? Double == 95.5)
    }
    
    /// BUSINESS PURPOSE: Validate FormDraft encoding and decoding
    /// TESTING SCOPE: Tests FormDraft Codable conformance
    /// METHODOLOGY: Encode FormDraft to JSON and decode back, verify data integrity
    @Test func testFormDraftEncodingDecoding() throws {
        let fieldValues: [String: Any] = [
            "text": "Hello",
            "number": 42,
            "flag": true
        ]
        
        let originalDraft = FormDraft(
            formId: "test-form",
            fieldValues: fieldValues
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(originalDraft)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedDraft = try decoder.decode(FormDraft.self, from: jsonData)
        
        #expect(decodedDraft.formId == originalDraft.formId)
        #expect(decodedDraft.fieldValues.count == originalDraft.fieldValues.count)
        
        // Verify values
        let restoredValues = decodedDraft.toFieldValues()
        #expect(restoredValues["text"] as? String == "Hello")
        #expect(restoredValues["number"] as? Int == 42)
        #expect(restoredValues["flag"] as? Bool == true)
    }
    
    // MARK: - AnyCodable Tests
    
    /// BUSINESS PURPOSE: Validate AnyCodable wrapper functionality
    /// TESTING SCOPE: Tests AnyCodable with various value types
    /// METHODOLOGY: Create AnyCodable with different types and verify encoding/decoding
    @Test func testAnyCodableWithVariousTypes() throws {
        let values: [Any] = [
            "string",
            42,
            3.14,
            true,
            ["array", "of", "strings"],
            ["key": "value"]
        ]
        
        for value in values {
            let codable = AnyCodable(value)
            let encoder = JSONEncoder()
            let data = try encoder.encode(codable)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AnyCodable.self, from: data)
            
            // Verify the value can be round-tripped
            #expect(String(describing: codable.value) == String(describing: decoded.value))
        }
    }
    
    // MARK: - FormStateStorage Tests
    
    /// BUSINESS PURPOSE: Validate UserDefaultsFormStateStorage save functionality
    /// TESTING SCOPE: Tests saving drafts to UserDefaults
    /// METHODOLOGY: Save a draft and verify it can be loaded
    @Test func testUserDefaultsStorageSave() throws {
        let testDefaults = UserDefaults(suiteName: "test_form_storage")!
        testDefaults.removePersistentDomain(forName: "test_form_storage")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let fieldValues: [String: Any] = ["name": "Test", "value": 42]
        let draft = FormDraft(formId: "test-form", fieldValues: fieldValues)
        
        try storage.saveDraft(draft)
        
        #expect(storage.hasDraft(formId: "test-form"))
        
        testDefaults.removePersistentDomain(forName: "test_form_storage")
    }
    
    /// BUSINESS PURPOSE: Validate UserDefaultsFormStateStorage load functionality
    /// TESTING SCOPE: Tests loading drafts from UserDefaults
    /// METHODOLOGY: Save a draft, then load it and verify data integrity
    @Test func testUserDefaultsStorageLoad() throws {
        let testDefaults = UserDefaults(suiteName: "test_form_storage")!
        testDefaults.removePersistentDomain(forName: "test_form_storage")
        
        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let fieldValues: [String: Any] = ["name": "Test", "value": 42]
        let originalDraft = FormDraft(formId: "test-form", fieldValues: fieldValues)
        
        try storage.saveDraft(originalDraft)
        
        let loadedDraft = storage.loadDraft(formId: "test-form")
        #expect(loadedDraft != nil)
        #expect(loadedDraft?.formId == "test-form")
        
        let restoredValues = loadedDraft?.toFieldValues()
        #expect(restoredValues?["name"] as? String == "Test")
        #expect(restoredValues?["value"] as? Int == 42)
        
        testDefaults.removePersistentDomain(forName: "test_form_storage")
    }
    
    /// BUSINESS PURPOSE: Validate UserDefaultsFormStateStorage clear functionality
    /// TESTING SCOPE: Tests clearing drafts from UserDefaults
    /// METHODOLOGY: Save a draft, clear it, and verify it's gone
    @Test func testUserDefaultsStorageClear() throws {
        let suiteName = "test_form_storage_clear_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)

        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let fieldValues: [String: Any] = ["name": "Test"]
        let draft = FormDraft(formId: "test-form", fieldValues: fieldValues)

        try storage.saveDraft(draft)
        #expect(storage.hasDraft(formId: "test-form"))

        try storage.clearDraft(formId: "test-form")
        #expect(!storage.hasDraft(formId: "test-form"))
        #expect(storage.loadDraft(formId: "test-form") == nil)

        testDefaults.removePersistentDomain(forName: suiteName)
    }
}
