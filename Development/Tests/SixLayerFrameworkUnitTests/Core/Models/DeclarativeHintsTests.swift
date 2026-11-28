//
//  DeclarativeHintsTests.swift
//  SixLayerFramework
//
//  Tests for fully declarative field hints with type information
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Declarative Hints Tests")
struct DeclarativeHintsTests {
    
    // MARK: - FieldDisplayHints Type Information Tests
    
    @Test func testFieldDisplayHints_WithFieldType() {
        // Test that FieldDisplayHints can include fieldType
        let hints = FieldDisplayHints(
            fieldType: "string",
            expectedLength: 20,
            displayWidth: "medium"
        )
        #expect(hints.fieldType == "string")
        #expect(hints.expectedLength == 20)
    }
    
    @Test func testFieldDisplayHints_WithIsOptional() {
        // Test isOptional property
        let optionalHints = FieldDisplayHints(
            fieldType: "string",
            isOptional: true
        )
        #expect(optionalHints.isOptional == true)
        
        let requiredHints = FieldDisplayHints(
            fieldType: "string",
            isOptional: false
        )
        #expect(requiredHints.isOptional == false)
    }
    
    @Test func testFieldDisplayHints_WithIsArray() {
        // Test isArray property
        let arrayHints = FieldDisplayHints(
            fieldType: "string",
            isArray: true
        )
        #expect(arrayHints.isArray == true)
        
        let scalarHints = FieldDisplayHints(
            fieldType: "string",
            isArray: false
        )
        #expect(scalarHints.isArray == false)
    }
    
    @Test func testFieldDisplayHints_WithDefaultValue() {
        // Test defaultValue property
        let hintsWithDefault = FieldDisplayHints(
            fieldType: "string",
            defaultValue: "default"
        )
        #expect(hintsWithDefault.defaultValue != nil)
        
        let hintsWithoutDefault = FieldDisplayHints(
            fieldType: "string"
        )
        #expect(hintsWithoutDefault.defaultValue == nil)
    }
    
    @Test func testFieldDisplayHints_BackwardCompatibility() {
        // Test that existing hints without type info still work
        let legacyHints = FieldDisplayHints(
            expectedLength: 20,
            displayWidth: "medium"
        )
        #expect(legacyHints.expectedLength == 20)
        #expect(legacyHints.fieldType == nil) // Should be nil for backward compatibility
    }
    
    @Test func testFieldDisplayHints_IsFullyDeclarative() {
        // Test that hints with all type info are considered fully declarative
        let fullHints = FieldDisplayHints(
            fieldType: "number",
            isOptional: false,
            isArray: false,
            defaultValue: 0
        )
        #expect(fullHints.isFullyDeclarative == true)
        
        let partialHints = FieldDisplayHints(
            fieldType: "string"
            // Missing isOptional
        )
        #expect(partialHints.isFullyDeclarative == false)
        
        let noTypeHints = FieldDisplayHints(
            expectedLength: 20
        )
        #expect(noTypeHints.isFullyDeclarative == false)
    }
    
    // MARK: - Hints Parsing Integration Tests
    
    /// Helper to write a hints file to documents directory where loader can find it
    private func writeHintsFile(modelName: String, json: [String: Any]) throws -> (fileURL: URL, uniqueModelName: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        // Use unique filename to prevent conflicts during parallel test execution
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        guard fileManager.fileExists(atPath: testFile.path) else {
            throw NSError(domain: "TestError", code: 2, userInfo: ["NSLocalizedDescription": "File was not created"])
        }
        return (testFile, uniqueModelName)
    }
    
    @Test func testParseHints_WithFieldType() throws {
        // Test parsing hints file with fieldType
        let modelName = "User_testParseHints_WithFieldType"
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false,
                "expectedLength": 20
            ],
            "age": [
                "fieldType": "number",
                "isOptional": true
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let usernameHints = result.fieldHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.fieldType == "string")
        #expect(usernameHints?.isOptional == false)
        #expect(usernameHints?.expectedLength == 20)
        
