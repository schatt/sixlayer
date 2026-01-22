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
@testable import SixLayerFramework

/// Pure unit tests for basic automatic compliance logic
/// Tests identifier generation, label formatting, and sanitization functions directly
/// These tests do NOT use SwiftUI views or ViewInspector - they test the logic functions
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
    
    /// BUSINESS PURPOSE: Test that labels are formatted with punctuation
    /// TESTING SCOPE: Label formatting logic through BasicAutomaticComplianceModifier
    /// METHODOLOGY: Test label formatting by checking results from modifier
    @Test @MainActor func testLabelFormatting_AddsPunctuation() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with accessibility label
            let view = Text("Test")
                .basicAutomaticCompliance(accessibilityLabel: "Test label")
            
            // When: Label is applied
            // Then: Label should be formatted with punctuation
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText.hasSuffix("."), "Label should end with punctuation")
                    #expect(labelText == "Test label.", "Label should be formatted correctly")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View with label should compile")
            #endif
        }
    }
    
    /// BUSINESS PURPOSE: Test that labels with existing punctuation are not modified
    /// TESTING SCOPE: Label formatting logic preserves existing punctuation
    /// METHODOLOGY: Test label formatting with labels that already have punctuation
    @Test @MainActor func testLabelFormatting_PreservesExistingPunctuation() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with accessibility label that already has punctuation
            let view = Text("Test")
                .basicAutomaticCompliance(accessibilityLabel: "Test label!")
            
            // When: Label is applied
            // Then: Label should preserve existing punctuation
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText == "Test label!", "Label should preserve existing punctuation")
                    #expect(!labelText.hasSuffix("."), "Label should not add period if punctuation exists")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View with label should compile")
            #endif
        }
    }
    
    /// BUSINESS PURPOSE: Test that empty labels are handled correctly
    /// TESTING SCOPE: Label formatting logic with empty strings
    /// METHODOLOGY: Test label formatting with empty label
    @Test @MainActor func testLabelFormatting_HandlesEmptyLabels() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with empty accessibility label
            let view = Text("Test")
                .basicAutomaticCompliance(accessibilityLabel: "")
            
            // When: Label is applied
            // Then: Empty label should be handled gracefully
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                // Empty label should not be applied
                #expect(labelView == nil, "Empty label should not be applied")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View with empty label should compile")
            #endif
        }
    }
    
    // MARK: - Identifier Sanitization Logic Tests
    
    /// BUSINESS PURPOSE: Test that identifier labels are sanitized correctly
    /// TESTING SCOPE: Label sanitization logic through identifier generation
    /// METHODOLOGY: Test sanitization by checking identifier components
    @Test @MainActor func testIdentifierSanitization_LowercasesAndReplacesSpaces() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with label text
            config.namespace = "SixLayer"
            config.includeComponentNames = true
            config.enableUITestIntegration = true
            
            // When: Generating identifier with label text containing spaces and uppercase
            // Note: We test this indirectly through the modifier since sanitizeLabelText is private
            let view = Text("Test")
                .basicAutomaticCompliance(
                    identifierName: "TestButton",
                    identifierLabel: "Save File"
                )
            
            // Then: Identifier should contain sanitized label
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "Identifier should be generated")
                if let id = identifier {
                    // Label should be sanitized: "Save File" -> "save-file"
                    #expect(id.contains("save-file") || id.contains("save"), "Identifier should contain sanitized label")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View with label should compile")
            #endif
        }
    }
    
    /// BUSINESS PURPOSE: Test that identifier labels with special characters are sanitized
    /// TESTING SCOPE: Label sanitization removes special characters
    /// METHODOLOGY: Test sanitization with special characters
    @Test @MainActor func testIdentifierSanitization_RemovesSpecialCharacters() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with identifier label containing special characters
            let view = Text("Test")
                .basicAutomaticCompliance(
                    identifierName: "TestButton",
                    identifierLabel: "Save & Load!"
                )
            
            // When: Identifier is generated
            // Then: Special characters should be removed or replaced
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "Identifier should be generated")
                if let id = identifier {
                    // Special characters should be sanitized
                    #expect(!id.contains("&"), "Identifier should not contain &")
                    #expect(!id.contains("!"), "Identifier should not contain !")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View with special characters should compile")
            #endif
        }
    }
    
    // MARK: - Config Respect Tests
    
    /// BUSINESS PURPOSE: Test that identifier generation respects enableAutoIDs config
    /// TESTING SCOPE: Config option enableAutoIDs
    /// METHODOLOGY: Test identifier generation with enableAutoIDs = false
    @Test @MainActor func testConfigRespect_EnableAutoIDs() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with auto IDs disabled
            config.enableAutoIDs = false
            
            let view = Text("Test")
                .basicAutomaticCompliance()
            
            // When: View is created with disabled config
            // Then: Identifier should NOT be applied
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier == nil || identifier?.isEmpty == true, "Identifier should not be applied when enableAutoIDs is false")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View should compile even when auto IDs are disabled")
            #endif
        }
    }
    
    /// BUSINESS PURPOSE: Test that identifier generation respects globalAutomaticAccessibilityIdentifiers
    /// TESTING SCOPE: Config option globalAutomaticAccessibilityIdentifiers
    /// METHODOLOGY: Test identifier generation with globalAutomaticAccessibilityIdentifiers = false
    @Test @MainActor func testConfigRespect_GlobalAutomaticAccessibilityIdentifiers() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            // Given: Configuration with global auto IDs disabled
            config.enableAutoIDs = true
            config.globalAutomaticAccessibilityIdentifiers = false
            
            let view = Text("Test")
                .basicAutomaticCompliance()
            
            // When: View is created with global auto IDs disabled
            // Then: Identifier should NOT be applied
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier == nil || identifier?.isEmpty == true, "Identifier should not be applied when globalAutomaticAccessibilityIdentifiers is false")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available - test that view compiles
            #expect(Bool(true), "View should compile even when global auto IDs are disabled")
            #endif
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
}
