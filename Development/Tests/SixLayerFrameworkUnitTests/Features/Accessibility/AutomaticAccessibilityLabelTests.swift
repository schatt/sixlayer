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
        let plainText = "Save document"
        let localized = localizeAccessibilityLabel(plainText)
        #expect(localized == "Save document.", "Plain text must be formatted, not merely non-empty (#503)")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel resolves a real catalog key
    /// TESTING SCOPE: Label localization logic with localization keys
    /// METHODOLOGY: Assert translated+formatted value via FrameworkCatalogFixture (#503)
    @Test func testLabelLocalization_HandlesLocalizationKeys() {
        let localizationKey = "SixLayerFramework.button.save"
        let localized = localizeAccessibilityLabel(localizationKey)
        let expected = formatAccessibilityLabel(FrameworkCatalogFixture.value(localizationKey))
        #expect(localized == expected, "Must resolve a real catalog value, not pass on raw/missing key (#503)")
    }

    /// Missing keys must surface as formatted key text — not as a successful “Save.” translation (#503).
    @Test func testLabelLocalization_MissingKeyReturnsFormattedKey() {
        let missingKey = "SixLayerFramework.accessibility.button.save"
        let localized = localizeAccessibilityLabel(missingKey)
        #expect(localized == formatAccessibilityLabel(missingKey))
        #expect(localized != formatAccessibilityLabel(FrameworkCatalogFixture.value("SixLayerFramework.button.save")))
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel still formats when context is provided
    /// TESTING SCOPE: context is debug-log only today; output remains formatted plain text
    /// METHODOLOGY: Test localizeAccessibilityLabel() with context parameter
    @Test func testLabelLocalization_UsesContext() {
        let label = "Save"
        let localized = localizeAccessibilityLabel(label, context: "button")
        #expect(localized == "Save.", "Context must not weaken formatting (#503)")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel still formats when elementType is provided
    /// TESTING SCOPE: elementType is debug-log only today; output remains formatted plain text
    /// METHODOLOGY: Test localizeAccessibilityLabel() with elementType parameter
    @Test func testLabelLocalization_UsesElementType() {
        let label = "Save"
        let localized = localizeAccessibilityLabel(label, context: nil, elementType: "Button")
        #expect(localized == "Save.", "Element type must not weaken formatting (#503)")
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
        let label = "Save document"
        let localized = localizeAccessibilityLabel(label)
        #expect(localized == "Save document.", "Formatting+localization path must yield concrete text (#503)")
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