        let ageHints = result.fieldHints["age"]
        #expect(ageHints != nil)
        #expect(ageHints?.fieldType == "number")
        #expect(ageHints?.isOptional == true)
    }
    
    @Test func testParseHints_WithArrayType() throws {
        // Test parsing array field
        let modelName = "Post_testParseHints_WithArrayType"
        let json: [String: Any] = [
            "tags": [
                "fieldType": "string",
                "isArray": true,
                "displayWidth": "wide"
            ],
            "comments": [
                "fieldType": "string",
                "isArray": true,
                "isOptional": true
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let tagsHints = result.fieldHints["tags"]
        #expect(tagsHints != nil)
        #expect(tagsHints?.fieldType == "string")
        #expect(tagsHints?.isArray == true)
        #expect(tagsHints?.displayWidth == "wide")
        
        let commentsHints = result.fieldHints["comments"]
        #expect(commentsHints != nil)
        #expect(commentsHints?.fieldType == "string")
        #expect(commentsHints?.isArray == true)
        #expect(commentsHints?.isOptional == true)
    }
    
    @Test func testParseHints_WithDefaultValue() throws {
        // Test parsing hints with default values
        let modelName = "Settings_testParseHints_WithDefaultValue"
        let json: [String: Any] = [
            "theme": [
                "fieldType": "string",
                "isOptional": false,
                "defaultValue": "light"
            ],
            "maxItems": [
                "fieldType": "number",
                "isOptional": false,
                "defaultValue": 10
            ],
            "isEnabled": [
                "fieldType": "boolean",
                "isOptional": false,
                "defaultValue": true
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let themeHints = result.fieldHints["theme"]
        #expect(themeHints != nil)
        #expect(themeHints?.defaultValue != nil)
        if let defaultValue = themeHints?.defaultValue as? String {
            #expect(defaultValue == "light")
        } else {
            Issue.record("Expected string defaultValue")
        }
        
        let maxItemsHints = result.fieldHints["maxItems"]
        #expect(maxItemsHints != nil)
        #expect(maxItemsHints?.defaultValue != nil)
        if let defaultValue = maxItemsHints?.defaultValue as? Int {
            #expect(defaultValue == 10)
        } else {
            Issue.record("Expected int defaultValue")
        }
        
        let isEnabledHints = result.fieldHints["isEnabled"]
        #expect(isEnabledHints != nil)
        #expect(isEnabledHints?.defaultValue != nil)
        if let defaultValue = isEnabledHints?.defaultValue as? Bool {
            #expect(defaultValue == true)
        } else {
            Issue.record("Expected bool defaultValue")
        }
    }
    
    @Test func testParseHints_BackwardCompatible() throws {
        // Test that hints without type info still parse correctly
        let modelName = "Legacy_testParseHints_BackwardCompatible"
        let json: [String: Any] = [
            "username": [
                "expectedLength": 20,
                "displayWidth": "medium"
            ],
            "email": [
                "displayWidth": "wide",
                "maxLength": 100
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let usernameHints = result.fieldHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.expectedLength == 20)
        #expect(usernameHints?.displayWidth == "medium")
        #expect(usernameHints?.fieldType == nil) // Should be nil for backward compatibility
        #expect(usernameHints?.isOptional == nil)
        
        let emailHints = result.fieldHints["email"]
        #expect(emailHints != nil)
        #expect(emailHints?.displayWidth == "wide")
        #expect(emailHints?.maxLength == 100)
    }
    
    @Test func testParseHints_MixedTypeAndDisplayHints() throws {
        // Test hints that have both type info and display hints
        let modelName = "Product_testParseHints_MixedTypeAndDisplayHints"
        let json: [String: Any] = [
            "name": [
                "fieldType": "string",
                "isOptional": false,
                "expectedLength": 50,
                "displayWidth": "wide",
                "maxLength": 100
            ],
            "price": [
                "fieldType": "number",
                "isOptional": false,
                "displayWidth": "narrow",
                "expectedRange": ["min": 0.0, "max": 10000.0]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let nameHints = result.fieldHints["name"]
        #expect(nameHints != nil)
        #expect(nameHints?.fieldType == "string")
        #expect(nameHints?.isOptional == false)
        #expect(nameHints?.expectedLength == 50)
        #expect(nameHints?.displayWidth == "wide")
        #expect(nameHints?.maxLength == 100)
        #expect(nameHints?.isFullyDeclarative == true)
        
        let priceHints = result.fieldHints["price"]
        #expect(priceHints != nil)
        #expect(priceHints?.fieldType == "number")
        #expect(priceHints?.isOptional == false)
        #expect(priceHints?.displayWidth == "narrow")
        #expect(priceHints?.expectedRange != nil)
    }
    
    @Test func testParseHints_WithBooleanStringValues() throws {
        // Test parsing boolean values as strings (JSON sometimes has "true"/"false" strings)
        let modelName = "Config_testParseHints_WithBooleanStringValues"
        let json: [String: Any] = [
            "isActive": [
                "fieldType": "boolean",
                "isOptional": "false",  // String boolean
                "defaultValue": true
            ],
            "isOptional": [
                "fieldType": "string",
                "isOptional": "true",  // String boolean
                "isArray": "false"     // String boolean
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let isActiveHints = result.fieldHints["isActive"]
        #expect(isActiveHints != nil)
        #expect(isActiveHints?.isOptional == false) // Should parse "false" string as false
        
        let isOptionalHints = result.fieldHints["isOptional"]
        #expect(isOptionalHints != nil)
        #expect(isOptionalHints?.isOptional == true)  // Should parse "true" string as true
        #expect(isOptionalHints?.isArray == false)    // Should parse "false" string as false
    }
    
    @Test func testParseHints_IsFullyDeclarative() throws {
        // Test that isFullyDeclarative works correctly with parsed hints
        let modelName = "Model_testParseHints_IsFullyDeclarative"
        let json: [String: Any] = [
            "fullyDeclarative": [
                "fieldType": "string",
                "isOptional": false
            ],
            "partialTypeInfo": [
                "fieldType": "number"
                // Missing isOptional
            ],
            "noTypeInfo": [
                "expectedLength": 20
                // No type fields
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let fullHints = result.fieldHints["fullyDeclarative"]
        #expect(fullHints != nil)
        #expect(fullHints?.isFullyDeclarative == true)
        
        let partialHints = result.fieldHints["partialTypeInfo"]
        #expect(partialHints != nil)
        #expect(partialHints?.isFullyDeclarative == false)
        #expect(partialHints?.hasPartialTypeInfo == true)
        
        let noTypeHints = result.fieldHints["noTypeInfo"]
        #expect(noTypeHints != nil)
        #expect(noTypeHints?.isFullyDeclarative == false)
        #expect(noTypeHints?.hasPartialTypeInfo == false)
    }
    
    // MARK: - FieldHintsRegistry Serialization Tests
    
    @Test func testFieldHintsRegistry_SerializeAndDeserialize() throws {
        // Test that FieldHintsRegistry can serialize and deserialize hints with type info
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_hints_\(UUID().uuidString).json")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        // Create hints with type information
        let originalHints: [String: FieldDisplayHints] = [
            "username": FieldDisplayHints(
                fieldType: "string",
                isOptional: false,
                expectedLength: 20,
                displayWidth: "medium"
            ),
            "age": FieldDisplayHints(
                fieldType: "number",
                isOptional: true,
                isArray: false,
                defaultValue: 0
            ),
            "tags": FieldDisplayHints(
                fieldType: "string",
                isOptional: true,
                isArray: true,
                displayWidth: "wide"
            )
        ]
        
        // Create registry and save
        let store = JSONFieldHintsStore(baseURL: tempDir)
        try store.saveHints(originalHints, formId: "test_form")
        
        // Load back
        let loadedHints = store.loadHints(formId: "test_form")
        
        // Verify all fields are present
        #expect(loadedHints.count == 3)
        
        let usernameHints = loadedHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.fieldType == "string")
        #expect(usernameHints?.isOptional == false)
        #expect(usernameHints?.expectedLength == 20)
        #expect(usernameHints?.displayWidth == "medium")
        
        let ageHints = loadedHints["age"]
        #expect(ageHints != nil)
        #expect(ageHints?.fieldType == "number")
        #expect(ageHints?.isOptional == true)
        #expect(ageHints?.isArray == false)
        #expect(ageHints?.defaultValue != nil)
        // defaultValue comes back as NSNumber from JSON, but should be convertible to Int
        if let defaultValue = ageHints?.defaultValue {
            // Try multiple conversion paths
            if let intValue = defaultValue as? Int {
                #expect(intValue == 0)
            } else if let nsNumber = defaultValue as? NSNumber {
                // NSNumber from JSON - convert to Int
                let intValue = nsNumber.intValue
                #expect(intValue == 0)
            } else {
                Issue.record("Expected int defaultValue, got: \(type(of: defaultValue))")
            }
        } else {
            Issue.record("defaultValue is nil")
        }
        
        let tagsHints = loadedHints["tags"]
        #expect(tagsHints != nil)
        #expect(tagsHints?.fieldType == "string")
        #expect(tagsHints?.isOptional == true)
        #expect(tagsHints?.isArray == true)
        #expect(tagsHints?.displayWidth == "wide")
    }
    
    @Test func testFieldDisplayHints_WithIsEditable() {
        // Test isEditable property
        let editableHints = FieldDisplayHints(
            fieldType: "string",
            isEditable: true
        )
        #expect(editableHints.isEditable == true)
        
        let readOnlyHints = FieldDisplayHints(
            fieldType: "string",
            isEditable: false
        )
        #expect(readOnlyHints.isEditable == false)
        
        // Default should be true
        let defaultHints = FieldDisplayHints(
            fieldType: "string"
        )
        #expect(defaultHints.isEditable == true)
    }
    
    @Test func testParseHints_WithIsEditable() throws {
        // Test parsing hints file with isEditable flag
        let modelName = "Model_testParseHints_WithIsEditable"
        let json: [String: Any] = [
            "editableField": [
                "fieldType": "string",
                "isOptional": false,
                "isEditable": true
            ],
            "readOnlyField": [
                "fieldType": "string",
                "isOptional": false,
                "isEditable": false
            ],
            "defaultField": [
                "fieldType": "string",
                "isOptional": false
                // isEditable not specified - should default to true
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let editableHints = result.fieldHints["editableField"]
        #expect(editableHints != nil)
        #expect(editableHints?.isEditable == true)
        
        let readOnlyHints = result.fieldHints["readOnlyField"]
        #expect(readOnlyHints != nil)
        #expect(readOnlyHints?.isEditable == false)
        
        let defaultHints = result.fieldHints["defaultField"]
        #expect(defaultHints != nil)
        #expect(defaultHints?.isEditable == true) // Should default to true
    }
    
    @Test func testFieldHintsRegistry_SerializeIsEditable() async throws {
        // Test that FieldHintsRegistry serializes isEditable correctly
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_isEditable_\(UUID().uuidString).hints")
        
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        let registry = FieldHintsRegistry(store: JSONFieldHintsStore(baseURL: tempDir))
        
        var hints: [String: FieldDisplayHints] = [:]
        hints["editable"] = FieldDisplayHints(
            fieldType: "string",
            isEditable: true
        )
        hints["readOnly"] = FieldDisplayHints(
            fieldType: "string",
            isEditable: false
        )
        
        try await registry.saveHints(hints, for: "testModel")
        
        let loaded = await registry.loadHints(for: "testModel")
        #expect(loaded["editable"]?.isEditable == true)
        #expect(loaded["readOnly"]?.isEditable == false)
    }
    
    @Test func testFieldHintsRegistry_BackwardCompatibility() throws {
        // Test that registry handles hints without type info
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_legacy_\(UUID().uuidString).json")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        // Create legacy hints without type information
        let legacyHints: [String: FieldDisplayHints] = [
            "username": FieldDisplayHints(
                expectedLength: 20,
                displayWidth: "medium"
            ),
            "email": FieldDisplayHints(
                displayWidth: "wide",
                maxLength: 100
            )
        ]
        
        let store = JSONFieldHintsStore(baseURL: tempDir)
        try store.saveHints(legacyHints, formId: "legacy_form")
        
        let loadedHints = store.loadHints(formId: "legacy_form")
        
        #expect(loadedHints.count == 2)
        
        let usernameHints = loadedHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.expectedLength == 20)
        #expect(usernameHints?.displayWidth == "medium")
        #expect(usernameHints?.fieldType == nil) // Should be nil for legacy hints
        #expect(usernameHints?.isOptional == nil)
    }
}
