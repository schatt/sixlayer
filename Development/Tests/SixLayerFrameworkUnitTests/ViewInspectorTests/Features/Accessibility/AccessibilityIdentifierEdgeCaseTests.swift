import Testing


import SwiftUI
@testable import SixLayerFramework

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
                Text("Test")
            }
            .named("")  // ← Empty string
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
                Text("Test")
            }
            .named("Button@#$%^&*()")  // ← Special characters
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
                Text("Test")
            }
            .named(longName)
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
    // See `AccessibilityIdentifierDisabledTests.testManualIDsStillWorkWhenAutomaticDisabled` and
    // `ManualAccessibilityIdentifierHarnessUITests` (XCUITest). ViewInspector / hosted UIKit collection
    // often omit manual ids in unit tests; XCUIApplication is the reliable check.
    
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
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
            
            // Modifier bodies are not reliably evaluated in UIHosting-based unit tests; assert the same generator `.exactNamed` uses.
            guard let cfg = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            let id1 = ExactNamedModifier.testingGeneratedIdentifier(name: "SameName", config: cfg)
            let id2 = ExactNamedModifier.testingGeneratedIdentifier(name: "SameName", config: cfg)
            #expect(id1 == "SameName")
            #expect(id2 == "SameName")
        }
    }
    
    @Test @MainActor func testExactNamedVsNamedDifference() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            guard let cfg = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            let exactID = ExactNamedModifier.testingGeneratedIdentifier(name: "TestButton", config: cfg)
            let namedID = NamedModifier.testingGeneratedIdentifier(name: "TestButton", config: cfg)
            #expect(exactID == "TestButton")
            #expect(namedID.contains("TestButton"))
            #expect(exactID != namedID, "exactNamed() should produce different identifiers than named()")
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
            
            let exactID = ExactNamedModifier.testingGeneratedIdentifier(name: "SaveButton", config: config)
            #expect(exactID == "SaveButton", "exactNamed() should ignore pushed hierarchy in the identifier string")
        }
    }
    
    @Test @MainActor func testExactNamedMinimalIdentifier() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            guard let cfg = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            let exactID = ExactNamedModifier.testingGeneratedIdentifier(name: "MinimalButton", config: cfg)
            #expect(exactID == "MinimalButton")
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
                Text("Test")
            }
            .named("TestButton")
            .enableGlobalAutomaticCompliance()
            
            // Change configuration after view creation
            config.namespace = "ChangedNamespace"
            config.mode = .semantic
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
                Text("Test")
            }
            .named("按钮")  // ← Chinese characters
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
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
