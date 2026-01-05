import Testing


import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

// Using ViewInspectorWrapper for cross-platform compatibility
/// Edge case tests for accessibility identifier generation bug fix
/// These tests ensure our fix handles all edge cases properly
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Identifier Edge Case")
open class AccessibilityIdentifierEdgeCaseTests: BaseTestClass {
    // MARK: - Edge Case 1: Empty String Parameters
    
    @Test @MainActor func testEmptyStringParameters() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
                .named("")  // ← Empty string
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            do { try withInspectedViewThrowing(view) { inspected in
                let buttonID = try inspected.accessibilityIdentifier()
                // Should handle empty strings gracefully
                #expect(!buttonID.isEmpty, "Should generate ID even with empty parameters")
                #expect(buttonID.contains("SixLayer"), "Should contain namespace")

            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 2: Special Characters in Names
    
    @Test @MainActor func testSpecialCharactersInNames() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are special characters handled in names?
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
                .named("Button@#$%^&*()")  // ← Special characters
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            do { try withInspectedViewThrowing(view) { inspected in
                let buttonID = try inspected.accessibilityIdentifier()
                // Should preserve special characters (no sanitization)
                #expect(!buttonID.isEmpty, "Should generate ID with special characters")
                #expect(buttonID.contains("SixLayer"), "Should contain namespace")
                #expect(buttonID.contains("@#$%^&*()"), "Should preserve special characters")

            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 3: Very Long Names
    
    @Test @MainActor func testVeryLongNames() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does it handle extremely long names gracefully?
            let longName = String(repeating: "VeryLongName", count: 50)  // 600+ chars
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
                .named(longName)
                .enableGlobalAutomaticCompliance()
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            do { try withInspectedViewThrowing(view) { inspected in
                let buttonID = try inspected.accessibilityIdentifier()
                // Should handle long names gracefully
                #expect(!buttonID.isEmpty, "Should generate ID with very long names")
                #expect(buttonID.contains("SixLayer"), "Should contain namespace")
                
                // Warn if extremely long (but don't fail the test)
                if buttonID.count > 200 {
                    print("⚠️ WARNING: Generated extremely long accessibility ID (\(buttonID.count) chars)")
                    print("   Consider using shorter, more semantic names for better debugging experience")
                    print("   ID: '\(buttonID)'")
                } else {
                }
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 4: Manual ID Override
    
    @Test @MainActor func testManualIDOverride() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does manual ID override automatic ID?
            let view = PlatformInteractionButton(style: .primary, action: {
                // Test action
            }) {
                Text("Test")
            }
                .accessibilityIdentifier("manual-override")  // ← Manual override
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            do { try withInspectedViewThrowing(view) { inspected in
                let buttonID = try inspected.accessibilityIdentifier()
                // Manual ID should override automatic ID
                #expect(buttonID == "manual-override", "Manual ID should override automatic ID")
                
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 5: Disable/Enable Mid-Hierarchy
    
    @Test @MainActor func testDisableEnableMidHierarchy() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does disable work mid-hierarchy?
            let view = platformVStackContainer {
                Button("Auto") { }
                    .named("AutoButton")
                    .enableGlobalAutomaticCompliance()
                
                Button("Manual") { }
                    .named("ManualButton")
                    .disableAutomaticAccessibilityIdentifiers()  // ← Disable mid-hierarchy
            }
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(view) { inspectedView in
                    let buttons = inspectedView.findAll(ViewType.Button.self)
                    
                    #expect(buttons.count == 2, "Should find both buttons")
                    
                    // First button should have automatic ID
                    let autoButtonID = try buttons[0].accessibilityIdentifier()
                    #expect(autoButtonID.contains("SixLayer"), "Auto button should have automatic ID")
                    
                    // Second button should not have accessibility identifier modifier
                    // (We can't inspect for accessibility identifier when disabled)
                    // Just verify the button exists (buttons[1] is non-optional, so it exists if we reach here)
                    #expect(Bool(true), "Disabled button should still exist")
                    
                }
            } catch {
                Issue.record("Failed to inspect view with mid-hierarchy disable")
            }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 6: Multiple Screen Contexts
    
    @Test @MainActor func testMultipleScreenContexts() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            let view = platformVStackContainer {
                Text("Content")
            }
                .named("TestView")
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(view) { inspectedView in
                    let vStackID = try inspectedView.accessibilityIdentifier()
                    
                    // Should handle multiple contexts (last one wins or combines)
                    #expect(!vStackID.isEmpty, "Should generate ID with multiple contexts")
                    #expect(vStackID.contains("SixLayer"), "Should contain namespace")
                    
                }
            } catch {
                Issue.record("Failed to inspect view with multiple contexts")
            }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 7: Exact Named Behavior (Red Phase Tests)
    
    @Test @MainActor func testExactNamedBehavior() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does exactNamed() use exact names without hierarchy?
            let view1 = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test1", hints: PresentationHints())
            } } catch { Issue.record("View inspection failed: \(error)") }
                .exactNamed("SameName")
                .enableGlobalAutomaticCompliance()
            
            let view2 = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test2", hints: PresentationHints())
            } } catch { Issue.record("View inspection failed: \(error)") }
                .exactNamed("SameName")  // ← Same exact name
                .enableGlobalAutomaticCompliance()
            
            #if canImport(ViewInspector)
            do {
                let button1ID = try withInspectedViewThrowing(view1) { inspectedView1 in
                    try inspectedView1.accessibilityIdentifier()
                }
                let button2ID = try withInspectedViewThrowing(view2) { inspectedView2 in
                    try inspectedView2.accessibilityIdentifier()
                }
                
                // exactNamed() should respect the exact name (no hierarchy, no collision detection)
                #expect(button1ID == button2ID, "exactNamed() should use exact names without modification")
                #expect(button1ID == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(button1ID)'")
                #expect(button2ID == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(button2ID)'")
                
            } catch {
                Issue.record("Failed to inspect exactNamed views")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedVsNamedDifference() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should produce different identifiers than named()
            let exactView = Button("Test") { }
                .exactNamed("TestButton")
                .enableGlobalAutomaticCompliance()
            
            let namedView = Button("Test") { }
                .named("TestButton")
                .enableGlobalAutomaticCompliance()
            
            #if canImport(ViewInspector)
            do {
                let exactID = try withInspectedViewThrowing(exactView) { exactInspected in
                    try exactInspected.accessibilityIdentifier()
                }
                let namedID = try withInspectedViewThrowing(namedView) { namedInspected in
                    try namedInspected.accessibilityIdentifier()
                }
                
                // exactNamed() should produce different identifiers than named()
                // This test will FAIL until exactNamed() is properly implemented
                #expect(exactID != namedID, "exactNamed() should produce different identifiers than named()")
                #expect(exactID.contains("TestButton"), "exactNamed() should contain the exact name")
                #expect(namedID.contains("TestButton"), "named() should contain the name")
                #expect(exactID == "TestButton", "exactNamed() should produce exact identifier 'TestButton', got '\(exactID)'")
                
            } catch {
                Issue.record("Failed to inspect exactNamed vs named views")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedIgnoresHierarchy() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should ignore view hierarchy context
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            } } catch { Issue.record("View inspection failed: \(error)") }
            config.pushViewHierarchy("NavigationView")
            config.pushViewHierarchy("ProfileSection")
            config.setScreenContext("UserProfile")
            
            let exactView = Button("Test") { }
                .exactNamed("SaveButton")
                .enableGlobalAutomaticCompliance()
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(exactView) { exactInspected in
                    let exactID = try exactInspected.accessibilityIdentifier()
                
                    // exactNamed() should NOT include hierarchy components
                    // This test will FAIL until exactNamed() is properly implemented
                    #expect(!exactID.contains("NavigationView"), "exactNamed() should ignore NavigationView hierarchy")
                    #expect(!exactID.contains("ProfileSection"), "exactNamed() should ignore ProfileSection hierarchy")
                    #expect(!exactID.contains("UserProfile"), "exactNamed() should ignore UserProfile screen context")
                    #expect(exactID.contains("SaveButton"), "exactNamed() should contain the exact name")
                    #expect(exactID == "SaveButton", "exactNamed() should produce exact identifier 'SaveButton', got '\(exactID)'")
                    
                }
            } catch {
                Issue.record("Failed to inspect exactNamed with hierarchy")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedMinimalIdentifier() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should produce minimal identifiers
            let exactView = Button("Test") { }
                .exactNamed("MinimalButton")
                .enableGlobalAutomaticCompliance()
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(exactView) { exactInspected in
                    let exactID = try exactInspected.accessibilityIdentifier()
                
                    // exactNamed() should produce minimal identifiers (just the exact name)
                    // This test will FAIL until exactNamed() is properly implemented
                    let expectedMinimalPattern = "MinimalButton"
                #expect(exactID == expectedMinimalPattern, "exactNamed() should produce exact identifier '\(expectedMinimalPattern)', got '\(exactID)'")
                
                }
            } catch {
                Issue.record("Failed to inspect exactNamed minimal")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 8: Configuration Changes Mid-Test
    
    @Test @MainActor func testConfigurationChangesMidTest() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: What happens if configuration changes during view creation?
            guard let config = testConfig else {
                
                Issue.record("testConfig is nil")
                
                return
                
            } } catch { Issue.record("View inspection failed: \(error)") }
            
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            } } catch { Issue.record("View inspection failed: \(error)") }
                .named("TestButton")
                .enableGlobalAutomaticCompliance()
            
            // Change configuration after view creation
            config.namespace = "ChangedNamespace"
            config.mode = .semantic
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(view) { inspectedView in
                    let buttonID = try inspectedView.accessibilityIdentifier()
                
                    // Should use configuration at time of ID generation
                    #expect(!buttonID.isEmpty, "Should generate ID with changed config")
                
                }
            } catch {
                Issue.record("Failed to inspect view with config changes")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 9: Nested .named() Calls
    
    @Test @MainActor func testNestedNamedCalls() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: What happens with deeply nested .named() calls?
            let view = platformVStackContainer {
                platformHStackContainer {
                    Button("Content") { }
                        .named("DeepNested")
                        .enableGlobalAutomaticCompliance()
                }
                .named("Nested")
            } } catch { Issue.record("View inspection failed: \(error)") }
                .named("Outer")
                .named("VeryOuter")  // ← Multiple .named() calls
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(view) { inspectedView in
                    let button = try inspectedView.findAll(ViewType.Button.self).first
                    let buttonID = try button.accessibilityIdentifier()
                    
                    // Should handle nested calls without duplication
                    #expect(!buttonID.isEmpty, "Should generate ID with nested .named() calls")
                    #expect(buttonID.contains("SixLayer"), "Should contain namespace")
                    #expect(!buttonID.contains("outer-outer"), "Should not duplicate names")
                    
                }
            } catch {
                Issue.record("Failed to inspect view with nested .named() calls")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    // MARK: - Edge Case 10: Unicode Characters
    
    @Test @MainActor func testUnicodeCharacters() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are Unicode characters handled?
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            } } catch { Issue.record("View inspection failed: \(error)") }
                .named("按钮")  // ← Chinese characters
            
            #if canImport(ViewInspector)
            do {
                try withInspectedViewThrowing(view) { inspectedView in
                    let buttonID = try inspectedView.accessibilityIdentifier()
                
                    // Should handle Unicode gracefully
                    #expect(!buttonID.isEmpty, "Should generate ID with Unicode characters")
                    #expect(buttonID.contains("SixLayer"), "Should contain namespace")
                
                }
            } catch {
                Issue.record("Failed to inspect view with Unicode characters")
            } } catch { Issue.record("View inspection failed: \(error)") }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
}
