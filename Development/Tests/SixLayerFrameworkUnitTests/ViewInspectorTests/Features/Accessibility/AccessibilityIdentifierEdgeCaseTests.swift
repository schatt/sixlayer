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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID even with empty parameters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with special characters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
                #expect(id.contains("Button") || id.contains("@#$%^&*()"), "Should contain name or special characters")
            }
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with very long names")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
            
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(id == "manual-override", "Manual ID should override automatic ID")
            }
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
            if anyID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = anyID {
                #expect(!id.isEmpty, "Auto-enabled button should produce an accessibility identifier")
            }
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
            
            if vStackID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = vStackID {
                #expect(!id.isEmpty, "Should generate ID with multiple contexts")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
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
            
            if id1 == nil || id2 == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let i1 = id1 { #expect(i1 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(i1)'") }
            if let i2 = id2 { #expect(i2 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(i2)'") }
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
            
            if exactID == nil || namedID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let e = exactID, let n = namedID {
                #expect(e != n, "exactNamed() should produce different identifiers than named()")
                #expect(e.contains("TestButton") || e == "TestButton", "exactNamed() should contain the exact name")
                #expect(n.contains("TestButton"), "named() should contain the name")
                #expect(e == "TestButton", "exactNamed() should produce exact identifier 'TestButton', got '\(e)'")
            }
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
            
            if exactID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = exactID {
                #expect(id == "SaveButton", "exactNamed() should produce exact identifier 'SaveButton', got '\(id)'")
            }
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
            
            if exactID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            let expectedMinimalPattern = "MinimalButton"
            if let id = exactID {
                #expect(id == expectedMinimalPattern, "exactNamed() should produce exact identifier '\(expectedMinimalPattern)', got '\(id)'")
            }
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with changed config")
            }
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with nested .named() calls")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
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
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with Unicode characters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
        }
    }
}
