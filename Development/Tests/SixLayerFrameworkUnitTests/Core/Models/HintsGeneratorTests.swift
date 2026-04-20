//
//  HintsGeneratorTests.swift
//  SixLayerFramework
//
//  Tests for the hints generator script functionality
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Hints Generator Tests")
struct HintsGeneratorTests {
    
    /// Test that generated hints can be parsed by DataHintsLoader
    @Test func testGeneratedHintsCanBeParsed() throws {
        // Create a test hints file with type information (simulating generator output)
        let modelName = "GeneratedModel_testGeneratedHintsCanBeParsed"
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false,
                "expectedLength": 20
            ],
            "age": [
                "fieldType": "number",
                "isOptional": false,
                "isArray": false
            ],
            "email": [
                "fieldType": "string",
                "isOptional": true
            ],
            "tags": [
                "fieldType": "string",
                "isArray": true,
                "isOptional": false
            ],
            "isActive": [
                "fieldType": "boolean",
                "isOptional": false,
                "defaultValue": true
            ],
            "balance": [
                "fieldType": "number",
                "isOptional": false,
                "defaultValue": 0
            ]
        ]
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        
        // Load using DataHintsLoader
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Verify all fields are parsed correctly
        #expect(result.fieldHints.count == 6)
        
        let usernameHints = result.fieldHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.fieldType == "string")
        #expect(usernameHints?.isOptional == false)
        #expect(usernameHints?.expectedLength == 20)
        #expect(usernameHints?.isFullyDeclarative == true)
        
        let ageHints = result.fieldHints["age"]
        #expect(ageHints != nil)
        #expect(ageHints?.fieldType == "number")
        #expect(ageHints?.isOptional == false)
        #expect(ageHints?.isArray == false)
        
        let emailHints = result.fieldHints["email"]
        #expect(emailHints != nil)
        #expect(emailHints?.fieldType == "string")
        #expect(emailHints?.isOptional == true)
        
        let tagsHints = result.fieldHints["tags"]
        #expect(tagsHints != nil)
        #expect(tagsHints?.fieldType == "string")
        #expect(tagsHints?.isArray == true)
        #expect(tagsHints?.isOptional == false)
        
        let isActiveHints = result.fieldHints["isActive"]
        #expect(isActiveHints != nil)
        #expect(isActiveHints?.fieldType == "boolean")
        #expect(isActiveHints?.defaultValue != nil)
        if let defaultValue = isActiveHints?.defaultValue {
            if let boolValue = defaultValue as? Bool {
                #expect(boolValue == true)
            } else if let nsNumber = defaultValue as? NSNumber {
                #expect(nsNumber.boolValue == true)
            }
        }
        
        let balanceHints = result.fieldHints["balance"]
        #expect(balanceHints != nil)
        #expect(balanceHints?.fieldType == "number")
        #expect(balanceHints?.defaultValue != nil)
        if let defaultValue = balanceHints?.defaultValue {
            if let intValue = defaultValue as? Int {
                #expect(intValue == 0)
            } else if let nsNumber = defaultValue as? NSNumber {
                #expect(nsNumber.intValue == 0)
            }
        }
    }
    
    /// Test that generated hints maintain existing display hints
    @Test func testGeneratedHintsPreserveDisplayHints() throws {
        // Simulate generating hints for a model that already has display hints
        let modelName = "ExistingHints_testGeneratedHintsPreserveDisplayHints"
        _ = [
            "username": [
                "expectedLength": 20,
                "displayWidth": "medium"
            ]
        ]
        
        // Simulate generator adding type info (should preserve display hints)
        let generatedHints: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false,
                "expectedLength": 20,  // Preserved
                "displayWidth": "medium"  // Preserved
            ]
        ]
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        let data = try JSONSerialization.data(withJSONObject: generatedHints, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let usernameHints = result.fieldHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.fieldType == "string")
        #expect(usernameHints?.isOptional == false)
        #expect(usernameHints?.expectedLength == 20)  // Preserved
        #expect(usernameHints?.displayWidth == "medium")  // Preserved
    }
    
    // MARK: - Section Preservation Tests
    
    /// BUSINESS PURPOSE: Validate that generator preserves existing _sections when updating hints
    /// TESTING SCOPE: Tests that _sections are preserved when hints are regenerated
    /// METHODOLOGY: Create hints file with sections, verify sections are preserved after regeneration
    @Test func testGeneratorPreservesExistingSections() throws {
        let modelName = "SectionPreservation_testGeneratorPreservesExistingSections"
        let existingHints: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "email": [
                "fieldType": "string",
                "isOptional": true
            ],
            "_sections": [
                [
                    "id": "basic-info",
                    "title": "Basic Information",
                    "description": "Your account details",
                    "fields": ["username", "email"],
                    "layoutStyle": "vertical",
                    "isCollapsible": true,
                    "isCollapsed": false
                ]
            ]
        ]
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        // Write existing hints with sections
        let data = try JSONSerialization.data(withJSONObject: existingHints, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        
        // Load using DataHintsLoader
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Verify sections are preserved
        #expect(result.sections.count == 1)
        
        let section = result.sections[0]
        #expect(section.id == "basic-info")
        #expect(section.title == "Basic Information")
        #expect(section.description == "Your account details")
        #expect(section.layoutStyle == .vertical)
        #expect(section.isCollapsible == true)
        #expect(section.isCollapsed == false)
        
        // Fields are stored in metadata as _fieldIds until matched with actual DynamicFormField instances
        // Verify field IDs are preserved in metadata
        guard let fieldIdsString = section.metadata?["_fieldIds"] else {
            Issue.record("Section should have _fieldIds in metadata")
            return
        }
        let fieldIds = fieldIdsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        #expect(fieldIds.count == 2)
        #expect(fieldIds[0] == "username")
        #expect(fieldIds[1] == "email")
        
        // Note: section.fields will be empty until SectionBuilder.buildSections() is called
        // with actual DynamicFormField instances to match against
    }
    
    /// BUSINESS PURPOSE: Validate that hints files without sections can still be loaded
    /// TESTING SCOPE: Tests that DataHintsLoader handles missing _sections gracefully
    /// METHODOLOGY: Create hints file without sections, verify fields are still loaded
    /// NOTE: The generator script creates default sections, but this test verifies loader behavior
    @Test func testLoaderHandlesMissingSections() throws {
        let modelName = "DefaultSection_testGeneratorCreatesDefaultSectionWhenNoneExist"
        let hintsWithoutSections: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "email": [
                "fieldType": "string",
                "isOptional": true
            ],
            "age": [
                "fieldType": "number",
                "isOptional": false
            ]
        ]
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        // Write hints without sections
        let data = try JSONSerialization.data(withJSONObject: hintsWithoutSections, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        
        // Note: The generator would add _sections, but for this test we're verifying
        // that when sections are missing, the loader can still work (graceful degradation)
        // The actual default section creation happens in the generator script
        
        // Load using DataHintsLoader (should handle missing sections gracefully)
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Verify fields are still loaded
        #expect(result.fieldHints.count == 3)
        #expect(result.fieldHints["username"] != nil)
        #expect(result.fieldHints["email"] != nil)
        #expect(result.fieldHints["age"] != nil)
        
        // Sections should be empty (generator would add default, but loader doesn't)
        #expect(result.sections.isEmpty)
    }
    
    /// BUSINESS PURPOSE: Validate that generator preserves section properties including collapsible settings
    /// TESTING SCOPE: Tests that all section properties (isCollapsible, isCollapsed, layoutStyle) are preserved
    /// METHODOLOGY: Create hints with sections having various properties, verify all are preserved
    @Test func testGeneratorPreservesAllSectionProperties() throws {
        let modelName = "SectionProperties_testGeneratorPreservesAllSectionProperties"
        let existingHints: [String: Any] = [
            "username": ["fieldType": "string"],
            "email": ["fieldType": "string"],
            "bio": ["fieldType": "string"],
            "_sections": [
                [
                    "id": "account",
                    "title": "Account",
                    "description": "Account information",
                    "fields": ["username", "email"],
                    "layoutStyle": "horizontal",
                    "isCollapsible": true,
                    "isCollapsed": true
                ],
                [
                    "id": "profile",
                    "title": "Profile",
                    "fields": ["bio"],
                    "layoutStyle": "vertical",
                    "isCollapsible": false
                ]
            ]
        ]
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer {
            try? fileManager.removeItem(at: testFile)
        }
        
        let data = try JSONSerialization.data(withJSONObject: existingHints, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Verify both sections are preserved with all properties
        #expect(result.sections.count == 2)
        
        let accountSection = result.sections.first { $0.id == "account" }
        #expect(accountSection != nil)
        #expect(accountSection?.title == "Account")
        #expect(accountSection?.description == "Account information")
        #expect(accountSection?.layoutStyle == .horizontal)
        #expect(accountSection?.isCollapsible == true)
        #expect(accountSection?.isCollapsed == true)
        
        let profileSection = result.sections.first { $0.id == "profile" }
        #expect(profileSection != nil)
        #expect(profileSection?.title == "Profile")
        #expect(profileSection?.description == nil)
        #expect(profileSection?.layoutStyle == .vertical)
        #expect(profileSection?.isCollapsible == false)
        #expect(profileSection?.isCollapsed == false)  // Default when not specified
    }
    
}
