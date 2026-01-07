//
//  HintsFilePresentationPropertiesTests.swift
//  SixLayerFrameworkTests
//
//  Tests for presentation properties in hints files (Issue #143)
//  Tests parsing dataType, complexity, context, customPreferences, and
//  presentationPreference from hints files and using them in PresentationHints
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Hints File Presentation Properties")
struct HintsFilePresentationPropertiesTests {
    
    /// Helper to write a hints file to documents directory where loader can find it
    private func writeHintsFile(modelName: String, json: [String: Any]) throws -> (fileURL: URL, uniqueModelName: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        guard fileManager.fileExists(atPath: testFile.path) else {
            throw NSError(domain: "TestError", code: 2, userInfo: ["NSLocalizedDescription": "File was not created"])
        }
        return (testFile, uniqueModelName)
    }
    
    // MARK: - DataHintsResult Parsing Tests
    
    @Test func testParseDataTypeFromHintsFile() throws {
        // Given: Hints file with dataType in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_dataType": "collection"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: dataType should be parsed
        #expect(result.dataType == "collection")
        #expect(result.dataType != nil)
    }
    
    @Test func testParseComplexityFromHintsFile() throws {
        // Given: Hints file with complexity in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_complexity": "complex"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: complexity should be parsed
        #expect(result.complexity == "complex")
    }
    
    @Test func testParseContextFromHintsFile() throws {
        // Given: Hints file with context in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_context": "edit"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: context should be parsed
        #expect(result.context == "edit")
    }
    
    @Test func testParseCustomPreferencesFromHintsFile() throws {
        // Given: Hints file with customPreferences in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_customPreferences": [
                    "businessType": "vehicle",
                    "formStyle": "multiStep"
                ]
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: customPreferences should be parsed
        #expect(result.customPreferences?["businessType"] == "vehicle")
        #expect(result.customPreferences?["formStyle"] == "multiStep")
    }
    
    @Test func testParsePresentationPreferenceSimpleFromHintsFile() throws {
        // Given: Hints file with simple presentationPreference in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_presentationPreference": "list"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: presentationPreference should be parsed
        #expect(result.presentationPreference != nil)
        if case .simple(let value) = result.presentationPreference {
            #expect(value == "list")
        } else {
            Issue.record("Expected simple presentationPreference, got something else")
        }
    }
    
    @Test func testParsePresentationPreferenceCountBasedFromHintsFile() throws {
        // Given: Hints file with countBased presentationPreference in _defaults
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_presentationPreference": [
                    "type": "countBased",
                    "lowCount": "list",
                    "highCount": "grid",
                    "threshold": 10
                ]
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Loading hints result
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: presentationPreference should be parsed as countBased
        #expect(result.presentationPreference != nil)
        if case .countBased(let lowCount, let highCount, let threshold) = result.presentationPreference {
            #expect(lowCount == "list")
            #expect(highCount == "grid")
            #expect(threshold == 10)
        } else {
            Issue.record("Expected countBased presentationPreference, got something else")
        }
    }
    
    // MARK: - PresentationHints Integration Tests
    
    #if canImport(SwiftUI)
    @Test func testPresentationHintsUsesDataTypeFromHintsFile() async throws {
        // Given: Hints file with dataType
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_dataType": "collection"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints from hints file
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: dataType should be used
        #expect(hints.dataType == .collection)
    }
    
    @Test func testPresentationHintsUsesComplexityFromHintsFile() async throws {
        // Given: Hints file with complexity
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_complexity": "complex"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints from hints file
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: complexity should be used
        #expect(hints.complexity == .complex)
    }
    
    @Test func testPresentationHintsUsesContextFromHintsFile() async throws {
        // Given: Hints file with context
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_context": "edit"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints from hints file
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: context should be used
        #expect(hints.context == .edit)
    }
    
    @Test func testPresentationHintsUsesCustomPreferencesFromHintsFile() async throws {
        // Given: Hints file with customPreferences
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_customPreferences": [
                    "businessType": "vehicle",
                    "formStyle": "multiStep"
                ]
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints from hints file
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: customPreferences should be used
        #expect(hints.customPreferences["businessType"] == "vehicle")
        #expect(hints.customPreferences["formStyle"] == "multiStep")
    }
    
    @Test func testPresentationHintsUsesPresentationPreferenceFromHintsFile() async throws {
        // Given: Hints file with presentationPreference
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_presentationPreference": "list"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints from hints file
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: presentationPreference should be used
        #expect(hints.presentationPreference == .list)
    }
    
    @Test func testPresentationHintsCodeParameterOverridesHintsFile() async throws {
        // Given: Hints file with dataType
        let json: [String: Any] = [
            "field1": ["fieldType": "string"],
            "_defaults": [
                "_dataType": "collection",
                "_complexity": "simple",
                "_context": "browse"
            ]
        ]
        
        let (_, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        
        // When: Creating PresentationHints with code parameters that override
        let hints = await PresentationHints(
            dataType: .text,
            complexity: .complex,
            context: .edit,
            modelName: uniqueModelName
        )
        
        // Then: Code parameters should override hints file values
        #expect(hints.dataType == .text)
        #expect(hints.complexity == .complex)
        #expect(hints.context == .edit)
    }
    #endif
}

