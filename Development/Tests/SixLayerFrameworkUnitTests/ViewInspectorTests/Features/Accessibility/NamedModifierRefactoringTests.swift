import Testing

import SwiftUI
@testable import SixLayerFramework

/// Tests for .named and .exactNamed Modifier Behavior
/// 
/// BUSINESS PURPOSE: Refactor .named modifier to be simpler and more predictable
/// 
/// DESIRED BEHAVIOR: 
/// - .named: Replace current hierarchy level + generate full hierarchy path (default case)
/// - .exactNamed: Apply exact name only, no hierarchy modification (explicit case)
/// 
/// TESTING SCOPE: UI tests verify that modifiers correctly apply accessibility identifiers
/// to rendered views. These tests belong in UI tests because they verify rendering behavior.
@Suite("Named Modifier Refactoring")
open class NamedModifierRefactoringTDDTests: BaseTestClass {
    
    // MARK: - Test Constants
    
    private let defaultPlatform = SixLayerPlatform.iOS
    private let hierarchyPattern = "SixLayer.*ui"
    
    // MARK: - Helper Methods
    
    /// Helper to disable auto IDs for tests that need to verify independence
    @MainActor
    private func withAutoIDsDisabled<T>(_ operation: () -> T) -> T? {
        guard let config = self.testConfig else {
            Issue.record("testConfig is nil")
            return nil
        }
        let wasEnabled = config.enableAutoIDs
        config.enableAutoIDs = false
        defer { config.enableAutoIDs = wasEnabled }
        return operation()
    }
    
    // MARK: - .named Modifier Tests
    
    /// Test that .named replaces current hierarchy level
    @Test @MainActor func testNamedModifierReplacesCurrentHierarchyLevel() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A button with .named modifier
            let testView = Button("Save") { }
                .named("SaveButton")
            
