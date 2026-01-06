//
//  HintsFileColorConfigurationTests.swift
//  SixLayerFrameworkTests
//
//  Tests for color configuration in hints files (Issue #142)
//  Tests parsing _defaultColor and _colorMapping from hints files
//  and using them in PresentationHints convenience initializer
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Hints File Color Configuration")
struct HintsFileColorConfigurationTests {
    
    /// Helper to write a hints file to documents directory where loader can find it
    /// Uses unique filenames to ensure test isolation during parallel execution
    /// Returns both the file URL and the unique model name to use with loadHintsResult
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
        // Verify file exists
        guard fileManager.fileExists(atPath: testFile.path) else {
            throw NSError(domain: "TestError", code: 2, userInfo: ["NSLocalizedDescription": "File was not created"])
        }
        return (testFile, uniqueModelName)
    }
    
    // MARK: - DataHintsResult Parsing Tests
    
    #if canImport(SwiftUI)
    @Test func testParseDefaultColorFromHintsFile() throws {
        // Given: Hints file with _defaultColor nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "blue"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Load hints file
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse _defaultColor
        #expect(result.defaultColor == "blue", "Should parse _defaultColor from hints file")
        #expect(result.fieldHints.count == 1, "Should still parse field hints")
        #expect(result.fieldHints["username"] != nil, "Should parse username field")
    }
    
    @Test func testParseColorMappingFromHintsFile() throws {
        // Given: Hints file with _colorMapping nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_colorMapping": [
                    "Vehicle": "blue",
                    "Task": "green"
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Load hints file
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse _colorMapping
        #expect(result.colorMapping != nil, "Should parse _colorMapping from hints file")
        #expect(result.colorMapping?["Vehicle"] == "blue", "Should parse Vehicle -> blue mapping")
        #expect(result.colorMapping?["Task"] == "green", "Should parse Task -> green mapping")
        #expect(result.fieldHints.count == 1, "Should still parse field hints")
    }
    
    @Test func testParseBothColorConfigFromHintsFile() throws {
        // Given: Hints file with both _defaultColor and _colorMapping nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "red",
                "_colorMapping": [
                    "Vehicle": "blue",
                    "Task": "green"
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Load hints file
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse both
        #expect(result.defaultColor == "red", "Should parse _defaultColor")
        #expect(result.colorMapping != nil, "Should parse _colorMapping")
        #expect(result.colorMapping?["Vehicle"] == "blue", "Should parse Vehicle mapping")
        #expect(result.colorMapping?["Task"] == "green", "Should parse Task mapping")
    }
    
    @Test func testParseHexColorFromHintsFile() throws {
        // Given: Hints file with hex color nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "#FF0000"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Load hints file
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse hex color
        #expect(result.defaultColor == "#FF0000", "Should parse hex color from hints file")
    }
    
    @Test func testParseColorConfigIgnoresColorKeysAsFieldHints() throws {
        // Given: Hints file with color config nested under _cardDefaults (should not be treated as field hints)
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "blue",
                "_colorMapping": [
                    "Vehicle": "blue"
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Load hints file
        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Color config should not appear as field hints
        #expect(result.fieldHints["_cardDefaults"] == nil, "Should not treat _cardDefaults as field hint")
        #expect(result.fieldHints["_defaultColor"] == nil, "Should not treat _defaultColor as field hint")
        #expect(result.fieldHints["_colorMapping"] == nil, "Should not treat _colorMapping as field hint")
        #expect(result.fieldHints.count == 1, "Should only have username field")
        #expect(result.fieldHints["username"] != nil, "Should still parse username field")
    }
    
    
    // MARK: - PresentationHints Convenience Initializer Tests
    
    @Test func testPresentationHintsUsesDefaultColorFromHintsFile() async throws {
        // Given: Hints file with _defaultColor nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "blue"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Create PresentationHints from model name
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: Should use defaultColor from hints file
        #expect(hints.defaultColor == .blue, "Should use blue from hints file")
    }
    
    @Test func testPresentationHintsParameterOverridesHintsFileDefaultColor() async throws {
        // Given: Hints file with _defaultColor nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "blue"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Create PresentationHints with parameter override
        let hints = await PresentationHints(
            modelName: uniqueModelName,
            defaultColor: .red  // Override hints file
        )
        
        // Then: Should use parameter (higher priority)
        #expect(hints.defaultColor == .red, "Parameter should override hints file defaultColor")
    }
    
    @Test func testPresentationHintsUsesHexColorFromHintsFile() async throws {
        // Given: Hints file with hex color nested under _cardDefaults
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "_cardDefaults": [
                "_defaultColor": "#FF0000"  // Red in hex
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Create PresentationHints from model name
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: Should parse hex color
        #expect(hints.defaultColor != nil, "Should parse hex color from hints file")
        // Note: We can't easily compare Color values, but we can verify it's not nil
    }
    
    @Test func testPresentationHintsWithNoColorConfigInHintsFile() async throws {
        // Given: Hints file without color config
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Create PresentationHints from model name
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: Should have nil defaultColor (no config in hints file)
        #expect(hints.defaultColor == nil, "Should have nil defaultColor when not in hints file")
    }
    
    @Test func testPresentationHintsWithColorConfigAndFieldHints() async throws {
        // Given: Hints file with both color config and field hints
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false,
                "expectedLength": 20
            ],
            "_cardDefaults": [
                "_defaultColor": "green"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: "TestModel", json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Create PresentationHints from model name
        let hints = await PresentationHints(modelName: uniqueModelName)
        
        // Then: Should have both color config and field hints
        #expect(hints.defaultColor == .green, "Should have defaultColor from hints file")
        #expect(hints.fieldHints["username"] != nil, "Should have field hints")
        #expect(hints.fieldHints["username"]?.expectedLength == 20, "Should parse field hint properties")
    }
    #endif
}

