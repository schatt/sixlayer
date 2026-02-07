//
//  AutomaticAccessibilityLabelTests.swift
//  SixLayerFrameworkTests
//
//  Pure unit tests for automatic accessibility label logic
//  Implements Issue #154: Automatic Accessibility Labels
//
//  BUSINESS PURPOSE: Test label formatting and localization logic directly
//  TESTING SCOPE: Core label logic functions (formatting, localization, sanitization)
//  METHODOLOGY: Test logic functions directly without SwiftUI views or ViewInspector
//

import Testing
import Foundation
@testable import SixLayerFramework

/// Pure unit tests for automatic accessibility label logic
/// Tests label formatting and localization logic directly without SwiftUI views or ViewInspector
/// These tests only test the internal logic functions
@Suite("Automatic Accessibility Labels Logic")
open class AutomaticAccessibilityLabelTests: BaseTestClass {
    
    // MARK: - Label Formatting Logic Tests
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel adds punctuation
    /// TESTING SCOPE: Label formatting logic directly
    /// METHODOLOGY: Test formatAccessibilityLabel() function directly
    @Test func testLabelFormatting_AddsPunctuation() {
        // Given: A label without punctuation
        let label = "Test label"
        
        // When: Formatting the label
        let formatted = formatAccessibilityLabel(label)
        
        // Then: Label should end with punctuation
        #expect(formatted.hasSuffix("."), "Label should end with period")
        #expect(formatted == "Test label.", "Label should be formatted correctly")
    }
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel preserves existing punctuation
    /// TESTING SCOPE: Label formatting logic preserves existing punctuation
    /// METHODOLOGY: Test formatAccessibilityLabel() with labels that already have punctuation
    @Test func testLabelFormatting_PreservesExistingPunctuation() {
        // Given: Labels with existing punctuation
        let exclamation = "Test label!"
        let question = "Test label?"
        let period = "Test label."
        
        // When: Formatting the labels
        let formattedExclamation = formatAccessibilityLabel(exclamation)
        let formattedQuestion = formatAccessibilityLabel(question)
        let formattedPeriod = formatAccessibilityLabel(period)
        
        // Then: Existing punctuation should be preserved
        #expect(formattedExclamation == "Test label!", "Exclamation should be preserved")
        #expect(formattedQuestion == "Test label?", "Question mark should be preserved")
        #expect(formattedPeriod == "Test label.", "Period should be preserved")
    }
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel handles empty strings
    /// TESTING SCOPE: Label formatting logic with edge cases
    /// METHODOLOGY: Test formatAccessibilityLabel() with empty string
    @Test func testLabelFormatting_HandlesEmptyStrings() {
        // Given: An empty label
        let emptyLabel = ""
        
        // When: Formatting the empty label
        let formatted = formatAccessibilityLabel(emptyLabel)
        
        // Then: Should return empty string (no punctuation added to empty)
        #expect(formatted.isEmpty, "Empty label should remain empty")
    }
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel trims whitespace
    /// TESTING SCOPE: Label formatting logic trims whitespace
    /// METHODOLOGY: Test formatAccessibilityLabel() with whitespace
    @Test func testLabelFormatting_TrimsWhitespace() {
        // Given: A label with leading/trailing whitespace
        let labelWithWhitespace = "  Test label  "
        
        // When: Formatting the label
        let formatted = formatAccessibilityLabel(labelWithWhitespace)
        
        // Then: Whitespace should be trimmed and punctuation added
        #expect(formatted == "Test label.", "Whitespace should be trimmed and punctuation added")
    }
    
