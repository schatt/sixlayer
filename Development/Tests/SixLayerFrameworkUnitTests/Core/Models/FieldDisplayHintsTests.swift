//
//  FieldDisplayHintsTests.swift
//  SixLayerFrameworkTests
//
//  Tests for field-level display hints functionality
//

import Testing
@testable import SixLayerFramework

@Suite("Field Display Hints")
struct FieldDisplayHintsTests {
    
    // MARK: - Basic Creation
    
    @Test func testFieldDisplayHintsCreation() {
        let hints = FieldDisplayHints(
            expectedLength: 20,
            displayWidth: "medium",
            showCharacterCounter: true,
            maxLength: 50,
            minLength: 3,
            metadata: ["key": "value"]
        )
        
        #expect(hints.expectedLength == 20)
        #expect(hints.displayWidth == "medium")
        #expect(hints.showCharacterCounter == true)
        #expect(hints.maxLength == 50)
        #expect(hints.minLength == 3)
        #expect(hints.metadata["key"] == "value")
    }
    
    @Test func testFieldDisplayHintsDefaultValues() {
        let hints = FieldDisplayHints()
        
        #expect(hints.expectedLength == nil)
        #expect(hints.displayWidth == nil)
        #expect(hints.showCharacterCounter == false)
        #expect(hints.maxLength == nil)
        #expect(hints.minLength == nil)
        #expect(hints.metadata.isEmpty)
    }
    
    // MARK: - Display Width Helpers
    
    @Test func testDisplayWidthNarrow() {
        let hints = FieldDisplayHints(displayWidth: "narrow")
        #expect(hints.isNarrow == true)
        #expect(hints.isMedium == false)
        #expect(hints.isWide == false)
    }
    
    @Test func testDisplayWidthMedium() {
        let hints = FieldDisplayHints(displayWidth: "medium")
        #expect(hints.isNarrow == false)
        #expect(hints.isMedium == true)
        #expect(hints.isWide == false)
    }
    
    @Test func testDisplayWidthWide() {
        let hints = FieldDisplayHints(displayWidth: "wide")
        #expect(hints.isNarrow == false)
        #expect(hints.isMedium == false)
        #expect(hints.isWide == true)
    }

    @Test func testDisplayWidthNilIsNotMedium() {
        // #385: nil displayWidth means no band preference, not medium.
        let hints = FieldDisplayHints()
        #expect(hints.isNarrow == false)
        #expect(hints.isMedium == false)
        #expect(hints.isWide == false)
    }
    
    @Test func testDisplayWidthNumericValue() {
        let hints = FieldDisplayHints(displayWidth: "250")
        if let width = hints.displayWidthValue() {
            #expect(width == 250.0)
        } else {
            Issue.record("Expected numeric width value")
        }
    }
    
    // MARK: - PresentationHints Integration
    
    @Test func testPresentationHintsWithFieldHints() {
        let fieldHints = [
            "username": FieldDisplayHints(displayWidth: "medium"),
            "email": FieldDisplayHints(displayWidth: "wide")
        ]
        
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .create,
            fieldHints: fieldHints
        )
        
        #expect(hints.fieldHints.count == 2)
        #expect(hints.hasHints(forFieldId: "username") == true)
        #expect(hints.hasHints(forFieldId: "email") == true)
        #expect(hints.hasHints(forFieldId: "nonexistent") == false)
    }
    
    @Test func testPresentationHintsFieldHintsRetrieval() {
        let fieldHints = [
            "username": FieldDisplayHints(
                expectedLength: 20,
                displayWidth: "medium"
            )
        ]
        
        let hints = PresentationHints(
            dataType: .form,
            fieldHints: fieldHints
        )
        
        let usernameHints = hints.hints(forFieldId: "username")
        #expect(usernameHints?.displayWidth == "medium")
        #expect(usernameHints?.expectedLength == 20)
    }
    
    // MARK: - EnhancedPresentationHints Integration
    
    @Test func testEnhancedPresentationHintsWithFieldHints() {
        let fieldHints = [
            "username": FieldDisplayHints(displayWidth: "medium")
        ]
        
        let hints = EnhancedPresentationHints(
            dataType: .form,
            fieldHints: fieldHints
        )
        
        #expect(hints.fieldHints.count == 1)
        #expect(hints.hasHints(forFieldId: "username") == true)
    }
}