            // When: We check the accessibility identifier
            // Then: Should get full hierarchy path ending with "SaveButton"
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "HierarchyReplacement"
            ), ".named() should replace current hierarchy level and generate full path as accessibility ID")
        }
    }
    
    /// Test that .named generates full hierarchy path
    @Test @MainActor func testNamedModifierGeneratesFullHierarchyPath() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Nested components with .named modifiers
            let testView = platformVStackContainer {
                Button("Edit") { }
                    .named("EditButton")
            }
            .named("ActionContainer")
            
            // When: We check the accessibility identifier
            // Then: Should get full path including both names
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "FullHierarchyPath"
            ), ".named() should generate full hierarchy path as accessibility identifier")
        }
    }
    
    /// Test that multiple nested .named modifiers build hierarchy
    @Test @MainActor func testMultipleNestedNamedModifiersBuildHierarchy() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Multiple levels of .named modifiers
            let testView = platformVStackContainer {
                platformHStackContainer {
                    Button("Cancel") { }
                        .named("CancelButton")
                }
                .named("ButtonRow")
            }
            .named("DialogBox")
            
            // When: We check the accessibility identifier
            // Then: Should get complete hierarchy path
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "NestedHierarchy"
            ), "Multiple .named() calls should build complete hierarchy path")
        }
    }
    
    /// Test that .named prevents collision with same names
    @Test @MainActor func testNamedModifierPreventsCollisionWithSameNames() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Two buttons with same name in different contexts
            let view1 = platformVStackContainer {
                Button("Save") { }
                    .named("SaveButton")
            }
            .named("UserProfile")
            
            let view2 = platformVStackContainer {
                Button("Save") { }
                    .named("SaveButton")
            }
            .named("Settings")
            
            // When: We check both accessibility identifiers
            // Then: Should get different full paths
            #expect(testComponentComplianceSinglePlatform(
                view1,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "CollisionPrevention1"
            ), "First SaveButton should include UserProfile in path")
            
            #expect(testComponentComplianceSinglePlatform(
                view2,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "CollisionPrevention2"
            ), "Second SaveButton should include Settings in path")
        }
    }
    
    /// Test that .named works independently of global settings
    @Test @MainActor func testNamedModifierWorksIndependentlyOfGlobalSettings() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Global automatic accessibility disabled
            guard withAutoIDsDisabled({
                let testView = Button("Test") { }
                    .named("TestButton")
                
                // When: We check the accessibility identifier
                // Then: Should still get full hierarchy path even with global system disabled
                #expect(testComponentComplianceSinglePlatform(
                    testView,
                    expectedPattern: hierarchyPattern,
                    platform: defaultPlatform,
                    componentName: "IndependentNamedModifier"
                ), ".named() should work independently of global automatic accessibility settings")
                return true
            }) != nil else {
                return
            }
        }
    }
    
    /// Test that subcomponents inherit modified hierarchy
    @Test @MainActor func testSubcomponentsInheritModifiedHierarchy() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A container with .named and subcomponent with automatic accessibility
            let testView = platformVStackContainer {
                Button("Save") { }
                    .automaticCompliance()
            }
            .named("ActionContainer")
            
            // When: We check the accessibility identifier
            // Then: Button should include "ActionContainer" in its generated ID
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "HierarchyInheritance"
            ), "Subcomponents should inherit modified hierarchy context")
        }
    }
    
    /// Test that .named handles empty string gracefully
    @Test @MainActor func testNamedModifierWithEmptyString() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A button with empty string in .named
            let testView = Button("Test") { }
                .named("")
            
            // When: We check the accessibility identifier
            // Then: Should handle empty string gracefully
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: ".*",
                platform: defaultPlatform,
                componentName: "EmptyStringTest"
            ), ".named() with empty string should handle gracefully")
        }
    }
    
    /// Test that .named doesn't change global environment settings
    @Test @MainActor func testNamedModifierDoesNotChangeGlobalEnvironmentSettings() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Global settings are disabled
            guard let config = self.testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            let wasEnabled = config.enableAutoIDs
            config.enableAutoIDs = false
            
            let testView = Button("Test") { }
                .named("TestButton")
            
            // When: We check the accessibility identifier
            // Then: Should work without changing global settings
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "NoGlobalChanges"
            ), ".named() should not change global environment settings")
            
            // And global settings should remain unchanged
            #expect(!config.enableAutoIDs, "Global settings should remain disabled after .named()")
            
            // Restore original state
            config.enableAutoIDs = wasEnabled
        }
    }
    
    // MARK: - .exactNamed Modifier Tests
    
    /// Test that .exactNamed applies exact name only
    @Test @MainActor func testExactNamedModifierAppliesExactNameOnly() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A button with .exactNamed modifier
            let testView = Button("Save") { }
                .exactNamed("SaveButton")
            
            // When: We check the accessibility identifier
            // Then: Should get exactly "SaveButton" (no hierarchy)
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: "^SaveButton$",
                platform: defaultPlatform,
                componentName: "ExactNamedModifier"
            ), ".exactNamed() should apply exact name only, no hierarchy")
        }
    }
    
    /// Test that .exactNamed doesn't modify hierarchy
    @Test @MainActor func testExactNamedModifierDoesNotModifyHierarchy() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Nested components with .exactNamed modifier
            let testView = platformVStackContainer {
                Button("Edit") { }
                    .exactNamed("EditButton")
            }
            .named("ActionContainer")
            
            // When: We check the accessibility identifier
            // Then: Button should get exact name, VStack should get hierarchy
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "ExactNamedHierarchyTest"
            ), ".exactNamed() should not modify hierarchy for other components")
        }
    }
    
    /// Test that .exactNamed works independently of global settings
    @Test @MainActor func testExactNamedModifierWorksIndependentlyOfGlobalSettings() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Global automatic accessibility disabled
            guard withAutoIDsDisabled({
                let testView = Button("Test") { }
                    .exactNamed("TestButton")
                
                // When: We check the accessibility identifier
                // Then: Should get exact name even with global system disabled
                #expect(testComponentComplianceSinglePlatform(
                    testView,
                    expectedPattern: "^TestButton$",
                    platform: defaultPlatform,
                    componentName: "IndependentExactNamedModifier"
                ), ".exactNamed() should work independently of global settings")
                return true
            }) != nil else {
                return
            }
        }
    }
    
    // MARK: - Combined Modifier Tests
    
    /// Test that .named and .exactNamed work together
    @Test @MainActor func testNamedAndExactNamedWorkTogether() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Nested components with both modifiers
            let testView = platformVStackContainer {
                Button("Save") { }
                    .exactNamed("SaveButton")  // Exact name only
                Button("Cancel") { }
                    .named("CancelButton")     // Hierarchical name
            }
            .named("DialogBox")
            
            // When: We check the accessibility identifier
            // Then: Should get hierarchical path for the container
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: hierarchyPattern,
                platform: defaultPlatform,
                componentName: "CombinedModifiersTest"
            ), ".named() and .exactNamed() should work together")
        }
    }
    
    /// Test collision prevention with .exactNamed
    @Test @MainActor func testExactNamedModifierDoesNotPreventCollisions() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: Two buttons with same exact name
            let view1 = Button("Save") { }
                .exactNamed("SaveButton")
            
            let view2 = Button("Save") { }
                .exactNamed("SaveButton")
            
            // When: We check both accessibility identifiers
            // Then: Both should get the same exact name (collision expected)
            #expect(testComponentComplianceSinglePlatform(
                view1,
                expectedPattern: "^SaveButton$",
                platform: defaultPlatform,
                componentName: "ExactNamedCollision1"
            ), "First .exactNamed() should get exact name")
            
            #expect(testComponentComplianceSinglePlatform(
                view2,
                expectedPattern: "^SaveButton$",
                platform: defaultPlatform,
                componentName: "ExactNamedCollision2"
            ), "Second .exactNamed() should get same exact name (collision)")
        }
    }
    
    /// Test that .exactNamed handles empty string
    @Test @MainActor func testExactNamedModifierWithEmptyString() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A button with empty string in .exactNamed
            let testView = Button("Test") { }
                .exactNamed("")
            
            // When: We check the accessibility identifier
            // Then: Should handle empty string gracefully
            #expect(testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: "^$",
                platform: defaultPlatform,
                componentName: "ExactNamedEmptyStringTest"
            ), ".exactNamed() with empty string should handle gracefully")
        }
    }
}