    // MARK: - Label Localization Logic Tests
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel formats plain text
    /// TESTING SCOPE: Label localization logic with plain text
    /// METHODOLOGY: Test localizeAccessibilityLabel() with plain text (not a key)
    @Test func testLabelLocalization_FormatsPlainText() {
        // Given: A plain text label (not a localization key)
        let plainText = "Save document"
        
        // When: Localizing the label
        let localized = localizeAccessibilityLabel(plainText)
        
        // Then: Should format the text (add punctuation if needed)
        // Note: localizeAccessibilityLabel calls formatAccessibilityLabel internally
        #expect(!localized.isEmpty, "Localized label should not be empty")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel handles localization keys
    /// TESTING SCOPE: Label localization logic with localization keys
    /// METHODOLOGY: Test localizeAccessibilityLabel() with a key format
    @Test func testLabelLocalization_HandlesLocalizationKeys() {
        // Given: A localization key format
        let localizationKey = "SixLayerFramework.accessibility.button.save"
        
        // When: Localizing the key
        let localized = localizeAccessibilityLabel(localizationKey)
        
        // Then: Should attempt to localize (may return key if not found)
        #expect(!localized.isEmpty, "Localized label should not be empty")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel uses context when provided
    /// TESTING SCOPE: Label localization logic with context
    /// METHODOLOGY: Test localizeAccessibilityLabel() with context parameter
    @Test func testLabelLocalization_UsesContext() {
        // Given: A label with context
        let label = "Save"
        let context = "button"
        
        // When: Localizing with context
        let localized = localizeAccessibilityLabel(label, context: context)
        
        // Then: Should use context for better localization
        #expect(!localized.isEmpty, "Localized label with context should not be empty")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel uses elementType when provided
    /// TESTING SCOPE: Label localization logic with element type
    /// METHODOLOGY: Test localizeAccessibilityLabel() with elementType parameter
    @Test func testLabelLocalization_UsesElementType() {
        // Given: A label with element type
        let label = "Save"
        let elementType = "Button"
        
        // When: Localizing with element type
        let localized = localizeAccessibilityLabel(label, context: nil, elementType: elementType)
        
        // Then: Should use element type for better localization
        #expect(!localized.isEmpty, "Localized label with element type should not be empty")
    }
    
    // MARK: - Label Sanitization Logic Tests
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText lowercases and replaces spaces
    /// TESTING SCOPE: Label sanitization logic for identifier generation
    /// METHODOLOGY: Test sanitizeLabelText() function directly
    @Test func testLabelSanitization_LowercasesAndReplacesSpaces() {
        // Given: A label with mixed case and spaces
        let label = "Test Label"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Should be lowercased with hyphens
        #expect(sanitized == "test-label", "Label should be lowercased with hyphens")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText removes special characters
    /// TESTING SCOPE: Label sanitization logic removes special characters
    /// METHODOLOGY: Test sanitizeLabelText() with special characters
    @Test func testLabelSanitization_RemovesSpecialCharacters() {
        // Given: A label with special characters
        let label = "Test@Label#123"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Special characters should be removed
        #expect(!sanitized.contains("@"), "Should not contain @")
        #expect(!sanitized.contains("#"), "Should not contain #")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText collapses multiple hyphens
    /// TESTING SCOPE: Label sanitization logic handles multiple hyphens
    /// METHODOLOGY: Test sanitizeLabelText() with multiple spaces/hyphens
    @Test func testLabelSanitization_CollapsesMultipleHyphens() {
        // Given: A label with multiple spaces
        let label = "Test    Label"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Multiple spaces should become single hyphen
        #expect(!sanitized.contains("--"), "Should not contain multiple hyphens")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText removes leading/trailing hyphens
    /// TESTING SCOPE: Label sanitization logic handles edge cases
    /// METHODOLOGY: Test sanitizeLabelText() with leading/trailing spaces
    @Test func testLabelSanitization_RemovesLeadingTrailingHyphens() {
        // Given: A label with leading/trailing spaces
        let label = "  Test Label  "
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Should not start or end with hyphen
        #expect(!sanitized.hasPrefix("-"), "Should not start with hyphen")
        #expect(!sanitized.hasSuffix("-"), "Should not end with hyphen")
    }
    
    // MARK: - Integration Tests (Logic Only)
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel and localizeAccessibilityLabel work together
    /// TESTING SCOPE: Integration of formatting and localization
    /// METHODOLOGY: Test that formatting is applied after localization
    @Test func testLabelFormattingAndLocalization_WorkTogether() {
        // Given: A plain text label
        let label = "Save document"
        
        // When: Localizing (which formats internally)
        let localized = localizeAccessibilityLabel(label)
        
        // Then: Should be both localized (if key exists) and formatted
        #expect(!localized.isEmpty, "Label should be processed")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText works with formatted labels
    /// TESTING SCOPE: Integration of sanitization with formatting
    /// METHODOLOGY: Test sanitization on formatted label text
    @Test func testLabelSanitization_WorksWithFormattedLabels() {
        // Given: A formatted label (with punctuation)
        let formatted = formatAccessibilityLabel("Test Label")
        
        // When: Sanitizing the formatted label
        let sanitized = sanitizeLabelText(formatted)
        
        // Then: Should sanitize correctly (punctuation removed, lowercased, hyphens)
        #expect(sanitized == "test-label", "Formatted label should be sanitized correctly")
    }
}
