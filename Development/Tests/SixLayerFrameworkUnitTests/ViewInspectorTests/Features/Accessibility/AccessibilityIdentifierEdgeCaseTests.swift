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
            
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test") {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("")  // ← Empty string
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            // Should handle empty strings gracefully
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID even with empty parameters")
            #expect(buttonID?.contains("SixLayer") == true, "Should contain namespace")
        }
    }
    
    // MARK: - Edge Case 2: Special Characters in Names
    
    @Test @MainActor func testSpecialCharactersInNames() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are special characters handled in names?
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "ButtonSpecials") {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("Button@#$%^&*()")  // ← Special characters
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            // Should preserve special characters (NamedModifier uses name as-is in identifier)
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID with special characters")
            #expect(buttonID?.contains("SixLayer") == true, "Should contain namespace")
            #expect(buttonID?.contains("Button") == true || buttonID?.contains("@#$%^&*()") == true, "Should contain name or special characters")
        }
    }
    
    // MARK: - Edge Case 3: Very Long Names
    
    @Test @MainActor func testVeryLongNames() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does it handle extremely long names gracefully?
            let longName = String(repeating: "VeryLongName", count: 50)  // 600+ chars
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "LongName") {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named(longName)
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID with very long names")
            #expect(buttonID?.contains("SixLayer") == true, "Should contain namespace")
            
            // Warn if extremely long (but don't fail the test)
            if let id = buttonID, id.count > 200 {
                print("⚠️ WARNING: Generated extremely long accessibility ID (\(id.count) chars)")
                print("   Consider using shorter, more semantic names for better debugging experience")
                print("   ID: '\(id)'")
            }
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
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            #expect(buttonID == "manual-override", "Manual ID should override automatic ID")
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
            
            let root = Self.hostRootPlatformView(view)
            let anyID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(anyID != nil && !(anyID?.isEmpty ?? true), "Auto-enabled button should produce an accessibility identifier")
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
            
            let root = Self.hostRootPlatformView(view)
            let vStackID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            // Should handle multiple contexts (last one wins or combines)
            #expect(vStackID != nil && !(vStackID?.isEmpty ?? true), "Should generate ID with multiple contexts")
            #expect(vStackID?.contains("SixLayer") == true, "Should contain namespace")
        }
    }
    
    // MARK: - Edge Case 7: Exact Named Behavior (Red Phase Tests)
    
    @Test @MainActor func testExactNamedBehavior() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does exactNamed() use exact names without hierarchy?
            let view1 = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test1") {
                platformPresentContent_L1(content: "Test1", hints: PresentationHints())
            }
            .exactNamed("SameName")
            .enableGlobalAutomaticCompliance()
            
            let view2 = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test2") {
                platformPresentContent_L1(content: "Test2", hints: PresentationHints())
            }
            .exactNamed("SameName")  // ← Same exact name
            .enableGlobalAutomaticCompliance()
            
            let root1 = Self.hostRootPlatformView(view1)
            let root2 = Self.hostRootPlatformView(view2)
            let id1 = getAccessibilityIdentifierForTest(view: view1, hostedRoot: root1)
            let id2 = getAccessibilityIdentifierForTest(view: view2, hostedRoot: root2)
            
            #expect(id1 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(id1 ?? "nil")'")
            #expect(id2 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(id2 ?? "nil")'")
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
            
            let exactRoot = Self.hostRootPlatformView(exactView)
            let namedRoot = Self.hostRootPlatformView(namedView)
            let exactID = getAccessibilityIdentifierForTest(view: exactView, hostedRoot: exactRoot)
            let namedID = getAccessibilityIdentifierForTest(view: namedView, hostedRoot: namedRoot)
            
            #expect(exactID != namedID, "exactNamed() should produce different identifiers than named()")
            #expect(exactID?.contains("TestButton") == true || exactID == "TestButton", "exactNamed() should contain the exact name")
            #expect(namedID?.contains("TestButton") == true, "named() should contain the name")
            #expect(exactID == "TestButton", "exactNamed() should produce exact identifier 'TestButton', got '\(exactID ?? "nil")'")
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
            }
            config.pushViewHierarchy("NavigationView")
            config.pushViewHierarchy("ProfileSection")
            config.setScreenContext("UserProfile")
            
            let exactView = Button("Test") { }
                .exactNamed("SaveButton")
                .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(exactView)
            let exactID = getAccessibilityIdentifierForTest(view: exactView, hostedRoot: root)
            
            #expect(exactID == "SaveButton", "exactNamed() should produce exact identifier 'SaveButton', got '\(exactID ?? "nil")'")
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
            
            let root = Self.hostRootPlatformView(exactView)
            let exactID = getAccessibilityIdentifierForTest(view: exactView, hostedRoot: root)
            
            let expectedMinimalPattern = "MinimalButton"
            #expect(exactID == expectedMinimalPattern, "exactNamed() should produce exact identifier '\(expectedMinimalPattern)', got '\(exactID ?? "nil")'")
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
            }
            
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("TestButton")
            .enableGlobalAutomaticCompliance()
            
            // Change configuration after view creation
            config.namespace = "ChangedNamespace"
            config.mode = .semantic
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID with changed config")
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
            }
            .named("Outer")
            .named("VeryOuter")  // ← Multiple .named() calls
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID with nested .named() calls")
            #expect(buttonID?.contains("SixLayer") == true, "Should contain namespace")
        }
    }
    
    // MARK: - Edge Case 10: Unicode Characters
    
    @Test @MainActor func testUnicodeCharacters() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are Unicode characters handled?
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "UnicodeButton") {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("按钮")  // ← Chinese characters
            
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            // Should handle Unicode gracefully
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should generate ID with Unicode characters")
            #expect(buttonID?.contains("SixLayer") == true, "Should contain namespace")
        }
    }
}
