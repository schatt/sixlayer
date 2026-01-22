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
}
