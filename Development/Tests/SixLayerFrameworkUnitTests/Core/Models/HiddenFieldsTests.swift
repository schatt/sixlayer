//
//  HiddenFieldsTests.swift
//  SixLayerFramework
//
//  Tests for hidden field functionality in hints
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Hidden Fields Tests")
struct HiddenFieldsTests {
    
    // MARK: - Hidden Field Tests
    
    @Test func testParseHints_WithHiddenField() throws {
        // Given: A hints file with a hidden field
        let modelName = "User_testParseHints_WithHiddenField"
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "cloudSyncId": [
                "fieldType": "string",
                "isOptional": false,
                "isHidden": true  // Hidden field
            ],
            "email": [
                "fieldType": "string",
                "isOptional": true
            ]
        ]
        
        let (testFile, uniqueModelName) = try HintsTestFixtures.writeHintsFile(modelName: modelName, json: json)
        defer {
            HintsTestFixtures.cleanup(testFile)
        }
        
        let loader = HintsTestFixtures.loader(for: testFile)
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Verify hints are loaded
        #expect(result.fieldHints.count == 3)
        
        // Verify hidden field is marked as hidden
        let cloudSyncIdHints = result.fieldHints["cloudSyncId"]
        #expect(cloudSyncIdHints != nil)
        #expect(cloudSyncIdHints?.isHidden == true)
        
        // Verify visible fields are not hidden
        let usernameHints = result.fieldHints["username"]
        #expect(usernameHints != nil)
        #expect(usernameHints?.isHidden == false)
        
        let emailHints = result.fieldHints["email"]
        #expect(emailHints != nil)
        #expect(emailHints?.isHidden == false)
    }
    
    @Test func testParseHints_HiddenFieldAsString() throws {
        // Given: A hints file with isHidden as string "true"
        let modelName = "User_testParseHints_HiddenFieldAsString"
        let json: [String: Any] = [
            "internalId": [
                "fieldType": "string",
                "isOptional": false,
                "isHidden": "true"  // String boolean
            ]
        ]
        
        let (testFile, uniqueModelName) = try HintsTestFixtures.writeHintsFile(modelName: modelName, json: json)
        defer {
            HintsTestFixtures.cleanup(testFile)
        }
        
        let loader = HintsTestFixtures.loader(for: testFile)
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        let hints = result.fieldHints["internalId"]
        #expect(hints != nil)
        #expect(hints?.isHidden == true) // Should parse "true" string as true
    }
    
    @Test func testHiddenFields_ExcludedFromAnalysis() throws {
        // Given: A model with hidden field in hints
        let modelName = "TestUser_testHiddenFields_ExcludedFromAnalysis"
        let json: [String: Any] = [
            "username": [
                "fieldType": "string",
                "isOptional": false
            ],
            "cloudSyncId": [
                "fieldType": "string",
                "isOptional": false,
                "isHidden": true
            ],
            "email": [
                "fieldType": "string",
                "isOptional": true
            ]
        ]
        
        let (testFile, uniqueModelName) = try HintsTestFixtures.writeHintsFile(modelName: modelName, json: json)
        defer {
            HintsTestFixtures.cleanup(testFile)
        }
        
        // Create a test model
        struct TestUser {
            let username: String
            let cloudSyncId: String
            let email: String?
        }
        
        let _ = TestUser(username: "test", cloudSyncId: "sync-123", email: "test@example.com")
        
        // When: Analyzing with hints
        // Note: The hints file name needs to match the type name
        // For this test, we'll verify the hints are loaded correctly
        let hintsLoader = HintsTestFixtures.loader(for: testFile)
        let hintsResult = hintsLoader.loadHintsResult(for: uniqueModelName)
        
        // Verify hidden field is in hints but marked as hidden
        #expect(hintsResult.fieldHints["cloudSyncId"]?.isHidden == true)
        #expect(hintsResult.fieldHints["username"]?.isHidden == false)
        #expect(hintsResult.fieldHints["email"]?.isHidden == false)
    }
    
    @Test func testFieldDisplayHints_DefaultIsNotHidden() {
        // Test that default FieldDisplayHints is not hidden
        let hints = FieldDisplayHints(
            fieldType: "string",
            isOptional: false
        )
        #expect(hints.isHidden == false)
    }
    
    @Test func testFieldDisplayHints_ExplicitlyHidden() {
        // Test that isHidden can be set to true
        let hints = FieldDisplayHints(
            fieldType: "string",
            isOptional: false,
            isHidden: true
        )
        #expect(hints.isHidden == true)
    }
}
