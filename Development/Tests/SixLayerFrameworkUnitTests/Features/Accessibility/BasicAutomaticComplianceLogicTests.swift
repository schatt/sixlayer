//
//  BasicAutomaticComplianceLogicTests.swift
//  SixLayerFrameworkTests
//
//  Pure unit tests for basic automatic compliance logic
//  Implements Issue #172: Lightweight Compliance for Basic SwiftUI Types
//
//  BUSINESS PURPOSE: Test identifier generation and label formatting logic directly
//  TESTING SCOPE: Core logic functions (identifier generation, label formatting, sanitization)
//  METHODOLOGY: Test logic functions directly without SwiftUI views
//

import Testing
import Foundation
import SwiftUI
@testable import SixLayerFramework

/// Pure unit tests for basic automatic compliance logic
/// Tests identifier generation logic directly without SwiftUI views or ViewInspector
/// These tests only test the public API of AccessibilityIdentifierGenerator
@Suite("Basic Automatic Compliance Logic")
open class BasicAutomaticComplianceLogicTests: BaseTestClass {
    
    // MARK: - Identifier Generation Logic Tests
    
    /// BUSINESS PURPOSE: Test that AccessibilityIdentifierGenerator generates correct identifiers
    /// TESTING SCOPE: Identifier generation logic with various configurations
    /// METHODOLOGY: Test generateID() directly with different inputs
    @Test @MainActor func testIdentifierGenerator_BasicGeneration() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Basic configuration
            config.namespace = "SixLayer"
            config.globalPrefix = ""
            config.includeComponentNames = true
            config.includeElementTypes = true
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier with basic parameters
            let identifier = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // Then: Identifier should have expected structure
            #expect(identifier.hasPrefix("SixLayer"), "Identifier should start with namespace")
            #expect(identifier.contains("main"), "Identifier should contain screen context")
            #expect(identifier.contains("ui"), "Identifier should contain view hierarchy")
            #expect(identifier.contains("TestButton"), "Identifier should contain component name")
            #expect(identifier.contains("button"), "Identifier should contain element type")
        }
    }
    
    /// BUSINESS PURPOSE: Test identifier generation without component names
    /// TESTING SCOPE: Config option to exclude component names
    /// METHODOLOGY: Test generateID() with includeComponentNames = false
    @Test @MainActor func testIdentifierGenerator_WithoutComponentNames() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration without component names
            config.namespace = "SixLayer"
            config.includeComponentNames = false
            config.includeElementTypes = true
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier
            let identifier = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // Then: Identifier should NOT contain component name
            #expect(identifier.hasPrefix("SixLayer"), "Identifier should start with namespace")
            #expect(!identifier.contains("TestButton"), "Identifier should not contain component name when disabled")
            #expect(identifier.contains("button"), "Identifier should still contain element type")
        }
    }
    
    /// BUSINESS PURPOSE: Test identifier generation without element types
    /// TESTING SCOPE: Config option to exclude element types
    /// METHODOLOGY: Test generateID() with includeElementTypes = false
    @Test @MainActor func testIdentifierGenerator_WithoutElementTypes() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration without element types
            config.namespace = "SixLayer"
            config.includeComponentNames = true
            config.includeElementTypes = false
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier
            let identifier = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // Then: Identifier should NOT contain element type
            #expect(identifier.hasPrefix("SixLayer"), "Identifier should start with namespace")
            #expect(identifier.contains("TestButton"), "Identifier should contain component name")
            #expect(!identifier.contains("button"), "Identifier should not contain element type when disabled")
        }
    }
    
    /// BUSINESS PURPOSE: Test identifier generation with view hierarchy
    /// TESTING SCOPE: View hierarchy tracking in identifier generation
    /// METHODOLOGY: Test generateID() with view hierarchy context
    @Test @MainActor func testIdentifierGenerator_WithViewHierarchy() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with view hierarchy
            config.namespace = "SixLayer"
            config.enableUITestIntegration = false  // Use actual hierarchy
            config.pushViewHierarchy("NavigationView")
            config.pushViewHierarchy("ProfileSection")
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier
            let identifier = generator.generateID(for: "EditButton", role: "button", context: "ui")
            
            // Then: Identifier should reflect view hierarchy
            #expect(identifier.hasPrefix("SixLayer"), "Identifier should start with namespace")
            #expect(identifier.contains("NavigationView"), "Identifier should contain view hierarchy")
            #expect(identifier.contains("ProfileSection"), "Identifier should contain nested hierarchy")
        }
    }
    
    /// BUSINESS PURPOSE: Test identifier generation with global prefix
    /// TESTING SCOPE: Global prefix in identifier generation
    /// METHODOLOGY: Test generateID() with global prefix set
    @Test @MainActor func testIdentifierGenerator_WithGlobalPrefix() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with global prefix
            config.namespace = "SixLayer"
            config.globalPrefix = "MyFeature"
            config.includeComponentNames = true
            config.includeElementTypes = true
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier
            let identifier = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // Then: Identifier should contain prefix
            #expect(identifier.hasPrefix("SixLayer"), "Identifier should start with namespace")
            #expect(identifier.contains("MyFeature"), "Identifier should contain global prefix")
        }
    }
    
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
        
        // Then: Labels should preserve existing punctuation
        #expect(formattedExclamation == "Test label!", "Exclamation should be preserved")
        #expect(formattedQuestion == "Test label?", "Question mark should be preserved")
        #expect(formattedPeriod == "Test label.", "Period should be preserved")
    }
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel handles empty strings
    /// TESTING SCOPE: Label formatting logic with empty strings
    /// METHODOLOGY: Test formatAccessibilityLabel() with empty label
    @Test func testLabelFormatting_HandlesEmptyStrings() {
        // Given: Empty label
        let emptyLabel = ""
        
        // When: Formatting the label
        let formatted = formatAccessibilityLabel(emptyLabel)
        
        // Then: Empty label should be returned as-is
        #expect(formatted.isEmpty, "Empty label should remain empty")
    }
    
    /// BUSINESS PURPOSE: Test that formatAccessibilityLabel trims whitespace
    /// TESTING SCOPE: Label formatting logic trims whitespace
    /// METHODOLOGY: Test formatAccessibilityLabel() with whitespace
    @Test func testLabelFormatting_TrimsWhitespace() {
        // Given: Label with whitespace
        let labelWithWhitespace = "  Test label  "
        
        // When: Formatting the label
        let formatted = formatAccessibilityLabel(labelWithWhitespace)
        
        // Then: Whitespace should be trimmed and punctuation added
        #expect(formatted == "Test label.", "Whitespace should be trimmed")
    }
    
    // MARK: - Label Sanitization Logic Tests
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText lowercases and replaces spaces
    /// TESTING SCOPE: Label sanitization logic directly
    /// METHODOLOGY: Test sanitizeLabelText() function directly
    @Test func testLabelSanitization_LowercasesAndReplacesSpaces() {
        // Given: Label with uppercase and spaces
        let label = "Save File"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Label should be lowercased and spaces replaced with hyphens
        #expect(sanitized == "save-file", "Label should be sanitized: 'Save File' -> 'save-file'")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText removes special characters
    /// TESTING SCOPE: Label sanitization removes special characters
    /// METHODOLOGY: Test sanitizeLabelText() with special characters
    @Test func testLabelSanitization_RemovesSpecialCharacters() {
        // Given: Label with special characters
        let label = "Save & Load!"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Special characters should be removed or replaced
        #expect(!sanitized.contains("&"), "Ampersand should be removed")
        #expect(!sanitized.contains("!"), "Exclamation should be removed")
        #expect(sanitized.contains("save"), "Label should be lowercased")
        #expect(sanitized.contains("load"), "Label should be lowercased")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText collapses multiple hyphens
    /// TESTING SCOPE: Label sanitization collapses multiple hyphens
    /// METHODOLOGY: Test sanitizeLabelText() with multiple consecutive hyphens
    @Test func testLabelSanitization_CollapsesMultipleHyphens() {
        // Given: Label that would create multiple hyphens
        let label = "Save  File"  // Double space
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Multiple hyphens should be collapsed
        #expect(!sanitized.contains("--"), "Multiple hyphens should be collapsed")
    }
    
    /// BUSINESS PURPOSE: Test that sanitizeLabelText removes leading/trailing hyphens
    /// TESTING SCOPE: Label sanitization removes leading/trailing hyphens
    /// METHODOLOGY: Test sanitizeLabelText() with leading/trailing special characters
    @Test func testLabelSanitization_RemovesLeadingTrailingHyphens() {
        // Given: Label that would create leading/trailing hyphens
        let label = "!Save File!"
        
        // When: Sanitizing the label
        let sanitized = sanitizeLabelText(label)
        
        // Then: Leading and trailing hyphens should be removed
        #expect(!sanitized.hasPrefix("-"), "Leading hyphen should be removed")
        #expect(!sanitized.hasSuffix("-"), "Trailing hyphen should be removed")
    }
    
    // MARK: - Label Localization Logic Tests
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel formats plain text
    /// TESTING SCOPE: Label localization logic with plain text
    /// METHODOLOGY: Test localizeAccessibilityLabel() with plain text (not a key)
    @Test func testLabelLocalization_FormatsPlainText() {
        // Given: Plain text label (not a localization key)
        let label = "Save button"
        
        // When: Localizing the label
        let localized = localizeAccessibilityLabel(label)
        
        // Then: Label should be formatted (punctuation added) but not localized
        #expect(localized.hasSuffix("."), "Plain text should be formatted with punctuation")
        #expect(localized == "Save button.", "Plain text should be formatted correctly")
    }
    
    /// BUSINESS PURPOSE: Test that localizeAccessibilityLabel handles localization keys
    /// TESTING SCOPE: Label localization logic with localization keys
    /// METHODOLOGY: Test localizeAccessibilityLabel() with localization key format
    @Test func testLabelLocalization_HandlesLocalizationKeys() {
        // Given: Label that looks like a localization key
        let label = "SixLayerFramework.accessibility.button.save"
        
        // When: Localizing the label
        let localized = localizeAccessibilityLabel(label)
        
        // Then: Label should attempt localization (result depends on whether key exists)
        // If key exists, it will be localized; if not, it will be formatted as-is
        #expect(localized.hasSuffix(".") || localized == label, "Label should be formatted or localized")
    }
    
    // MARK: - Interactive Element Detection Tests
    
    /// BUSINESS PURPOSE: Test that isInteractiveElement correctly identifies interactive elements
    /// TESTING SCOPE: Interactive element detection logic
    /// METHODOLOGY: Test isInteractiveElement() function directly
    @Test func testIsInteractiveElement_IdentifiesInteractiveTypes() {
        // Given: Various element types
        let modifier = AutomaticComplianceModifier()
        
        // When: Checking if elements are interactive
        // Then: Interactive elements should be identified
        #expect(modifier.isInteractiveElement(elementType: "button"), "Button should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "link"), "Link should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "textfield"), "TextField should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "toggle"), "Toggle should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "picker"), "Picker should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "stepper"), "Stepper should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "slider"), "Slider should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "segmentedcontrol"), "SegmentedControl should be interactive")
    }
    
    /// BUSINESS PURPOSE: Test that isInteractiveElement correctly identifies non-interactive elements
    /// TESTING SCOPE: Non-interactive element detection logic
    /// METHODOLOGY: Test isInteractiveElement() with non-interactive types
    @Test func testIsInteractiveElement_IdentifiesNonInteractiveTypes() {
        // Given: Non-interactive element types
        let modifier = AutomaticComplianceModifier()
        
        // When: Checking if elements are interactive
        // Then: Non-interactive elements should not be identified
        #expect(!modifier.isInteractiveElement(elementType: "text"), "Text should not be interactive")
        #expect(!modifier.isInteractiveElement(elementType: "image"), "Image should not be interactive")
        #expect(!modifier.isInteractiveElement(elementType: "label"), "Label should not be interactive")
        #expect(!modifier.isInteractiveElement(elementType: "view"), "View should not be interactive")
        #expect(!modifier.isInteractiveElement(elementType: nil), "Nil element type should not be interactive")
    }
    
    /// BUSINESS PURPOSE: Test that isInteractiveElement is case-insensitive
    /// TESTING SCOPE: Case-insensitive matching
    /// METHODOLOGY: Test isInteractiveElement() with different cases
    @Test func testIsInteractiveElement_CaseInsensitive() {
        // Given: Element types with different cases
        let modifier = AutomaticComplianceModifier()
        
        // When: Checking if elements are interactive
        // Then: Case should not matter
        #expect(modifier.isInteractiveElement(elementType: "Button"), "Button (capitalized) should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "BUTTON"), "BUTTON (uppercase) should be interactive")
        #expect(modifier.isInteractiveElement(elementType: "TextField"), "TextField (capitalized) should be interactive")
    }
    
    // MARK: - Config Logic Tests
    
    /// BUSINESS PURPOSE: Test that config options are respected in identifier generation
    /// TESTING SCOPE: Config option enableAutoIDs affects generator behavior
    /// METHODOLOGY: Test that generator respects config settings
    @Test @MainActor func testConfigRespect_EnableAutoIDs() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with auto IDs disabled
            config.enableAutoIDs = false
            config.namespace = "SixLayer"
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            
            // When: Generating identifier with disabled config
            // Then: Generator should still work (it doesn't check enableAutoIDs directly)
            // The modifier checks enableAutoIDs, not the generator
            let identifier = generator.generateID(for: "TestButton", role: "button", context: "ui")
            #expect(!identifier.isEmpty, "Generator should still generate identifier (modifier checks enableAutoIDs)")
        }
    }
    
    // MARK: - Identifier Collision Detection Tests
    
    /// BUSINESS PURPOSE: Test that AccessibilityIdentifierGenerator detects collisions
    /// TESTING SCOPE: Collision detection logic
    /// METHODOLOGY: Test checkForCollision() method
    @Test @MainActor func testCollisionDetection_DetectsDuplicates() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Generator with existing identifier
            config.namespace = "SixLayer"
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            let identifier1 = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // When: Checking for collision with same identifier
            let hasCollision = generator.checkForCollision(identifier1)
            
            // Then: Collision should be detected
            #expect(hasCollision, "Generator should detect collision with existing identifier")
        }
    }
    
    /// BUSINESS PURPOSE: Test that collision detection doesn't false positive
    /// TESTING SCOPE: Collision detection with different identifiers
    /// METHODOLOGY: Test checkForCollision() with different identifier
    @Test @MainActor func testCollisionDetection_NoFalsePositives() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Generator with existing identifier
            config.namespace = "SixLayer"
            config.enableUITestIntegration = true
            
            let generator = AccessibilityIdentifierGenerator()
            _ = generator.generateID(for: "TestButton", role: "button", context: "ui")
            
            // When: Checking for collision with different identifier
            let hasCollision = generator.checkForCollision("Different.Identifier.Here")
            
            // Then: No collision should be detected
            #expect(!hasCollision, "Generator should not detect collision with different identifier")
        }
    }
    
    // MARK: - Modifier Stub Verification Tests
    
    /// BUSINESS PURPOSE: Verify BasicAutomaticComplianceModifier stub exists and can be instantiated
    /// TESTING SCOPE: Modifier stub structure
    /// METHODOLOGY: Test that modifier can be created (stub should exist for Red phase)
    @Test func testBasicAutomaticComplianceModifier_CanBeInstantiated() {
        // Given: Modifier parameters
        let modifier = BasicAutomaticComplianceModifier(
            identifierName: "testView",
            identifierElementType: "View",
            identifierLabel: "Test",
            accessibilityLabel: "Test label"
        )
        
        // When: Modifier is created
        // Then: Should exist (stub allows compilation)
        // Note: This test verifies the stub exists, but doesn't verify it works
        // The stub just returns content unchanged, so identifiers/labels won't be applied
        #expect(modifier.identifierName == "testView", "Modifier should store identifierName")
        #expect(modifier.accessibilityLabel == "Test label", "Modifier should store accessibilityLabel")
    }
    
    /// BUSINESS PURPOSE: Verify basicAutomaticCompliance() extension method exists
    /// TESTING SCOPE: View extension method availability
    /// METHODOLOGY: Test that extension method compiles and can be called
    @Test @MainActor func testBasicAutomaticCompliance_ExtensionExists() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view
            let view = Text("Test")
            
            // When: Calling basicAutomaticCompliance() extension
            let modifiedView = view.basicAutomaticCompliance(identifierName: "test")
            
            // Then: Should compile (stub allows compilation)
            // Note: Stub just returns content unchanged, so identifier won't be applied
            // This test verifies the method exists, but the stub doesn't actually work
            // ViewInspector tests will verify the stub doesn't apply identifiers (Red phase)
            #expect(Bool(true), "basicAutomaticCompliance() extension should exist and compile")
        }
    }
    
    /// BUSINESS PURPOSE: Verify Text.basicAutomaticCompliance() extension method exists and preserves type
    /// TESTING SCOPE: Text extension method availability and type preservation
    /// METHODOLOGY: Test that Text extension compiles and preserves Text type
    @Test func testTextBasicAutomaticCompliance_ExtensionExistsAndPreservesType() {
        // Given: Text view
        let text = Text("Hello")
        
        // When: Calling Text.basicAutomaticCompliance() extension
        let modifiedText = text.basicAutomaticCompliance(identifierName: "helloText")
        
        // Then: Should compile and preserve Text type (stub allows compilation)
        // Note: Stub just returns self unchanged, so identifier won't be applied
        // This test verifies the method exists and type is preserved, but stub doesn't work
        // ViewInspector tests will verify the stub doesn't apply identifiers (Red phase)
        let chained = modifiedText.bold()
        #expect(Bool(true), "Text.basicAutomaticCompliance() should exist, compile, and preserve Text type for chaining")
    }
}
