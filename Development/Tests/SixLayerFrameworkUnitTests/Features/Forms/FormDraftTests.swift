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

    /// #672: Date field values must round-trip as Date, not String(describing:).
    @Test func testAnyCodableDateRoundTripsAsDate() throws {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(AnyCodable(original))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let restored = try #require(decoded.value as? Date)
        #expect(abs(restored.timeIntervalSince1970 - original.timeIntervalSince1970) < 1)
        #expect(!(decoded.value is String), "must not fall back to String(describing:) (#672)")
    }

    /// #672: FormDraft JSON save/load keeps Date usable by DynamicFormStoredDateValue.
    @Test func testFormDraftDateFieldSurvivesJSONRoundTrip() throws {
        let original = Date(timeIntervalSince1970: 1_712_000_000)
        let draft = FormDraft(
            formId: "672-date",
            fieldValues: ["due": original],
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(draft)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FormDraft.self, from: data)

        let restored = decoded.toFieldValues()["due"]
        #expect(restored is Date, "draft field must restore Date (#672)")
        let asDate = try #require(DynamicFormStoredDateValue.date(fromStoredValue: restored))
        #expect(abs(asDate.timeIntervalSince1970 - original.timeIntervalSince1970) < 1)
    }

    /// #672: A plain ISO-8601 string field must stay String (not coerced to Date).
    @Test func testAnyCodablePlainISO8601StringStaysString() throws {
        let iso = "2024-06-15T14:30:00Z"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(AnyCodable(iso))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnyCodable.self, from: data)
        #expect(decoded.value as? String == iso)
        #expect(!(decoded.value is Date))
    }

    /// #672: UserDefaults draft storage round-trips Date field values.
    @Test func testUserDefaultsStorageDateFieldRoundTrip() throws {
        let suiteName = "test_form_storage_date_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        try storage.saveDraft(FormDraft(formId: "672-date", fieldValues: ["when": original]))

        let loaded = try #require(storage.loadDraft(formId: "672-date"))
        let restored = loaded.toFieldValues()["when"]
        #expect(restored is Date)
        let asDate = try #require(restored as? Date)
        #expect(abs(asDate.timeIntervalSince1970 - original.timeIntervalSince1970) < 1)
    }

    // MARK: - AnyCodable URL / Data / UUID (#674)

    /// #674: URL must round-trip as URL, not String(describing:).
    @Test func testAnyCodableURLRoundTripsAsURL() throws {
        let original = try #require(URL(string: "https://example.com/path?q=1"))
        let data = try JSONEncoder().encode(AnyCodable(original))
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? URL == original)
        #expect(!(decoded.value is String), "must not fall back to String(describing:) (#674)")
    }

    /// #674: Data must round-trip as Data (image/data fields).
    @Test func testAnyCodableDataRoundTripsAsData() throws {
        let original = Data([0x00, 0xFF, 0x10, 0xAB])
        let data = try JSONEncoder().encode(AnyCodable(original))
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Data == original)
        #expect(!(decoded.value is String))
    }

    /// #674: UUID must round-trip as UUID.
    @Test func testAnyCodableUUIDRoundTripsAsUUID() throws {
        let original = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
        let data = try JSONEncoder().encode(AnyCodable(original))
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? UUID == original)
        #expect(!(decoded.value is String))
    }

    /// #674: FormDraft JSON keeps URL, Data, and UUID usable after decode.
    @Test func testFormDraftURLDataUUIDSurviveJSONRoundTrip() throws {
        let url = try #require(URL(string: "https://sixlayer.example/doc"))
        let blob = Data("blob".utf8)
        let id = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
        let draft = FormDraft(
            formId: "674-types",
            fieldValues: ["link": url, "payload": blob, "id": id],
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(draft)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FormDraft.self, from: data)
        let values = decoded.toFieldValues()
        #expect(values["link"] as? URL == url)
        #expect(values["payload"] as? Data == blob)
        #expect(values["id"] as? UUID == id)
    }

    /// #674: Plain URL-looking and UUID-looking strings stay String.
    @Test func testAnyCodablePlainURLAndUUIDStringsStayString() throws {
        let urlText = "https://example.com/plain"
        let uuidText = "550e8400-e29b-41d4-a716-446655440000"
        for text in [urlText, uuidText] {
            let decoded = try JSONDecoder().decode(
                AnyCodable.self,
                from: try JSONEncoder().encode(AnyCodable(text))
            )
            #expect(decoded.value as? String == text)
            #expect(!(decoded.value is URL))
            #expect(!(decoded.value is UUID))
        }
    }

    /// #674: UserDefaults draft storage round-trips URL and Data.
    @Test func testUserDefaultsStorageURLAndDataRoundTrip() throws {
        let suiteName = "test_form_storage_url_data_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let url = try #require(URL(string: "https://example.com/a"))
        let blob = Data([1, 2, 3, 4])
        try storage.saveDraft(FormDraft(
            formId: "674-storage",
            fieldValues: ["link": url, "bytes": blob]
        ))
        let loaded = try #require(storage.loadDraft(formId: "674-storage"))
        let values = loaded.toFieldValues()
        #expect(values["link"] as? URL == url)
        #expect(values["bytes"] as? Data == blob)
    }
    
    // MARK: - FormStateStorage Tests
    
    /// BUSINESS PURPOSE: Validate UserDefaultsFormStateStorage save functionality
    /// TESTING SCOPE: Tests saving drafts to UserDefaults
    /// METHODOLOGY: Save a draft and verify it can be loaded
    @Test func testUserDefaultsStorageSave() throws {
        let suiteName = "test_form_storage_save_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)

        let storage = UserDefaultsFormStateStorage(userDefaults: testDefaults)
        let fieldValues: [String: Any] = ["name": "Test", "value": 42]
        let draft = FormDraft(formId: "test-form", fieldValues: fieldValues)

        try storage.saveDraft(draft)

        #expect(storage.hasDraft(formId: "test-form"))

        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    /// BUSINESS PURPOSE: Validate UserDefaultsFormStateStorage load functionality
    /// TESTING SCOPE: Tests loading drafts from UserDefaults
    /// METHODOLOGY: Save a draft, then load it and verify data integrity
    @Test func testUserDefaultsStorageLoad() throws {
        let suiteName = "test_form_storage_load_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)

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

        testDefaults.removePersistentDomain(forName: suiteName)
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
